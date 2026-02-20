import SwiftUI

struct ContentView: View {
    @State private var viewModel = AppViewModel()
    @State private var notificationService = NotificationService()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Hoy", systemImage: "heart.fill", value: 0) {
                TodayView(viewModel: viewModel)
            }

            Tab("Guardados", systemImage: "bookmark.fill", value: 1) {
                SavedView()
            }

            Tab("Ajustes", systemImage: "gearshape.fill", value: 2) {
                SettingsView(notificationService: notificationService, viewModel: viewModel)
            }
        }
        .tint(Theme.rosePrimary)
        .task {
            await notificationService.checkStatus()
        }
    }
}
