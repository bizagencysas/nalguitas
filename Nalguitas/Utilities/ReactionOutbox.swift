import Foundation
import Network
import OSLog

/// A queue that stores emoji reactions locally when the device is offline or requests fail.
actor ReactionOutbox {
    static let shared = ReactionOutbox()
    
    private let logger = Logger(subsystem: "app.rork.amor-rosa-app", category: "ReactionOutbox")
    private let queueKey = "reaction_outbox_queue"
    private var isFlushing = false
    private let monitor = NWPathMonitor()
    
    private init() {
        startMonitoring()
    }
    
    struct QueuedReaction: Codable, Identifiable {
        let id: String
        let messageId: String
        let username: String
        let emoji: String?
        let queuedAt: Date
        var retryCount: Int = 0
    }
    
    func enqueue(messageId: String, username: String, emoji: String?) {
        let newReaction = QueuedReaction(
            id: UUID().uuidString,
            messageId: messageId,
            username: username,
            emoji: emoji,
            queuedAt: Date()
        )
        
        var queue = getQueue()
        // If there's already a pending reaction for this message/user, replace it
        queue.removeAll { $0.messageId == messageId && $0.username == username }
        queue.append(newReaction)
        saveQueue(queue)
        logger.info("Enqueued reaction for later delivery on message: \(messageId)")
    }
    
    func flushQueue() async {
        guard !isFlushing else { return }
        let queue = getQueue()
        guard !queue.isEmpty else { return }
        
        isFlushing = true
        logger.info("Attempting to flush \(queue.count) queued reactions...")
        
        var remainingReactions: [QueuedReaction] = []
        
        for reaction in queue {
            do {
                try await APIService.shared.addReaction(messageId: reaction.messageId, username: reaction.username, emoji: reaction.emoji)
                logger.debug("Successfully flushed reaction for message: \(reaction.messageId)")
            } catch {
                logger.error("Failed to flush reaction \(reaction.id): \(error)")
                var updated = reaction
                updated.retryCount += 1
                if updated.retryCount < 20 {
                    remainingReactions.append(updated)
                }
            }
        }
        
        saveQueue(remainingReactions)
        isFlushing = false
        
        if !remainingReactions.isEmpty {
            Task {
                try? await Task.sleep(for: .seconds(60))
                await flushQueue()
            }
        }
    }
    
    // MARK: - Local Storage
    private func getQueue() -> [QueuedReaction] {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let queue = try? JSONDecoder().decode([QueuedReaction].self, from: data) else {
            return []
        }
        return queue
    }
    
    private func saveQueue(_ queue: [QueuedReaction]) {
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
        let queue = DispatchQueue(label: "ReactionNetworkMonitor")
        monitor.start(queue: queue)
    }
}
