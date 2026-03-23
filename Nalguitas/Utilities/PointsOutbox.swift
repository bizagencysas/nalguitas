import Foundation
import Network
import OSLog

/// A queue that stores point awards locally when the device is offline or requests fail.
actor PointsOutbox {
    static let shared = PointsOutbox()
    
    private let logger = Logger(subsystem: "app.rork.amor-rosa-app", category: "PointsOutbox")
    private let queueKey = "points_outbox_queue"
    private var isFlushing = false
    private let monitor = NWPathMonitor()
    
    private init() {
        startMonitoring()
    }
    
    struct QueuedPoint: Codable, Identifiable {
        let id: String
        let username: String
        let points: Int
        let reason: String
        let queuedAt: Date
        var retryCount: Int = 0
    }
    
    func enqueue(username: String, points: Int, reason: String) {
        let newPoint = QueuedPoint(
            id: UUID().uuidString,
            username: username,
            points: points,
            reason: reason,
            queuedAt: Date()
        )
        
        var queue = getQueue()
        queue.append(newPoint)
        saveQueue(queue)
        logger.info("Enqueued point award for later delivery: \(reason). Total in queue: \(queue.count)")
    }
    
    func flushQueue() async {
        guard !isFlushing else { return }
        let queue = getQueue()
        guard !queue.isEmpty else { return }
        
        isFlushing = true
        logger.info("Attempting to flush \(queue.count) queued point awards...")
        
        var failedPoints: [QueuedPoint] = []
        
        for point in queue {
            do {
                try await APIService.shared.addPoints(username: point.username, points: point.points, reason: point.reason)
                logger.debug("Successfully flushed point award: \(point.reason)")
            } catch {
                logger.error("Failed to flush point award \(point.id): \(error)")
                var updatedPoint = point
                updatedPoint.retryCount += 1
                // Only keep points that haven't failed too many times (e.g., 20 retries)
                if updatedPoint.retryCount < 20 {
                    failedPoints.append(updatedPoint)
                }
            }
        }
        
        saveQueue(failedPoints)
        isFlushing = false
        
        if failedPoints.isEmpty {
            logger.info("Points outbox queue successfully emptied.")
        } else {
            logger.warning("\(failedPoints.count) point awards remain in outbox queue.")
            // Retry again in 1 minute if still failing
            Task {
                try? await Task.sleep(for: .seconds(60))
                await flushQueue()
            }
        }
    }
    
    // MARK: - Local Storage
    private func getQueue() -> [QueuedPoint] {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let queue = try? JSONDecoder().decode([QueuedPoint].self, from: data) else {
            return []
        }
        return queue
    }
    
    private func saveQueue(_ queue: [QueuedPoint]) {
        if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: queueKey)
        }
    }
    
    // MARK: - Network Monitoring
    nonisolated private func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                Task {
                    await self.flushQueue()
                }
            }
        }
        let queue = DispatchQueue(label: "PointsNetworkMonitor")
        monitor.start(queue: queue)
    }
}
