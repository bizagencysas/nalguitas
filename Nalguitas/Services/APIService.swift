import Foundation
import UIKit

nonisolated final class APIService: Sendable {
    static let shared = APIService()

    private let baseURL: String = "https://dev-2em1f73schcayului3oej.rorktest.dev"

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

    func fetchTodayMessage() async throws -> LoveMessage {
        let url = URL(string: "\(baseURL)/api/messages/today")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decoder.decode(LoveMessage.self, from: data)
    }

    func fetchMessages() async throws -> [LoveMessage] {
        let url = URL(string: "\(baseURL)/api/messages")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try decoder.decode(MessagesResponse.self, from: data)
        return response.messages
    }

    func registerDevice(token: String) async throws {
        let url = URL(string: "\(baseURL)/api/device/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let body = DeviceRegistration(token: token, deviceId: deviceId)
        request.httpBody = try JSONEncoder().encode(body)

        let (_, _) = try await URLSession.shared.data(for: request)
    }

    func testNotification() async throws {
        let url = URL(string: "\(baseURL)/api/notifications/test")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (_, _) = try await URLSession.shared.data(for: request)
    }

    func sendNotification(message: String) async throws {
        let url = URL(string: "\(baseURL)/api/notifications/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["message": message]
        request.httpBody = try JSONEncoder().encode(body)
        let (_, _) = try await URLSession.shared.data(for: request)
    }

    func createMessage(content: String, subtitle: String, tone: String) async throws {
        let url = URL(string: "\(baseURL)/api/trpc/messages.create")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = CreateMessagePayload(json: CreateMessageInput(content: content, subtitle: subtitle, tone: tone, isSpecial: false, priority: 1))
        request.httpBody = try JSONEncoder().encode(payload)
        let (_, _) = try await URLSession.shared.data(for: request)
    }

    func deleteMessage(id: String) async throws {
        let url = URL(string: "\(baseURL)/api/trpc/messages.delete")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload = DeleteMessagePayload(json: DeleteMessageInput(id: id))
        request.httpBody = try JSONEncoder().encode(payload)
        let (_, _) = try await URLSession.shared.data(for: request)
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
