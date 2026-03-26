import SwiftUI
import UIKit
import LocalAuthentication

struct ContentView: View {
    @State private var viewModel = AppViewModel()
    @State private var notificationService = NotificationService()
    @State private var selectedTab = 2
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isAdminDevice") private var isAdminDevice = false
    @AppStorage("hasSelectedRole") private var hasSelectedRole = false
    @State private var remoteConfig: RemoteConfig?
    @State private var showRolePopup = false
    @State private var isCheckingRole = true
    
    // Biometrics Storage
    @AppStorage("isBiometricLockEnabled") private var isBiometricLockEnabled = false
    @State private var isUnlocked = true
    @State private var showingAuthError = false
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack {
            Group {
                if !isUnlocked && isBiometricLockEnabled {
                    biometricLockScreen
                } else if isCheckingRole {
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
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isCheckingRole)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isUnlocked)

            if showRolePopup, let popup = remoteConfig?.popup, popup.enabled {
                RoleSelectionPopup(config: popup) { role in
                    handleRoleSelection(role)
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.light)
        .onAppear { AppDelegate.appIsReady = true }
        .task {
            await checkRoleAndConfig()
            if !isBiometricLockEnabled {
                isUnlocked = true
            } else {
                authenticate()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                Task { try? await UNUserNotificationCenter.current().setBadgeCount(0) }
            }
            if newPhase == .background && isBiometricLockEnabled {
                isUnlocked = false
            } else if newPhase == .active && isBiometricLockEnabled && !isUnlocked {
                authenticate()
            }
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
    
    private var biometricLockScreen: some View {
        ZStack {
            Theme.meshBackground
            VStack(spacing: 24) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Theme.rosePrimary)
                    .symbolEffect(.pulse)
                
                Text("App Bloqueada")
                    .font(.system(.title, design: .rounded, weight: .bold))
                
                Text("Desbloquea Nalguitas para ver tus mensajes y planes privados.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button(action: authenticate) {
                    Text("Usar FaceID / TouchID")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Theme.rosePrimary))
                        .shadow(color: Theme.rosePrimary.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.top, 20)
                
                if showingAuthError {
                    Text("Error de autenticación. Intenta de nuevo.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
    }
    
    private func authenticate() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Desbloquea Nalguitas para acceder"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    if success {
                        withAnimation(.spring()) {
                            self.isUnlocked = true
                            self.showingAuthError = false
                        }
                    } else {
                        self.showingAuthError = true
                    }
                }
            }
        } else {
            // No biometrics or passcode set
            isUnlocked = true
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
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            if newTab == 2 { unreadChatCount = 0 }
        }
        .task {
            await notificationService.requestPermission()
            await refreshBadge()
        }
        .onAppear { 
            startBadgePolling() 
            checkDeepLink()
        }
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
        unreadChatCount = (try? await APIService.shared.fetchUnseenCount(sender: "girlfriend")) ?? 0
    }
    
    private func checkDeepLink() {
        if let link = UserDefaults.standard.string(forKey: "pendingDeepLink"), link == "chat" {
            selectedTab = 2
            UserDefaults.standard.removeObject(forKey: "pendingDeepLink")
        }
    }
}
