import SwiftUI
import UIKit

struct ContentView: View {
    @State private var viewModel = AppViewModel()
    @State private var notificationService = NotificationService()
    @State private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isAdminDevice") private var isAdminDevice = false
    @AppStorage("hasSelectedRole") private var hasSelectedRole = false
    @State private var remoteConfig: RemoteConfig?
    @State private var showRolePopup = false
    @State private var isCheckingRole = true

    var body: some View {
        ZStack {
            Group {
                if isCheckingRole {
                    launchScreen
                } else if !hasSelectedRole {
                    WelcomeView(hasCompletedOnboarding: $hasCompletedOnboarding)
                } else if isAdminDevice {
                    AdminRootView(viewModel: viewModel, notificationService: notificationService)
                } else if !hasCompletedOnboarding {
                    WelcomeView(hasCompletedOnboarding: $hasCompletedOnboarding)
                } else {
                    GirlfriendTabView(viewModel: viewModel, notificationService: notificationService, selectedTab: $selectedTab)
                }
            }

            if showRolePopup, let popup = remoteConfig?.popup, popup.enabled {
                RoleSelectionPopup(config: popup) { role in
                    handleRoleSelection(role)
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
        .task {
            await checkRoleAndConfig()
        }
    }

    private var launchScreen: some View {
        ZStack {
            Theme.meshBackground
            VStack(spacing: 16) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.rosePrimary)
                    .symbolEffect(.breathe, options: .repeating)
                ProgressView()
                    .tint(Theme.rosePrimary)
            }
        }
    }

    private func checkRoleAndConfig() async {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

        if hasSelectedRole {
            isCheckingRole = false
            return
        }

        do {
            if let serverRole = try await APIService.shared.fetchRole(deviceId: deviceId), !serverRole.isEmpty {
                applyRole(serverRole)
                isCheckingRole = false
                return
            }
        } catch {}

        do {
            let config = try await APIService.shared.fetchRemoteConfig()
            remoteConfig = config
            if let popup = config.popup, popup.enabled, popup.type == "role_selection" {
                isCheckingRole = false
                withAnimation(.spring(duration: 0.5)) {
                    showRolePopup = true
                }
                return
            }
        } catch {}

        isCheckingRole = false
    }

    private func handleRoleSelection(_ role: String) {
        applyRole(role)
        withAnimation(.spring(duration: 0.5)) {
            showRolePopup = false
        }
    }

    private func applyRole(_ role: String) {
        hasSelectedRole = true
        if role == "admin" {
            isAdminDevice = true
            hasCompletedOnboarding = true
        } else {
            isAdminDevice = false
        }
        reRegisterDeviceWithRole()
    }

    private func reRegisterDeviceWithRole() {
        Task {
            await notificationService.requestPermission()
        }
    }
}

struct GirlfriendTabView: View {
    let viewModel: AppViewModel
    let notificationService: NotificationService
    @Binding var selectedTab: Int
    @State private var unreadChatCount = 0
    @State private var badgeTimer: Timer?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Hoy", systemImage: "heart.fill", value: 0) {
                TodayView(viewModel: viewModel)
            }

            Tab("Explorar", systemImage: "sparkles", value: 1) {
                ExploreView(isAdmin: false)
            }

            Tab("Chat", systemImage: "bubble.left.and.bubble.right.fill", value: 2) {
                ChatView(isAdmin: false)
            }
            .badge(unreadChatCount)

            Tab("Guardados", systemImage: "bookmark.fill", value: 3) {
                SavedView()
            }

            Tab("Historial", systemImage: "clock.arrow.circlepath", value: 4) {
                HistoryView()
            }

            Tab("Ajustes", systemImage: "gearshape.fill", value: 5) {
                SettingsView(notificationService: notificationService, viewModel: viewModel)
            }
        }
        .tint(Theme.rosePrimary)
        .onChange(of: selectedTab) { _, newTab in
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
        unreadChatCount = (try? await APIService.shared.fetchUnseenCount(sender: "girlfriend")) ?? 0
    }
}
