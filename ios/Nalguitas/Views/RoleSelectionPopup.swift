import SwiftUI
import UIKit

struct RoleSelectionPopup: View {
    let config: PopupConfig
    let onRoleSelected: (String) -> Void

    @State private var appeared: Bool = false
    @State private var selectedRole: String?
    @State private var isRegistering: Bool = false
    @State private var pulseAdmin: Bool = false
    @State private var pulseGirlfriend: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.4 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(appeared)

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    headerSection
                    optionsSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 36)
                .padding(.bottom, 40)
                .background {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay {
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.85),
                                            Theme.rosePale.opacity(0.6),
                                            Theme.warmWhite.opacity(0.7)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [Theme.roseLight.opacity(0.6), Theme.blush.opacity(0.2)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ),
                                    lineWidth: 1
                                )
                        }
                        .shadow(color: Theme.rosePrimary.opacity(0.15), radius: 40, y: 20)
                }
                .padding(.horizontal, 20)
                .offset(y: appeared ? 0 : 400)

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.25)) {
                appeared = true
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.roseLight.opacity(0.4))
                    .frame(width: 80, height: 80)
                    .blur(radius: 12)

                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.rosePrimary, Theme.blush],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.breathe, options: .repeating)
            }

            VStack(spacing: 8) {
                Text(config.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)

                Text(config.subtitle)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
    }

    private var optionsSection: some View {
        VStack(spacing: 14) {
            ForEach(config.options) { option in
                roleButton(option: option)
            }
        }
    }

    private func roleButton(option: PopupOption) -> some View {
        let isAdmin = option.role == "admin"
        let isSelected = selectedRole == option.role

        return Button {
            guard !isRegistering else { return }
            withAnimation(.spring(duration: 0.3, bounce: 0.4)) {
                selectedRole = option.role
            }

            Task {
                isRegistering = true
                let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
                try? await APIService.shared.registerRole(deviceId: deviceId, role: option.role)

                try? await Task.sleep(for: .milliseconds(600))

                withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                    onRoleSelected(option.role)
                }
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            isAdmin
                            ? LinearGradient(colors: [Color.orange.opacity(0.15), Color.yellow.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Theme.roseLight.opacity(0.5), Theme.rosePale.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .frame(width: 52, height: 52)

                    Text(option.emoji)
                        .font(.system(size: 26))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.label)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)

                    Text(isAdmin ? "Panel de control completo" : "Recibe mensajes de amor")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                if isSelected && isRegistering {
                    ProgressView()
                        .tint(Theme.rosePrimary)
                } else {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(isSelected ? Theme.rosePrimary : Theme.textSecondary.opacity(0.4))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isSelected ? Theme.roseLight.opacity(0.4) : Color.white.opacity(0.7))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(
                                isSelected ? Theme.rosePrimary.opacity(0.4) : Theme.roseLight.opacity(0.5),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    }
                    .shadow(color: isSelected ? Theme.rosePrimary.opacity(0.1) : .clear, radius: 8, y: 4)
            }
        }
        .sensoryFeedback(.impact(flexibility: .soft), trigger: selectedRole)
    }
}
