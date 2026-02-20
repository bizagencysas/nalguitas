import Foundation

nonisolated struct LoveMessage: Codable, Identifiable, Sendable, Hashable {
    let id: String
    let content: String
    let subtitle: String?
    let tone: String?
    let createdAt: Date?
    let isSpecial: Bool?

    var displaySubtitle: String {
        subtitle ?? "Pensado para ti hoy"
    }
}

nonisolated struct MessagesResponse: Codable, Sendable {
    let messages: [LoveMessage]
    let todayMessage: LoveMessage?
}

nonisolated struct DeviceRegistration: Codable, Sendable {
    let token: String
    let deviceId: String
}

nonisolated struct APIResponse: Codable, Sendable {
    let success: Bool
    let message: String?
}
