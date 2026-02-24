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
    /// Set to true once ContentView has fully appeared
    static var appIsReady = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        // Home screen Quick Actions (long-press app icon)
        application.shortcutItems = [
            UIApplicationShortcutItem(
                type: "com.nalguitas.openchat",
                localizedTitle: "💬  Chat",
                localizedSubtitle: "Abrir el chat",
                icon: UIApplicationShortcutIcon(systemImageName: "bubble.left.and.bubble.right.fill"),
                userInfo: nil
            ),
            UIApplicationShortcutItem(
                type: "com.nalguitas.openpay",
                localizedTitle: "💸  Nalguitas Pay",
                localizedSubtitle: "Enviar dinero",
                icon: UIApplicationShortcutIcon(systemImageName: "dollarsign.circle.fill"),
                userInfo: nil
            )
        ]
        
        // Handle shortcut if app was launched from one
        if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            handleShortcut(shortcutItem)
        }
        
        return true
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        handleShortcut(shortcutItem)
        completionHandler(true)
    }
    
    private func handleShortcut(_ item: UIApplicationShortcutItem) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if item.type == "com.nalguitas.openchat" || item.type == "com.nalguitas.openpay" {
                NotificationCenter.default.post(name: .switchToChatTab, object: nil)
            }
        }
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
        // App is in foreground — safe to post immediately with small debounce
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard AppDelegate.appIsReady else { return }
            NotificationCenter.default.post(name: .didReceiveRemoteMessage, object: nil)
        }
        return [.banner, .badge, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        // User tapped a notification — wait for app to be ready, then navigate
        Task { @MainActor in
            // Wait until app is ready (max 8 seconds)
            for _ in 0..<16 {
                if AppDelegate.appIsReady { break }
                try? await Task.sleep(for: .milliseconds(500))
            }
            // Only post if app is ready
            guard AppDelegate.appIsReady else { return }
            
            // Navigate to chat tab
            NotificationCenter.default.post(name: .switchToChatTab, object: nil)
            
            // Small delay then refresh data
            try? await Task.sleep(for: .milliseconds(500))
            NotificationCenter.default.post(name: .didReceiveRemoteMessage, object: nil)
        }
    }
}

extension Notification.Name {
    static let didReceiveRemoteMessage = Notification.Name("didReceiveRemoteMessage")
    static let switchToChatTab = Notification.Name("switchToChatTab")
}
