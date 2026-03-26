import Foundation
import SwiftData

@Model
final class SavedMessage {
    var messageId: String
    var content: String
    var subtitle: String
    var savedAt: Date
    var tone: String

    init(messageId: String, content: String, subtitle: String, savedAt: Date = Date(), tone: String = "tierno") {
        self.messageId = messageId
        self.content = content
        self.subtitle = subtitle
        self.savedAt = savedAt
        self.tone = tone
    }
}
