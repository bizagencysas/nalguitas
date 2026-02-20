import SwiftUI

struct ContentView: View {
    @State private var viewModel = AppViewModel()
    @State private var notificationService = NotificationService()
    @State private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                TabView(selection: $selectedTab) {
                    Tab("Hoy", systemImage: "heart.fill", value: 0) {
                        TodayView(viewModel: viewModel)
                    }

                    Tab("Guardados", systemImage: "bookmark.fill", value: 1) {
                        SavedView()
                    }

                    Tab("Historial", systemImage: "clock.arrow.circlepath", value: 2) {
                        HistoryView()
                    }

                    Tab("Ajustes", systemImage: "gearshape.fill", value: 3) {
                        SettingsView(notificationService: notificationService, viewModel: viewModel)
                    }
                }
                .tint(Theme.rosePrimary)
                .task {
                    await notificationService.checkStatus()
                }
            } else {
                WelcomeView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
        .preferredColorScheme(.light)
    }
}
