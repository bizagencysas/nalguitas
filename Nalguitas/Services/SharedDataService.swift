import Foundation
import WidgetKit

struct SharedDataService {
    static let appGroupID = "group.app.rork.amor-rosa-app"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func saveTodayMessage(_ message: LoveMessage) {
        guard let defaults = sharedDefaults else { return }
        defaults.set(message.content, forKey: "todayMessage")
        defaults.set(message.displaySubtitle, forKey: "todaySubtitle")
        defaults.set(Date().timeIntervalSince1970, forKey: "lastUpdated")
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func getTodayMessage() -> (content: String, subtitle: String)? {
        guard let defaults = sharedDefaults else { return nil }
        guard let content = defaults.string(forKey: "todayMessage") else { return nil }
        let subtitle = defaults.string(forKey: "todaySubtitle") ?? "Pensado para ti hoy"
        return (content, subtitle)
    }

    static func saveLastNotificationMessage(_ content: String, subtitle: String = "Para ti") {
        guard let defaults = sharedDefaults else { return }
        defaults.set(content, forKey: "lastNotification")
        defaults.set(Date().timeIntervalSince1970, forKey: "lastNotificationTime")
    }
}
