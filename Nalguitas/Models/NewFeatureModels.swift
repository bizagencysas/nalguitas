import Foundation

// MARK: - Love Coupon
nonisolated struct LoveCoupon: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
    let emoji: String
    let createdAt: String?
    let redeemed: Bool
    let redeemedAt: String?
}

// MARK: - Daily Question
nonisolated struct DailyQuestion: Codable, Identifiable, Sendable {
    let id: String?
    let question: String
    let category: String?
    let answered: Bool?
    let answer: String?
    let answeredAt: String?
    let shownDate: String?
}

// MARK: - Mood
nonisolated struct MoodEntry: Codable, Identifiable, Sendable {
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
nonisolated struct SpecialDate: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let date: String
    let emoji: String
    let reminderDaysBefore: Int?
}

// MARK: - Days Together
nonisolated struct DaysTogether: Codable, Sendable {
    let totalDays: Int
    let years: Int
    let months: Int
    let days: Int
    let startDate: String
}

// MARK: - Song
nonisolated struct Song: Codable, Identifiable, Sendable {
    let id: String
    let youtubeUrl: String
    let title: String
    let artist: String
    let message: String
    let createdAt: String?
    let seen: Bool?
}

// MARK: - Achievement
nonisolated struct Achievement: Codable, Identifiable, Sendable {
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
nonisolated struct SharedPhoto: Codable, Identifiable, Sendable {
    let id: String
    let imageData: String?
    let caption: String
    let uploadedBy: String
    let createdAt: String?
}

// MARK: - Plan
nonisolated struct DatePlan: Codable, Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
    let category: String
    let proposedDate: String
    let proposedTime: String
    let status: String
    let proposedBy: String
    let createdAt: String?
    
    var statusEmoji: String {
        switch status {
        case "aceptado": return "✅"
        case "completado": return "🎉"
        case "cancelado": return "❌"
        default: return "⏳"
        }
    }
}

struct PlanCategory: Identifiable, Sendable {
    let id: String
    let name: String
    let emoji: String
    
    static let categories: [PlanCategory] = [
        PlanCategory(id: "cita", name: "Cita", emoji: "💕"),
        PlanCategory(id: "cena", name: "Cena Romántica", emoji: "🍽️"),
        PlanCategory(id: "viaje", name: "Viaje", emoji: "✈️"),
        PlanCategory(id: "paseo", name: "Paseo", emoji: "🚶‍♂️"),
        PlanCategory(id: "actividad", name: "Actividad", emoji: "🎯"),
        PlanCategory(id: "sorpresa", name: "Sorpresa", emoji: "🎁"),
        PlanCategory(id: "pelicula", name: "Película/Serie", emoji: "🎬"),
        PlanCategory(id: "aventura", name: "Aventura", emoji: "🏔️"),
    ]
}

// MARK: - Love Challenge (engagement feature)
struct LoveChallenge: Identifiable, Sendable {
    let id: Int
    let challenge: String
    let emoji: String
    
