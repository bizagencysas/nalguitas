import Foundation
import UserNotifications
import UIKit

@Observable
@MainActor
class NotificationService {
    var isAuthorized = false
    var deviceToken: String?

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            isAuthorized = false
        }
    }

    func checkStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func handleDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = token
        Task {
            let isAdmin = UserDefaults.standard.bool(forKey: "isAdminDevice")
            try? await APIService.shared.registerDevice(token: token, isAdmin: isAdmin)
        }
    }
}
