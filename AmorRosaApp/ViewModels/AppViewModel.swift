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

    private let fallbackMessages: [LoveMessage] = [
        LoveMessage(id: "f1", content: "Te quería decir algo: hoy te ves preciosa.", subtitle: "Para ti", tone: "tierno", createdAt: nil, isSpecial: nil),
        LoveMessage(id: "f2", content: "Paso por aquí solo para recordarte que te quiero.", subtitle: "Un susurro", tone: "romántico", createdAt: nil, isSpecial: nil),
        LoveMessage(id: "f3", content: "Ojalá estés sonriendo ahora mismo.", subtitle: "Pensando en ti", tone: "tierno", createdAt: nil, isSpecial: nil),
        LoveMessage(id: "f4", content: "Eres mi lugar tranquilo.", subtitle: "Siempre", tone: "profundo", createdAt: nil, isSpecial: nil),
        LoveMessage(id: "f5", content: "Si pudiera elegir a alguien otra vez, te elegiría a ti.", subtitle: "Con todo", tone: "romántico", createdAt: nil, isSpecial: nil),
        LoveMessage(id: "f6", content: "No necesito un motivo para pensarte. Lo hago todo el tiempo.", subtitle: "De corazón", tone: "tierno", createdAt: nil, isSpecial: nil),
        LoveMessage(id: "f7", content: "Eres lo más bonito que me ha pasado.", subtitle: "Solo para ti", tone: "profundo", createdAt: nil, isSpecial: nil),
        LoveMessage(id: "f8", content: "Hoy no pude evitar sonreír pensando en ti.", subtitle: "Así de simple", tone: "divertido", createdAt: nil, isSpecial: nil),
    ]

    func loadTodayMessage() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let message = try await APIService.shared.fetchTodayMessage()
            todayMessage = message
            SharedDataService.saveTodayMessage(message)
        } catch {
            if todayMessage == nil {
                let dayIndex = Calendar.current.component(.day, from: Date()) % fallbackMessages.count
                todayMessage = fallbackMessages[dayIndex]
                if let msg = todayMessage {
                    SharedDataService.saveTodayMessage(msg)
                }
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
