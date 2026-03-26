import Foundation

enum ProfileCache {
    static func save(_ profile: UserProfile, for username: String) {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: "profile_cache_\(username)")
    }

    static func load(for username: String) -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: "profile_cache_\(username)"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
        else { return nil }
        return profile
    }
}
