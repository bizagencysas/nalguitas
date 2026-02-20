import SwiftUI

struct AdminView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var messageText: String = ""
    @State private var newContent: String = ""
    @State private var newSubtitle: String = "Para ti"
    @State private var selectedTone: String = "tierno"
    @State private var messages: [LoveMessage] = []
    @State private var isLoading: Bool = false
    @State private var toastMessage: String?
    @State private var showToast: Bool = false
    @State private var sendingNotification: Bool = false
    @State private var creatingMessage: Bool = false

    private let tones = ["tierno", "romántico", "profundo", "divertido"]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground

                ScrollView {
                    VStack(spacing: 20) {
                        sendNowCard
                        createMessageCard
                        messagesListCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Admin")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textSecondary.opacity(0.5))
                            .font(.title3)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await loadMessages() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Theme.rosePrimary)
                    }
                }
            }
            .overlay(alignment: .top) {
                if showToast, let msg = toastMessage {
                    toastBanner(msg)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .padding(.top, 8)
                }
            }
        }
        .task {
            await loadMessages()
        }
    }

    private var sendNowCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "paperplane.fill", title: "Enviar Ahora")

            VStack(spacing: 12) {
                TextField("Escribe un mensaje bonito...", text: $messageText, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white)
                            .stroke(Theme.roseLight, lineWidth: 1)
                    }

                Button {
                    Task { await sendNotification() }
                } label: {
                    HStack(spacing: 8) {
                        if sendingNotification {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "heart.fill")
                        }
                        Text("Enviar notificación")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        Capsule().fill(Theme.accentGradient)
                    }
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sendingNotification)
                .opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
            }
            .padding(16)
            .background { cardBackground }
        }
    }

    private var createMessageCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "plus.message.fill", title: "Crear Mensaje")

            VStack(spacing: 12) {
                TextField("El mensaje que ella verá...", text: $newContent, axis: .vertical)
                    .lineLimit(2...5)
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white)
                            .stroke(Theme.roseLight, lineWidth: 1)
                    }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Subtítulo")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)

                        TextField("Para ti", text: $newSubtitle)
                            .padding(10)
                            .background {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.white)
                                    .stroke(Theme.roseLight, lineWidth: 1)
                            }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tono")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)

                        Picker("Tono", selection: $selectedTone) {
                            ForEach(tones, id: \.self) { tone in
                                Text(tone.capitalized).tag(tone)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(Theme.rosePrimary)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.white)
                                .stroke(Theme.roseLight, lineWidth: 1)
                        }
                    }
                }

                Button {
                    Task { await createMessage() }
                } label: {
                    HStack(spacing: 8) {
                        if creatingMessage {
                            ProgressView().tint(.white)
                        } else {
                            Image(systemName: "plus")
                        }
                        Text("Agregar mensaje")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background {
                        Capsule().fill(Theme.accentGradient)
                    }
                }
                .disabled(newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || creatingMessage)
                .opacity(newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
            }
            .padding(16)
            .background { cardBackground }
        }
    }

    private var messagesListCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(icon: "list.bullet", title: "Mensajes (\(messages.count))")

            VStack(spacing: 0) {
                if isLoading && messages.isEmpty {
                    ProgressView()
                        .tint(Theme.rosePrimary)
                        .frame(maxWidth: .infinity)
                        .padding(32)
                } else if messages.isEmpty {
                    Text("No hay mensajes aún")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(32)
                } else {
                    ForEach(messages) { message in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(message.content)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(3)

                            HStack {
                                Text(message.displaySubtitle)
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(Theme.textSecondary)

                                if let tone = message.tone {
                                    Text("·")
                                        .foregroundStyle(Theme.textSecondary)
                                    Text(tone)
                                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                                        .foregroundStyle(Theme.blush)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background {
                                            Capsule().fill(Theme.rosePale)
                                        }
                                }

                                Spacer()

                                Button {
                                    Task { await deleteMessage(id: message.id) }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .foregroundStyle(.red.opacity(0.6))
                                }
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)

                        if message.id != messages.last?.id {
                            Divider().overlay(Theme.roseLight.opacity(0.5)).padding(.horizontal, 16)
                        }
                    }
                }
            }
            .background { cardBackground }
        }
    }

    private func toastBanner(_ message: String) -> some View {
        Text(message)
            .font(.system(.subheadline, design: .rounded, weight: .medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                Capsule().fill(Theme.accentGradient)
                    .shadow(color: Theme.rosePrimary.opacity(0.3), radius: 8, y: 4)
            }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.white.opacity(0.75))
            .shadow(color: Theme.rosePrimary.opacity(0.06), radius: 10, y: 4)
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Theme.roseLight.opacity(0.4), lineWidth: 0.5)
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

    private func showTemporaryToast(_ message: String) {
        toastMessage = message
        withAnimation(.spring(duration: 0.3)) { showToast = true }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeOut(duration: 0.3)) { showToast = false }
        }
    }

    private func sendNotification() async {
        sendingNotification = true
        defer { sendingNotification = false }
        do {
            try await APIService.shared.sendNotification(message: messageText.trimmingCharacters(in: .whitespacesAndNewlines))
            messageText = ""
            showTemporaryToast("Mensaje enviado 💕")
        } catch {
            showTemporaryToast("Error: \(error.localizedDescription)")
        }
    }

    private func createMessage() async {
        creatingMessage = true
        defer { creatingMessage = false }
        let content = newContent.trimmingCharacters(in: .whitespacesAndNewlines)
        let sub = newSubtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try await APIService.shared.createMessage(content: content, subtitle: sub.isEmpty ? "Para ti" : sub, tone: selectedTone)
            newContent = ""
            showTemporaryToast("Mensaje creado ✨")
            await loadMessages()
        } catch {
            showTemporaryToast("Error: \(error.localizedDescription)")
        }
    }

    private func loadMessages() async {
        isLoading = true
        defer { isLoading = false }
        do {
            messages = try await APIService.shared.fetchMessages()
        } catch {}
    }

    private func deleteMessage(id: String) async {
        do {
            try await APIService.shared.deleteMessage(id: id)
            showTemporaryToast("Mensaje eliminado")
            await loadMessages()
        } catch {
            showTemporaryToast("Error al eliminar")
        }
    }
}
