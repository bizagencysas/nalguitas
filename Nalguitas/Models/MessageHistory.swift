import Foundation
import SwiftData

@Model
final class MessageHistory {
    var content: String
    var subtitle: String
    var source: String
    var receivedAt: Date

    init(content: String, subtitle: String = "Para ti", source: String = "message", receivedAt: Date = Date()) {
        self.content = content
        self.subtitle = subtitle
        self.source = source
        self.receivedAt = receivedAt
    }
}