    static let challenges: [LoveChallenge] = [
        LoveChallenge(id: 1, challenge: "Envíale un audio diciéndole lo que más amas de ella", emoji: "🎙️"),
        LoveChallenge(id: 2, challenge: "Cocina algo especial para los dos", emoji: "👨‍🍳"),
        LoveChallenge(id: 3, challenge: "Escribele una carta de amor a mano", emoji: "✉️"),
        LoveChallenge(id: 4, challenge: "Planea una cita sorpresa", emoji: "🎁"),
        LoveChallenge(id: 5, challenge: "Dile 10 cosas que amas de ella sin repetir", emoji: "💝"),
        LoveChallenge(id: 6, challenge: "Recrea su primera cita juntos", emoji: "🔄"),
        LoveChallenge(id: 7, challenge: "Haz un video con fotos de ustedes juntos", emoji: "📹"),
        LoveChallenge(id: 8, challenge: "Dedícale una canción y explica por qué", emoji: "🎵"),
        LoveChallenge(id: 9, challenge: "Hazle un masaje de 15 minutos sin que lo pida", emoji: "💆"),
        LoveChallenge(id: 10, challenge: "Llama a su mamá y dile algo bonito de ella", emoji: "📞"),
        LoveChallenge(id: 11, challenge: "Esconde una nota de amor en su bolso", emoji: "📝"),
        LoveChallenge(id: 12, challenge: "Aprende a hacer su postre favorito", emoji: "🍰"),
        LoveChallenge(id: 13, challenge: "Mira las estrellas juntos y cuéntale tus sueños", emoji: "⭐"),
        LoveChallenge(id: 14, challenge: "Crea una playlist de 'nuestra historia' juntos", emoji: "🎶"),
        LoveChallenge(id: 15, challenge: "Dile algo que nunca le hayas dicho", emoji: "💭"),
        LoveChallenge(id: 16, challenge: "Hazle un desayuno en la cama", emoji: "🥞"),
        LoveChallenge(id: 17, challenge: "Baila con ella una canción lenta en la sala", emoji: "💃"),
        LoveChallenge(id: 18, challenge: "Escríbele un poema (no importa si es malo)", emoji: "📜"),
        LoveChallenge(id: 19, challenge: "Compra su dulce favorito sin que te lo pida", emoji: "🍫"),
        LoveChallenge(id: 20, challenge: "Dile 'te amo' en 5 idiomas diferentes", emoji: "🌍"),
    ]
    
    static func todayChallenge() -> LoveChallenge {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return challenges[(day - 1) % challenges.count]
    }
}

// MARK: - Romantic Fact
struct RomanticFact: Identifiable, Sendable {
    let id: Int
    let fact: String
    
    static let facts: [RomanticFact] = [
        RomanticFact(id: 1, fact: "Abrazar a tu pareja reduce el estrés hasta un 50%. ¡Abraza más! 🤗"),
        RomanticFact(id: 2, fact: "Las parejas que se ríen juntas duran más. La risa fortalece el vínculo. 😂"),
        RomanticFact(id: 3, fact: "Tomarse de la mano sincroniza los ritmos cardíacos de la pareja. 💓"),
        RomanticFact(id: 4, fact: "El amor activa las mismas zonas del cerebro que el chocolate. 🍫"),
        RomanticFact(id: 5, fact: "Las parejas que cocinan juntas reportan más felicidad. 👩‍🍳"),
        RomanticFact(id: 6, fact: "El enamoramiento dura entre 18 y 36 meses... después viene algo mejor: amor real. ❤️"),
        RomanticFact(id: 7, fact: "Los besos liberan oxitocina, la 'hormona del amor'. 💋"),
        RomanticFact(id: 8, fact: "Mirar a los ojos de tu pareja por 4 minutos puede enamorarte más. 👀"),
        RomanticFact(id: 9, fact: "Las parejas que dicen 'nosotros' en vez de 'yo' son más felices. 💑"),
        RomanticFact(id: 10, fact: "Dormir acurrucados regula la temperatura y reduce la ansiedad. 🛏️"),
        RomanticFact(id: 11, fact: "La gratitud es el predictor #1 de relaciones duraderas. 🙏"),
        RomanticFact(id: 12, fact: "Los pequeños gestos importan más que los grandes regalos. 🌸"),
        RomanticFact(id: 13, fact: "Tu corazón late literalmente al ritmo de tu pareja cuando están cerca. 💕"),
        RomanticFact(id: 14, fact: "Las parejas que viajan juntas tienen relaciones más fuertes. ✈️"),
        RomanticFact(id: 15, fact: "Decir 'te amo' antes de dormir mejora la calidad del sueño. 🌙"),
    ]
    
    static func todayFact() -> RomanticFact {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return facts[(day - 1) % facts.count]
    }
}

// MARK: - Chat Message
nonisolated struct ChatMessage: Codable, Identifiable, Sendable {
    let id: String
    let sender: String
    let type: String
    let content: String
    let mediaData: String?
    let mediaUrl: String?
    let replyTo: String?
    let seen: Bool?
    let createdAt: String?
}

// MARK: - AI Sticker
nonisolated struct AISticker: Codable, Identifiable, Sendable {
    let id: String
    let prompt: String
    let imageData: String
    let createdAt: String?
}
