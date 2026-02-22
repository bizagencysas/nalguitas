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

            Tab("Explorar", systemImage: "sparkles", value: 1) {
                ExploreView(isAdmin: true)
            }

            Tab("Chat", systemImage: "bubble.left.and.bubble.right.fill", value: 2) {
                ChatView(isAdmin: true)
            }

            Tab("Vista Novia", systemImage: "heart.fill", value: 3) {
                TodayView(viewModel: viewModel)
            }

            Tab("Guardados", systemImage: "bookmark.fill", value: 4) {
                SavedView()
            }

            Tab("Historial", systemImage: "clock.arrow.circlepath", value: 5) {
                HistoryView()
            }

            Tab("Ajustes", systemImage: "gearshape.fill", value: 6) {
                SettingsView(notificationService: notificationService, viewModel: viewModel)
            }
        }
        .tint(Theme.rosePrimary)
        .onChange(of: selectedTab) { _, _ in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .task {
            await notificationService.requestPermission()
        }
    }
}
