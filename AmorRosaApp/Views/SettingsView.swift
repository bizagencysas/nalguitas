import SwiftUI

struct SettingsView: View {
    let notificationService: NotificationService
    let viewModel: AppViewModel
    @State private var showWidgetInstructions = false
    @State private var secretTapCount: Int = 0
    @State private var showAdminLogin: Bool = false
    @State private var showAdmin: Bool = false
    @State private var adminUser: String = ""
    @State private var adminPass: String = ""
    @State private var loginError: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground

                ScrollView {
                    VStack(spacing: 24) {
                        notificationsSection
                        widgetSection
                        aboutSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showWidgetInstructions) {
                WidgetInstructionsSheet()
            }
            .alert("Acceso Admin", isPresented: $showAdminLogin) {
                TextField("Usuario", text: $adminUser)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Contraseña", text: $adminPass)
                Button("Entrar") {
                    if adminUser == "admin" && adminPass == "admin" {
                        loginError = false
                        showAdmin = true
                    } else {
                        loginError = true
                    }
                    adminUser = ""
                    adminPass = ""
                }
                Button("Cancelar", role: .cancel) {
                    adminUser = ""
                    adminPass = ""
                    secretTapCount = 0
                }
            } message: {
                Text(loginError ? "Credenciales incorrectas" : "Ingresa tus credenciales")
            }
            .fullScreenCover(isPresented: $showAdmin) {
                AdminView()
            }
        }
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "bell.fill", title: "Notificaciones")

            VStack(spacing: 12) {
                settingsRow(
                    icon: "bell.badge",
                    title: "Estado",
                    trailing: {
                        AnyView(
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(notificationService.isAuthorized ? Color.green : Theme.textSecondary.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                Text(notificationService.isAuthorized ? "Activas" : "Inactivas")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        )
                    }
                )

                if !notificationService.isAuthorized {
                    Button {
                        Task { await notificationService.requestPermission() }
                    } label: {
                        HStack {
                            Image(systemName: "bell.and.waves.left.and.right")
                            Text("Activar notificaciones")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            Capsule().fill(Theme.accentGradient)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                Divider().overlay(Theme.roseLight.opacity(0.5))

                scheduleRow(time: "8:00 AM", label: "Buenos días")
                scheduleRow(time: "12:30 PM", label: "Mediodía")
                scheduleRow(time: "5:00 PM", label: "Tarde")
                scheduleRow(time: "9:30 PM", label: "Buenas noches")

                Divider().overlay(Theme.roseLight.opacity(0.5))

                Button {
                    Task { await viewModel.testNotification() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane")
                        Text("Probar notificación")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                    }
                    .foregroundStyle(Theme.rosePrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.75))
                    .shadow(color: Theme.rosePrimary.opacity(0.06), radius: 10, y: 4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.roseLight.opacity(0.4), lineWidth: 0.5)
                    }
            }
        }
    }

    private func scheduleRow(time: String, label: String) -> some View {
        HStack {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundStyle(Theme.blush)

            Text(label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Text(time)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.vertical, 2)
    }

    private var widgetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "square.grid.2x2.fill", title: "Widget")

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Theme.cardGradient)
                        .frame(width: 60, height: 60)
                        .overlay {
                            Image(systemName: "heart.text.square.fill")
                                .font(.title2)
                                .foregroundStyle(Theme.rosePrimary)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Widget de Nalguitas")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)

                        Text("Mensajes bonitos en tu pantalla de inicio")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Button {
                    showWidgetInstructions = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle")
                        Text("Cómo activar el widget")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                    }
                    .foregroundStyle(Theme.rosePrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background {
                        Capsule()
                            .stroke(Theme.rosePrimary.opacity(0.3), lineWidth: 1)
                    }
                }
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.75))
                    .shadow(color: Theme.rosePrimary.opacity(0.06), radius: 10, y: 4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.roseLight.opacity(0.4), lineWidth: 0.5)
                    }
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "sparkles", title: "Acerca de")

            VStack(spacing: 8) {
                Text("Hecho con amor, solo para ti")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)

                Text("v1.0.0")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white.opacity(0.75))
                    .shadow(color: Theme.rosePrimary.opacity(0.06), radius: 10, y: 4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Theme.roseLight.opacity(0.4), lineWidth: 0.5)
                    }
            }
            .onTapGesture {
                secretTapCount += 1
                if secretTapCount >= 5 {
                    secretTapCount = 0
                    loginError = false
                    showAdminLogin = true
                }
            }
        }
    }

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Theme.rosePrimary)
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private func settingsRow<T: View>(icon: String, title: String, @ViewBuilder trailing: () -> T) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(Theme.blush)
                .frame(width: 24)
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            trailing()
        }
    }
}

struct WidgetInstructionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground

                ScrollView {
                    VStack(spacing: 32) {
                        instructionStep(
                            number: 1,
                            icon: "hand.tap.fill",
                            title: "Mantén presionado",
                            description: "Toca y mantén presionada cualquier área vacía de tu pantalla de inicio"
                        )

                        instructionStep(
                            number: 2,
                            icon: "plus.circle.fill",
                            title: "Toca el botón +",
                            description: "Busca \"Nalguitas\" en la lista de widgets disponibles"
                        )

                        instructionStep(
                            number: 3,
                            icon: "heart.fill",
                            title: "Elige tu favorito",
                            description: "Selecciona el tamaño que más te guste y toca \"Agregar widget\""
                        )

                        Text("¡Listo! Ahora tendrás mensajes de amor en tu pantalla")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                    .padding(24)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Activar Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(Theme.rosePrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationContentInteraction(.scrolls)
    }

    private func instructionStep(number: Int, icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Theme.accentGradient)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Paso \(number): \(title)")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)

                Text(description)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.75))
                .shadow(color: Theme.rosePrimary.opacity(0.06), radius: 8, y: 3)
        }
    }
}
