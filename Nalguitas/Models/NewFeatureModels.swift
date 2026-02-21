import Foundation

// MARK: - Love Coupon
struct LoveCoupon: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
    let emoji: String
    let createdAt: String?
    let redeemed: Bool
    let redeemedAt: String?
}

// MARK: - Daily Question
struct DailyQuestion: Codable, Identifiable, Sendable {
    let id: String?
    let question: String
    let category: String?
    let answered: Bool?
    let answer: String?
    let answeredAt: String?
    let shownDate: String?
}

// MARK: - Mood
struct MoodEntry: Codable, Identifiable, Sendable {
    let id: String?
    let mood: String
    let emoji: String
    let note: String?
    let createdAt: String?
}

struct MoodOption: Identifiable, Sendable {
    let id: String
    let mood: String
    let emoji: String
    let color: String
    
    static let options: [MoodOption] = [
        MoodOption(id: "feliz", mood: "Feliz", emoji: "😊", color: "happy"),
        MoodOption(id: "enamorada", mood: "Enamorada", emoji: "🥰", color: "love"),
        MoodOption(id: "tranquila", mood: "Tranquila", emoji: "😌", color: "calm"),
        MoodOption(id: "emocionada", mood: "Emocionada", emoji: "🤩", color: "excited"),
        MoodOption(id: "agradecida", mood: "Agradecida", emoji: "🙏", color: "grateful"),
        MoodOption(id: "nostalgica", mood: "Nostálgica", emoji: "🥲", color: "nostalgic"),
        MoodOption(id: "cansada", mood: "Cansada", emoji: "😴", color: "tired"),
        MoodOption(id: "triste", mood: "Triste", emoji: "😢", color: "sad"),
        MoodOption(id: "ansiosa", mood: "Ansiosa", emoji: "😰", color: "anxious"),
        MoodOption(id: "enojada", mood: "Enojada", emoji: "😤", color: "angry"),
        MoodOption(id: "divertida", mood: "Divertida", emoji: "😂", color: "fun"),
        MoodOption(id: "pensativa", mood: "Pensativa", emoji: "🤔", color: "pensive"),
    ]
}

// MARK: - Special Date
struct SpecialDate: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let date: String
    let emoji: String
    let reminderDaysBefore: Int?
}

// MARK: - Days Together
struct DaysTogether: Codable, Sendable {
    let totalDays: Int
    let years: Int
    let months: Int
    let days: Int
    let startDate: String
}

// MARK: - Song
struct Song: Codable, Identifiable, Sendable {
    let id: String
    let youtubeUrl: String
    let title: String
    let artist: String
    let message: String
    let createdAt: String?
    let seen: Bool?
}

// MARK: - Achievement
struct Achievement: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
    let emoji: String
    let category: String
    let unlocked: Bool
    let unlockedAt: String?
    let progress: Int
    let target: Int
    
    var progressPercent: Double {
        guard target > 0 else { return 0 }
        return min(Double(progress) / Double(target), 1.0)
    }
}

// MARK: - Photo
struct SharedPhoto: Codable, Identifiable, Sendable {
    let id: String
    let imageData: String?
    let caption: String
    let uploadedBy: String
    let createdAt: String?
}
