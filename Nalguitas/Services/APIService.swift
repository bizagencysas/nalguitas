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
        let input = CreateMessageInput(content: content, subtitle: subtitle, tone: tone, isSpecial: false, priority: 1)
        request.httpBody = try JSONEncoder().encode(input)
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

    // MARK: - Gifts
    
    func fetchUnseenGifts() async throws -> [Gift] {
        let url = URL(string: "\(baseURL)/api/gifts/unseen")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try checkResponse(data, response)
        return try decoder.decode([Gift].self, from: data)
    }
    
    func fetchGifts() async throws -> [Gift] {
        let url = URL(string: "\(baseURL)/api/gifts")!
        let (data, response) = try await URLSession.shared.data(from: url)
        try checkResponse(data, response)
        return try decoder.decode([Gift].self, from: data)
    }
    
    func createGift(characterUrl: String, characterName: String, message: String, subtitle: String, giftType: String) async throws {
        let url = URL(string: "\(baseURL)/api/gifts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "characterUrl": characterUrl,
            "characterName": characterName,
            "message": message,
            "subtitle": subtitle,
            "giftType": giftType,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    
    func markGiftSeen(id: String) async throws {
        let url = URL(string: "\(baseURL)/api/gifts/\(id)/seen")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    
    // MARK: - Coupons
    func fetchCoupons() async throws -> [LoveCoupon] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/coupons")!)
        try checkResponse(data, response)
        return try decoder.decode([LoveCoupon].self, from: data)
    }
    func createCoupon(title: String, description: String, emoji: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/coupons")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["title": title, "description": description, "emoji": emoji])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    func redeemCoupon(id: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/coupons/\(id)/redeem")!)
        request.httpMethod = "POST"
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    
    // MARK: - Daily Questions
    func fetchTodayQuestion() async throws -> DailyQuestion {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/questions/today")!)
        try checkResponse(data, response)
        return try decoder.decode(DailyQuestion.self, from: data)
    }
    func answerQuestion(id: String, answer: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/questions/\(id)/answer")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["answer": answer])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    func fetchAnsweredQuestions() async throws -> [DailyQuestion] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/questions/answered")!)
        try checkResponse(data, response)
        return try decoder.decode([DailyQuestion].self, from: data)
    }
    
    // MARK: - Moods
    func saveMood(mood: String, emoji: String, note: String?) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/moods")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = ["mood": mood, "emoji": emoji]
        if let note = note, !note.isEmpty { body["note"] = note }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    func fetchTodayMood() async throws -> MoodEntry? {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/moods/today")!)
        try checkResponse(data, response)
        let result = try decoder.decode(MoodEntry.self, from: data)
        return result.id == nil ? nil : result
    }
    func fetchMoods() async throws -> [MoodEntry] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/moods")!)
        try checkResponse(data, response)
        return try decoder.decode([MoodEntry].self, from: data)
    }
    
    // MARK: - Special Dates
    func fetchSpecialDates() async throws -> [SpecialDate] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/dates")!)
        try checkResponse(data, response)
        return try decoder.decode([SpecialDate].self, from: data)
    }
    func createSpecialDate(title: String, date: String, emoji: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/dates")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["title": title, "date": date, "emoji": emoji])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    
    // MARK: - Days Together
    func fetchDaysTogether() async throws -> DaysTogether {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/days-together")!)
        try checkResponse(data, response)
        return try decoder.decode(DaysTogether.self, from: data)
    }
    
    // MARK: - Songs
    func fetchSongs() async throws -> [Song] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/songs")!)
        try checkResponse(data, response)
        return try decoder.decode([Song].self, from: data)
    }
    func sendSong(youtubeUrl: String, title: String, artist: String, message: String, fromGirlfriend: Bool = false) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/songs")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["youtubeUrl": youtubeUrl, "title": title, "artist": artist, "message": message, "fromGirlfriend": fromGirlfriend])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    func markSongSeen(id: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/songs/\(id)/seen")!)
        request.httpMethod = "POST"
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    
    // MARK: - Achievements
    func fetchAchievements() async throws -> [Achievement] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/achievements")!)
        try checkResponse(data, response)
        return try decoder.decode([Achievement].self, from: data)
    }
    
    // MARK: - Photos
    func fetchPhotos() async throws -> [SharedPhoto] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/photos")!)
        try checkResponse(data, response)
        return try decoder.decode([SharedPhoto].self, from: data)
    }
    func uploadPhoto(imageData: String, caption: String, uploadedBy: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/photos")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["imageData": imageData, "caption": caption, "uploadedBy": uploadedBy])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    func fetchPhotoById(id: String) async throws -> SharedPhoto {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/photos/\(id)")!)
        try checkResponse(data, response)
        return try decoder.decode(SharedPhoto.self, from: data)
    }
    
    // MARK: - Plans
    func fetchPlans() async throws -> [DatePlan] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/plans")!)
        try checkResponse(data, response)
        return try decoder.decode([DatePlan].self, from: data)
    }
    func createPlan(title: String, description: String, category: String, date: String, time: String, proposedBy: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/plans")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["title": title, "description": description, "category": category, "proposedDate": date, "proposedTime": time, "proposedBy": proposedBy])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    func updatePlanStatus(id: String, status: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/plans/\(id)/status")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["status": status])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    
    // MARK: - Chat
    func fetchChatMessages(limit: Int = 50, before: String? = nil) async throws -> [ChatMessage] {
        var urlStr = "\(baseURL)/api/chat/messages?limit=\(limit)"
        if let b = before { urlStr += "&before=\(b)" }
        let (data, response) = try await URLSession.shared.data(from: URL(string: urlStr)!)
        try checkResponse(data, response)
        return try decoder.decode([ChatMessage].self, from: data)
    }
    func sendChatMessage(sender: String, type: String, content: String, mediaData: String? = nil, mediaUrl: String? = nil, replyTo: String? = nil) async throws -> ChatMessage {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/chat/send")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var body: [String: Any] = ["sender": sender, "type": type, "content": content]
        if let md = mediaData { body["mediaData"] = md }
        if let mu = mediaUrl { body["mediaUrl"] = mu }
        if let rt = replyTo { body["replyTo"] = rt }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
        return try decoder.decode(ChatMessage.self, from: data)
    }
    func markChatSeen(sender: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/chat/seen")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["sender": sender])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    func fetchUnseenChatCount(sender: String) async throws -> Int {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/chat/unseen?sender=\(sender)")!)
        try checkResponse(data, response)
        struct R: Decodable { let count: Int }
        return try decoder.decode(R.self, from: data).count
    }
    func generateAISticker(prompt: String) async throws -> AISticker {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/stickers/generate")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["prompt": prompt])
        request.timeoutInterval = 60
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
        return try decoder.decode(AISticker.self, from: data)
    }
    func fetchAIStickers() async throws -> [AISticker] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/stickers")!)
        try checkResponse(data, response)
        return try decoder.decode([AISticker].self, from: data)
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

