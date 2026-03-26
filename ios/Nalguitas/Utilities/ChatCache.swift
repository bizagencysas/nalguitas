import Foundation

/// Persists chat messages locally for instant loading.
/// Messages are stored as JSON in the app's documents directory.
enum ChatCache {
    private static let fileName = "chat_messages_cache.json"
    
    private static var cacheURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }
    
    /// Load cached messages from disk (instant, no network).
    static func load() -> [ChatMessage] {
        guard let data = try? Data(contentsOf: cacheURL),
              let messages = try? JSONDecoder().decode([ChatMessage].self, from: data)
        else { return [] }
        return messages
    }
    
    /// Save messages to disk (called after every fetch/send).
    static func save(_ messages: [ChatMessage]) {
        // Run on background queue to avoid blocking UI
        DispatchQueue.global(qos: .utility).async {
            // First, strip down messages so the JSON isn't massive with Base64 strings.
            // If a message has mediaData (Base64), save it as a native file, then remove the Base64 from JSON.
            let strippedMessages = messages.map { msg -> ChatMessage in
                if let base64 = msg.mediaData, (msg.type == "image" || msg.type == "video" || msg.type == "sticker") {
                    // Fire and forget file saving (MediaFileManager is async, but we can call it in a Task)
                    Task {
                        await MediaFileManager.shared.saveBase64Media(base64, messageId: msg.id, type: msg.type)
                    }
                    
                    // Return lightweight message for JSON cache
                    return ChatMessage(
                        id: msg.id,
                        sender: msg.sender,
                        type: msg.type,
                        content: msg.content,
                        mediaData: nil,         // Removed!
                        mediaUrl: msg.mediaUrl, // Existing URLs remain
                        replyTo: msg.replyTo,
                        seen: msg.seen,
                        createdAt: msg.createdAt
                    )
                }
                return msg
            }
            
            guard let data = try? JSONEncoder().encode(strippedMessages) else { return }
            try? data.write(to: cacheURL, options: .atomic)
        }
    }
    
    /// Clear cache (e.g. on logout).
    static func clear() {
        try? FileManager.default.removeItem(at: cacheURL)
    }
}
