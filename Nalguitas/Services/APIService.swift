import Foundation
import UIKit

nonisolated enum APIError: Error, Sendable, LocalizedError {
    case serverError(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .serverError(let msg): return msg
        case .networkError(let msg): return msg
        }
    }
}

nonisolated struct ErrorResponse: Codable, Sendable {
    let error: String?
}

nonisolated final class APIService: Sendable {
    static let shared = APIService()

    private let baseURL: String = "https://nalguitas.onrender.com"

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if str.isEmpty { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Empty date") }
            if let date = formatter.date(from: str) { return date }
            if let date = fallback.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(str)")
        }
        return d
    }()

    private func checkResponse(_ data: Data, _ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard http.statusCode >= 200 && http.statusCode < 300 else {
            if let errorResp = try? JSONDecoder().decode(ErrorResponse.self, from: data), let msg = errorResp.error {
                throw APIError.serverError(msg)
            }
            let text = String(data: data, encoding: .utf8) ?? "Error desconocido"
            throw APIError.serverError(text)
        }
    }

    func fetchTodayMessage() async throws -> LoveMessage {
        let url = URL(string: "\(baseURL)/api/messages/today")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try checkResponse(data, response)
        return try decoder.decode(LoveMessage.self, from: data)
    }

    func fetchMessages() async throws -> [LoveMessage] {
        let url = URL(string: "\(baseURL)/api/messages")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try checkResponse(data, response)
        let resp = try decoder.decode(MessagesResponse.self, from: data)
        return resp.messages
    }

    func registerDevice(token: String, isAdmin: Bool = false) async throws {
        let url = URL(string: "\(baseURL)/api/device/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let body = DeviceRegistrationFull(token: token, deviceId: deviceId, isAdmin: isAdmin)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }

    func testNotification() async throws {
        let url = URL(string: "\(baseURL)/api/notifications/test")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }

    func sendNotification(message: String) async throws {
        let url = URL(string: "\(baseURL)/api/notifications/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["message": message]
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }

    func createMessage(content: String, subtitle: String, tone: String) async throws {
        let url = URL(string: "\(baseURL)/api/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = CreateMessageInput(content: content, subtitle: subtitle, tone: tone, isSpecial: false, priority: 1)
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }

    func deleteMessage(id: String) async throws {
        let url = URL(string: "\(baseURL)/api/messages/\(id)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }

    func sendGirlfriendMessage(content: String) async throws {
        let url = URL(string: "\(baseURL)/api/girlfriend/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["content": content]
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }

    func fetchRemoteConfig() async throws -> RemoteConfig {
        let url = URL(string: "\(baseURL)/api/config")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try checkResponse(data, response)
        return try JSONDecoder().decode(RemoteConfig.self, from: data)
    }

    func registerRole(deviceId: String, role: String) async throws {
        let url = URL(string: "\(baseURL)/api/role/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = ["deviceId": deviceId, "role": role]
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }

    func fetchRole(deviceId: String) async throws -> String? {
        let url = URL(string: "\(baseURL)/api/role/\(deviceId)")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try checkResponse(data, response)
        let result = try JSONDecoder().decode(RoleResponse.self, from: data)
        return result.role
    }

    func fetchGirlfriendMessages() async throws -> [GirlfriendMessage] {
        let url = URL(string: "\(baseURL)/api/girlfriend/messages")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try checkResponse(data, response)
        return try decoder.decode([GirlfriendMessage].self, from: data)
    }
}

nonisolated struct CreateMessageInput: Codable, Sendable {
    let content: String
    let subtitle: String
    let tone: String
    let isSpecial: Bool
    let priority: Int
}

nonisolated struct CreateMessagePayload: Codable, Sendable {
    let json: CreateMessageInput
}

nonisolated struct DeleteMessageInput: Codable, Sendable {
    let id: String
}

nonisolated struct DeleteMessagePayload: Codable, Sendable {
    let json: DeleteMessageInput
}

nonisolated struct DeviceRegistrationFull: Codable, Sendable {
    let token: String
    let deviceId: String
    let isAdmin: Bool
}

nonisolated struct GirlfriendMessage: Codable, Identifiable, Sendable {
    let id: String
    let content: String
    let sentAt: Date?
    let read: Bool?
}
