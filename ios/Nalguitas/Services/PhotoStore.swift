import Foundation
import UIKit

final class PhotoStore {
    static let shared = PhotoStore()

    private let directory: URL

    private init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        directory = support.appendingPathComponent("GalleryPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    private func fileURL(for id: String) -> URL {
        directory.appendingPathComponent("\(id).jpg")
    }

    func exists(id: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: id).path)
    }

    func save(base64: String, id: String) async {
        guard !exists(id: id) else { return }
        let url = fileURL(for: id)
        await Task.detached(priority: .utility) {
            guard let data = Data(base64Encoded: base64) else { return }
            if let img = UIImage(data: data), let compressed = img.jpegData(compressionQuality: 0.75) {
                try? compressed.write(to: url, options: .atomic)
            } else {
                try? data.write(to: url, options: .atomic)
            }
        }.value
    }

    func load(id: String) -> UIImage? {
        let url = fileURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    func deleteAll() {
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
