import SwiftUI

struct AdminRootView: View {
    let viewModel: AppViewModel
    let notificationService: NotificationService
    @State private var selectedTab = 2
    @State private var unreadChatCount = 0
    @State private var badgeTimer: Timer?

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
            .badge(unreadChatCount)

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
        .onChange(of: selectedTab) { _, newTab in
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            if newTab == 2 { unreadChatCount = 0 }
        }
        .task {
            await notificationService.requestPermission()
            await refreshBadge()
        }
        .onAppear { startBadgePolling() }
        .onDisappear { badgeTimer?.invalidate() }
        .onReceive(NotificationCenter.default.publisher(for: .switchToChatTab)) { _ in
            selectedTab = 2
        }
    }
    
    private func startBadgePolling() {
        badgeTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task { @MainActor in await refreshBadge() }
        }
    }
    
    private func refreshBadge() async {
        guard selectedTab != 2 else { unreadChatCount = 0; return }
        unreadChatCount = (try? await APIService.shared.fetchUnseenCount(sender: "admin")) ?? 0
    }
}