// MARK: - Custom Facts
extension APIService {
    func fetchRandomFact() async throws -> CustomFact {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/facts/random")!)
        try checkResponse(data, response)
        return try decoder.decode(CustomFact.self, from: data)
    }
    func fetchAllFacts() async throws -> [CustomFact] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/facts")!)
        try checkResponse(data, response)
        return try decoder.decode([CustomFact].self, from: data)
    }
    func createFact(fact: String) async throws -> CustomFact {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/facts")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["fact": fact])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
        return try decoder.decode(CustomFact.self, from: data)
    }
    func deleteFact(id: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/facts/\(id)")!)
        request.httpMethod = "DELETE"
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    
    // MARK: - English Word of the Day
    func fetchTodayWord() async throws -> EnglishWord {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/words/today")!)
        try checkResponse(data, response)
        return try decoder.decode(EnglishWord.self, from: data)
    }
    func fetchAiExample(word: String, translation: String, dayOfYear: Int) async throws -> String {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/words/ai-example")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["word": word, "translation": translation, "dayOfYear": "\(dayOfYear)"])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
        let result = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return result?["aiExample"] as? String ?? ""
    }
    
    // MARK: - Scratch Cards
    func fetchScratchCards() async throws -> [ScratchCard] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/scratch-cards")!)
        try checkResponse(data, response)
        return try decoder.decode([ScratchCard].self, from: data)
    }
    func fetchAvailableScratchCard() async throws -> ScratchCard? {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/scratch-cards/available")!)
        try checkResponse(data, response)
        struct AvailableResponse: Codable { let available: Bool; let card: ScratchCard? }
        let result = try decoder.decode(AvailableResponse.self, from: data)
        return result.card
    }
    func createScratchCard(prize: String, emoji: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/scratch-cards")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["prize": prize, "emoji": emoji])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    func scratchCard(id: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/scratch-cards/\(id)/scratch")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    
    // MARK: - Roulette
    func fetchRouletteOptions(category: String) async throws -> [RouletteOption] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/roulette/\(category)")!)
        try checkResponse(data, response)
        return try decoder.decode([RouletteOption].self, from: data)
    }
    func createRouletteOption(category: String, optionText: String, addedBy: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/roulette")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["category": category, "optionText": optionText, "addedBy": addedBy])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    func deleteRouletteOption(id: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/roulette/\(id)")!)
        request.httpMethod = "DELETE"
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    
    // MARK: - Diary
    func writeDiaryEntry(author: String, content: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/diary")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["author": author, "content": content])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    func fetchTodayDiary(author: String) async throws -> DiaryEntry {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/diary/\(author)/today")!)
        try checkResponse(data, response)
        return try decoder.decode(DiaryEntry.self, from: data)
    }
    func fetchPartnerDiary(author: String) async throws -> [DiaryEntry] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/diary/\(author)/partner")!)
        try checkResponse(data, response)
        return try decoder.decode([DiaryEntry].self, from: data)
    }
    
    // MARK: - Points
    func fetchPoints(username: String) async throws -> PointsBalance {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/points/\(username)")!)
        try checkResponse(data, response)
        return try decoder.decode(PointsBalance.self, from: data)
    }
    func addPoints(username: String, points: Int, reason: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/points")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        struct PointsInput: Encodable { let username: String; let points: Int; let reason: String }
        request.httpBody = try JSONEncoder().encode(PointsInput(username: username, points: points, reason: reason))
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    
    // MARK: - Rewards
    func fetchRewards() async throws -> [Reward] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/rewards")!)
        try checkResponse(data, response)
        return try decoder.decode([Reward].self, from: data)
    }
    func createReward(title: String, emoji: String, cost: Int) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/rewards")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        struct RewardInput: Encodable { let title: String; let emoji: String; let cost: Int }
        request.httpBody = try JSONEncoder().encode(RewardInput(title: title, emoji: emoji, cost: cost))
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    func redeemReward(id: String, redeemedBy: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/rewards/\(id)/redeem")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["redeemedBy": redeemedBy])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    
    // MARK: - Experiences
    func fetchExperiences() async throws -> [Experience] {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/experiences")!)
        try checkResponse(data, response)
        return try decoder.decode([Experience].self, from: data)
    }
    func createExperience(title: String, description: String, emoji: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/experiences")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["title": title, "description": description, "emoji": emoji])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    func completeExperience(id: String, photo: String?) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/experiences/\(id)/complete")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["photo": photo ?? ""])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    func deleteExperience(id: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/experiences/\(id)")!)
        request.httpMethod = "DELETE"
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    
    // MARK: - Profiles (BBM-style)
    func fetchProfile(username: String) async throws -> UserProfile {
        let (data, response) = try await URLSession.shared.data(from: URL(string: "\(baseURL)/api/profiles/\(username)")!)
        try checkResponse(data, response)
        return try decoder.decode(UserProfile.self, from: data)
    }
    func updateProfile(username: String, displayName: String, avatar: String, statusMessage: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/profiles/\(username)")!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["displayName": displayName, "avatar": avatar, "statusMessage": statusMessage])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    func updateAvatar(username: String, avatar: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/profiles/\(username)/avatar")!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["avatar": avatar])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
    func updateStatus(username: String, statusMessage: String) async throws {
        var request = URLRequest(url: URL(string: "\(baseURL)/api/profiles/\(username)/status")!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["statusMessage": statusMessage])
        let (data, response) = try await URLSession.shared.data(for: request)
        try checkResponse(data, response)
    }
}

nonisolated struct CustomFact: Codable, Identifiable, Sendable {
    let id: String
    let fact: String
    var createdAt: String?
}
