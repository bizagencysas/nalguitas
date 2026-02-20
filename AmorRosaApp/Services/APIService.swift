import Foundation
import UIKit

nonisolated final class APIService: Sendable {
    static let shared = APIService()

    private let baseURL: String = "https://dev-2em1f73schcayului3oej.rorktest.dev"

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
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
}
