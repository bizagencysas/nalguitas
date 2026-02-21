import SwiftUI

struct AdminRootView: View {
    let viewModel: AppViewModel
    let notificationService: NotificationService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Admin", systemImage: "crown.fill", value: 0) {
                AdminView()
            }

            Tab("Vista Novia", systemImage: "heart.fill", value: 1) {
                TodayView(viewModel: viewModel)
            }

            Tab("Guardados", systemImage: "bookmark.fill", value: 2) {
                SavedView()
            }

            Tab("Historial", systemImage: "clock.arrow.circlepath", value: 3) {
                HistoryView()
            }

            Tab("Ajustes", systemImage: "gearshape.fill", value: 4) {
                SettingsView(notificationService: notificationService, viewModel: viewModel)
            }
        }
        .tint(Theme.rosePrimary)
        .task {
            await notificationService.checkStatus()
        }
    }
}
