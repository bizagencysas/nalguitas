import Foundation
import UIKit
import OSLog

/// A utility to manage native file persistence for Chat Media, similar to WhatsApp or iMessage.
/// It saves Base64 strings to actual device storage (.jpg / .mp4) to allow instant reading and zero memory decode bottlenecks.
final class MediaFileManager {
    static let shared = MediaFileManager()
    private let logger = Logger(subsystem: "com.bizagencysas.nalguitas", category: "MediaFileManager")
    
    private let mediaDirectory: URL
    
    private init() {
        // Use Application Support directory so media isn't visible in iCloud Drive by default,
        // but it persists across app updates and launches.
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = paths[0]
        mediaDirectory = appSupport.appendingPathComponent("ChatMedia", isDirectory: true)
        
        createDirectoryIfNeeded()
    }
    
    private func createDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: mediaDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: mediaDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                logger.error("Failed to create ChatMedia directory: \(error.localizedDescription)")
            }
        }
    }
    
    /// Returns the local file URL if the media for this message ID already exists on disk.
    func localURL(for messageId: String, type: String) -> URL? {
        let ext = type == "video" ? "mp4" : "jpg"
        let fileURL = mediaDirectory.appendingPathComponent("\(messageId).\(ext)")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        return nil
    }
    
    /// Saves a base64 string directly to a physical file.
    /// Runs asynchronously on a background thread.
    /// Returns the saved local URL, or nil if failed.
    func saveBase64Media(_ base64String: String, messageId: String, type: String) async -> URL? {
        // Check if we already have it
        if let existingUrl = localURL(for: messageId, type: type) {
            return existingUrl
        }
        
        let ext = type == "video" ? "mp4" : "jpg"
        let fileURL = mediaDirectory.appendingPathComponent("\(messageId).\(ext)")
        
        return await Task.detached(priority: .utility) {
            guard let data = Data(base64Encoded: base64String) else {
                return nil
            }
            
            do {
                try data.write(to: fileURL, options: .atomic)
                return fileURL
            } catch {
                self.logger.error("Failed to save media \(messageId): \(error.localizedDescription)")
                return nil
            }
        }.value
    }
    
    /// Deletes the local file associated with a message.
    func deleteMedia(for messageId: String, type: String) {
        if let url = localURL(for: messageId, type: type) {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    /// Clears the entire ChatMedia directory.
    func clearAllMedia() {
        try? FileManager.default.removeItem(at: mediaDirectory)
        createDirectoryIfNeeded()
    }
}
