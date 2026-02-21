import Foundation

nonisolated struct RemoteConfig: Codable, Sendable {
    let popup: PopupConfig?
}

nonisolated struct PopupConfig: Codable, Sendable {
    let enabled: Bool
    let type: String
    let title: String
    let subtitle: String
    let options: [PopupOption]
}

nonisolated struct PopupOption: Codable, Sendable, Identifiable {
    let id: String
    let label: String
    let emoji: String
    let role: String
}

nonisolated struct RoleResponse: Codable, Sendable {
    let role: String?
}

nonisolated struct RoleRegisterResponse: Codable, Sendable {
    let success: Bool?
    let role: String?
}
