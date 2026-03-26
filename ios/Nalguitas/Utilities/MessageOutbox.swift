import Foundation
import Network
import OSLog

/// A queue that stores messages locally when the device is offline or requests fail
actor MessageOutbox {
    static let shared = MessageOutbox()
    
    private let logger = Logger(subsystem: "app.rork.amor-rosa-app", category: "MessageOutbox")
    private let queueKey = "chat_outbox_queue"
    private var isFlushing = false
    private let monitor = NWPathMonitor()
    
    private init() {
        startMonitoring()
    }
    
    struct QueuedMessage: Codable, Identifiable {
        let id: String
        let sender: String
        let type: String
        let content: String
        let mediaData: String?
        let mediaUrl: String?
        let replyTo: String?
        let queuedAt: Date
        var retryCount: Int = 0
    }
    
    func enqueue(sender: String, type: String, content: String, mediaData: String? = nil, mediaUrl: String? = nil, replyTo: String? = nil) {
        let newMsg = QueuedMessage(
            id: UUID().uuidString,
            sender: sender,
            type: type,
            content: content,
            mediaData: mediaData,
            mediaUrl: mediaUrl,
            replyTo: replyTo,
            queuedAt: Date()
        )
        
        var queue = getQueue()
        queue.append(newMsg)
        saveQueue(queue)
        logger.info("Enqueued message for later delivery: \(newMsg.id). Total in queue: \(queue.count)")
    }
    
    func flushQueue() async {
        guard !isFlushing else { return }
        let queue = getQueue()
        guard !queue.isEmpty else { return }
        
        isFlushing = true
        logger.info("Attempting to flush \(queue.count) queued messages...")
        
        var failedMessages: [QueuedMessage] = []
        
        for msg in queue {
            do {
                _ = try await APIService.shared.sendChatMessage(
                    sender: msg.sender,
                    type: msg.type,
                    content: msg.content,
                    mediaData: msg.mediaData,
                    mediaUrl: msg.mediaUrl,
                    replyTo: msg.replyTo
                )
                logger.debug("Successfully flushed outbox message: \(msg.id)")
            } catch {
                logger.error("Failed to flush message \(msg.id): \(error)")
                var updatedMsg = msg
                updatedMsg.retryCount += 1
                // Only keep messages that haven't failed too many times
                if updatedMsg.retryCount < 10 {
                    failedMessages.append(updatedMsg)
                }
            }
        }
        
        saveQueue(failedMessages)
        isFlushing = false
        
        if failedMessages.isEmpty {
            logger.info("Outbox queue successfully emptied.")
        } else {
            logger.warning("\(failedMessages.count) messages remain in outbox queue.")
            // Retry again in 30 seconds if still failing but network claims it's up
            Task {
                try? await Task.sleep(for: .seconds(30))
                await flushQueue()
            }
        }
    }
    
    // MARK: - Local Storage
    private func getQueue() -> [QueuedMessage] {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let queue = try? JSONDecoder().decode([QueuedMessage].self, from: data) else {
            return []
        }
        return queue
    }
    
    private func saveQueue(_ queue: [QueuedMessage]) {
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
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}
