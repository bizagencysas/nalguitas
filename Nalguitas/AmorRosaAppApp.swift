import SwiftUI
import SwiftData
import UserNotifications

@main
struct AmorRosaAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([SavedMessage.self, MessageHistory.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Task { @MainActor in
            let isAdmin = UserDefaults.standard.bool(forKey: "isAdminDevice")
            try? await APIService.shared.registerDevice(token: token, isAdmin: isAdmin)
        }
    }

    nonisolated func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Small delay to debounce rapid notifications
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            NotificationCenter.default.post(name: .didReceiveRemoteMessage, object: nil)
        }
        return [.banner, .badge, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // Longer delay for cold start — gives SwiftUI time to mount views + SwiftData
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3.0))
            NotificationCenter.default.post(name: .didReceiveRemoteMessage, object: nil)
        }
    }
}

extension Notification.Name {
    static let didReceiveRemoteMessage = Notification.Name("didReceiveRemoteMessage")
}
