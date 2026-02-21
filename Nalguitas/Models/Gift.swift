import Foundation

struct Gift: Codable, Identifiable, Sendable {
    let id: String
    let characterUrl: String
    let characterName: String
    let message: String
    let subtitle: String
    let giftType: String
    let createdAt: String
    let seen: Bool
}

struct GiftCharacter: Identifiable, Sendable {
    let id: String
    let name: String
    let imageUrl: String
    let emoji: String
    
    static let characters: [GiftCharacter] = [
        GiftCharacter(id: "capybara_roses", name: "Capibara con Rosas", imageUrl: "capybara_roses.png", emoji: "🌹"),
        GiftCharacter(id: "bear_giftcard", name: "Osito con Gift Card", imageUrl: "bear_giftcard.png", emoji: "💳"),
        GiftCharacter(id: "bunny_chocolates", name: "Conejita con Chocolates", imageUrl: "bunny_chocolates.png", emoji: "🍫"),
        GiftCharacter(id: "cat_letter", name: "Gatito con Carta", imageUrl: "cat_letter.png", emoji: "💌"),
        GiftCharacter(id: "penguin_gift", name: "Pingüino con Regalo", imageUrl: "penguin_gift.png", emoji: "🎁"),
        GiftCharacter(id: "fox_coffee", name: "Zorrito con Café", imageUrl: "fox_coffee.png", emoji: "☕"),
        GiftCharacter(id: "duck_balloons", name: "Patito con Globos", imageUrl: "duck_balloons.png", emoji: "🎈"),
        GiftCharacter(id: "panda_icecream", name: "Panda con Helado", imageUrl: "panda_icecream.png", emoji: "🍦"),
        GiftCharacter(id: "hamster_sunflower", name: "Hamster con Girasol", imageUrl: "hamster_sunflower.png", emoji: "🌻"),
    ]
    
    static func imageURL(for characterId: String) -> URL? {
        let baseURL = "https://raw.githubusercontent.com/bizagencysas/nalguitas/main/backend/characters"
        return URL(string: "\(baseURL)/\(characterId).png")
    }
}
