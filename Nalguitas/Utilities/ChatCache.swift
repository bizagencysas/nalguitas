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
            guard let data = try? JSONEncoder().encode(messages) else { return }
            try? data.write(to: cacheURL, options: .atomic)
        }
    }
    
    /// Clear cache (e.g. on logout).
    static func clear() {
        try? FileManager.default.removeItem(at: cacheURL)
    }
}
