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

    func loadTodayMessage(context: ModelContext? = nil) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let message = try await APIService.shared.fetchTodayMessage()
            if message.id.isEmpty || message.content.isEmpty {
                todayMessage = nil
            } else {
                let isNew = todayMessage?.id != message.id
                todayMessage = message
                SharedDataService.saveTodayMessage(message)
                if isNew, let context {
                    saveToHistory(message, context: context)
                }
            }
        } catch {
            if todayMessage == nil, let cached = SharedDataService.getTodayMessage(), !cached.content.isEmpty {
                todayMessage = LoveMessage(id: "cached", content: cached.content, subtitle: cached.subtitle, tone: nil, createdAt: nil, isSpecial: nil)
            }
        }
    }

    private func saveToHistory(_ message: LoveMessage, context: ModelContext) {
        let content = message.content
        let descriptor = FetchDescriptor<MessageHistory>(predicate: #Predicate { $0.content == content })
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }
        let entry = MessageHistory(
            content: message.content,
            subtitle: message.displaySubtitle,
            source: "message",
            receivedAt: message.createdAt ?? Date()
        )
        context.insert(entry)
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
