import Foundation
import SwiftData
import WidgetKit

@Observable
@MainActor
class AppViewModel {
    var todayMessage: LoveMessage?
    var isLoading = false
    var errorMessage: String?
    var showSavedConfirmation = false

    func loadTodayMessage() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let message = try await APIService.shared.fetchTodayMessage()
            todayMessage = message
            SharedDataService.saveTodayMessage(message)
        } catch {
            if todayMessage == nil, let cached = SharedDataService.getTodayMessage() {
                todayMessage = LoveMessage(id: "cached", content: cached.content, subtitle: cached.subtitle, tone: nil, createdAt: nil, isSpecial: nil)
            }
        }
    }

    func saveMessage(_ message: LoveMessage, context: ModelContext) {
        let saved = SavedMessage(
            messageId: message.id,
            content: message.content,
            subtitle: message.displaySubtitle,
            tone: message.tone ?? "tierno"
        )
        context.insert(saved)
        showSavedConfirmation = true
    }

    func isMessageSaved(_ message: LoveMessage, savedMessages: [SavedMessage]) -> Bool {
        savedMessages.contains { $0.messageId == message.id }
    }

    func testNotification() async {
        do {
            try await APIService.shared.testNotification()
        } catch {
            errorMessage = "No se pudo enviar la notificación de prueba"
        }
    }
}
