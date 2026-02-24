import SwiftUI
import Combine

struct AdminView: View {
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
    @State private var girlfriendMessages: [GirlfriendMessage] = []
    
    // Gift states
    @State private var selectedCharacter: GiftCharacter = GiftCharacter.characters[0]
    @State private var giftMessage: String = ""
    @State private var giftSubtitle: String = "Para ti"
    @State private var sendingGift: Bool = false
    
    // Facts management
    @State private var customFacts: [CustomFact] = []
    @State private var newFactText: String = ""
    @State private var isCreatingFact: Bool = false
    
    // Scratch card admin
    @State private var scratchPrize: String = ""
    @State private var scratchEmoji: String = "🎁"
    
    // Reward admin
    @State private var rewardTitle: String = ""
    @State private var rewardEmoji: String = "🎁"
    @State private var rewardCost: String = "10"
    
    // Experience admin
    @State private var expTitle: String = ""
    @State private var expDescription: String = ""
    @State private var expEmoji: String = "✨"

    private let tones = ["tierno", "romántico", "profundo", "divertido"]

    var body: some View {
        NavigationStack {
            Form {
                girlfriendMessagesCard
                sendNowCard
                createMessageCard
                messagesListCard
                
                Section(header: Text("Gestión Interactiva")) {
                    NavigationLink(destination: Text("Regalos")) { EmptyView() }.hidden().frame(height: 0) // Enforce inset style spacing hack if needed, but not needed
                }
                .listRowBackground(Color.clear)
                .frame(height: 0)
                
                giftSendCard
                scratchCardAdminCard
                rewardAdminCard
                experienceAdminCard
                factsManagerCard
            }
            .navigationTitle("Admin")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
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
            await loadGirlfriendMessages()
            customFacts = (try? await APIService.shared.fetchAllFacts()) ?? []
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task {
                await loadMessages()
                await loadGirlfriendMessages()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didReceiveRemoteMessage)) { _ in
            Task {
                await loadMessages()
                await loadGirlfriendMessages()
            }
        }
        .onReceive(Timer.publish(every: 10, on: .main, in: .common).autoconnect()) { _ in
            Task {
                await loadGirlfriendMessages()
            }
        }
    }

    // MARK: - Mensajes Recibidos
    private var girlfriendMessagesCard: some View {
        Section {
            if girlfriendMessages.isEmpty {
                Text("Aún no tienes mensajes de ella 💕")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(girlfriendMessages) { msg in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(msg.content)
                            .font(.system(.body, design: .rounded))
                        Text(formatDate(msg.sentAt))
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        } header: {
            Label("Bandeja de Entrada", systemImage: "tray.fill")
        }
    }

    // MARK: - Enviar Notificación Rápida
    private var sendNowCard: some View {
        Section {
            TextField("Escribe un mensaje bonito...", text: $messageText, axis: .vertical)
                .lineLimit(3...6)
            
            Button {
                Task { await sendNotification() }
            } label: {
                HStack {
                    if sendingNotification {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "paperplane.fill")
                        Text("Enviar notificación instantánea")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.rosePrimary)
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sendingNotification)
        } header: {
            Label("Enviar Ahora", systemImage: "paperplane.fill")
        }
    }

    // MARK: - Crear Mensaje de Cariño
    private var createMessageCard: some View {
        Section {
            TextField("El mensaje que ella verá...", text: $newContent, axis: .vertical)
                .lineLimit(2...5)
            
            HStack {
                Text("Subtítulo")
                Spacer()
                TextField("E.g. Para ti", text: $newSubtitle)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }
            
            Picker("Tono", selection: $selectedTone) {
                ForEach(tones, id: \.self) { tone in
                    Text(tone.capitalized).tag(tone)
                }
            }
            
            Button {
                Task { await createMessage() }
            } label: {
                HStack(spacing: 8) {
                    if creatingMessage {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "heart.fill")
                        Text("Guardar para después")
                    }
                }
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.rosePrimary)
            .disabled(newContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || creatingMessage)
        } header: {
            Label("Crear Mensaje Programado", systemImage: "plus.message.fill")
        }
    }

    // MARK: - Mensajes Programados / Guardados
    private var messagesListCard: some View {
        Section {
            if isLoading {
                ProgressView().frame(maxWidth: .infinity, alignment: .center)
            } else if messages.isEmpty {
                Text("No hay mensajes guardados")
                    .foregroundColor(.secondary)
            } else {
                ForEach(messages) { msg in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(msg.content)
                            .font(.subheadline)
                        HStack {
                            Text(msg.subtitle ?? "")
                            Spacer()
                            Text((msg.tone ?? "").capitalized)
                        }
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await deleteMessage(id: msg.id) }
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                    }
                }
            }
        } header: {
            Label("Mensajes Guardados (\(messages.count))", systemImage: "list.bullet")
        }
    }

    // MARK: - Enviar Sorpresa (Regalo Animado)
    private var giftSendCard: some View {
        Section {
            Picker("Personaje 3D", selection: $selectedCharacter) {
                ForEach(GiftCharacter.characters) { char in
                    Text(char.name).tag(char)
                }
            }
            
            HStack {
                Text("Subtítulo")
                Spacer()
                TextField("E.g. Para ti", text: $giftSubtitle)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }
            
            TextField("Escribe un mensajito que acompañe la sorpresa...", text: $giftMessage, axis: .vertical)
                .lineLimit(2...4)
            
            Button {
                Task { await sendGift() }
            } label: {
                HStack(spacing: 8) {
                    if sendingGift {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "gift.fill")
                        Text("Enviar Sorpresa Interactiva")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.blush)
            .foregroundStyle(.white)
            .disabled(giftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || sendingGift)
        } header: {
            Label("Control de Sorpresas & Regalos Animados", systemImage: "gift.fill")
        }
    }

    // MARK: - Scratch Card Admin
    private var scratchCardAdminCard: some View {
        Section {
            HStack {
                Text("Emoji")
                Spacer()
                TextField("🎁", text: $scratchEmoji)
                    .frame(width: 60).multilineTextAlignment(.trailing)
            }
            
            TextField("Premio (ej: Masajito de 10 min)", text: $scratchPrize)
            
            Button("Crear tarjeta Raspa y Gana") {
                guard !scratchPrize.isEmpty else { return }
                Task {
                    try? await APIService.shared.createScratchCard(prize: scratchPrize, emoji: scratchEmoji)
                    scratchPrize = ""
                    showTemporaryToast("Tarjeta creada 🎁")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.blush)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .trailing)
        } header: {
            Label("Crear Raspa y Gana", systemImage: "sparkles")
        }
    }

    // MARK: - Reward Admin
    private var rewardAdminCard: some View {
        Section {
            HStack {
                Text("Emoji")
                Spacer()
                TextField("⭐", text: $rewardEmoji)
                    .frame(width: 60).multilineTextAlignment(.trailing)
            }
            
            TextField("Título de Recompensa", text: $rewardTitle)
            
            HStack {
                Text("Costo (Puntos de novia)")
                Spacer()
                TextField("10", text: $rewardCost)
                    .keyboardType(.numberPad)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(.secondary)
            }
            
            Button("Agregar a la tienda de puntos") {
                guard !rewardTitle.isEmpty else { return }
                Task {
                    try? await APIService.shared.createReward(title: rewardTitle, emoji: rewardEmoji, cost: Int(rewardCost) ?? 10)
                    rewardTitle = ""
                    showTemporaryToast("Recompensa agregada a la tienda ⭐")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.blush)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .trailing)
        } header: {
            Label("Crear Recompensa Canjeable", systemImage: "star.fill")
        }
    }

    // MARK: - Experience Admin
    private var experienceAdminCard: some View {
        Section {
            HStack {
                Text("Emoji")
                Spacer()
                TextField("✨", text: $expEmoji)
                    .frame(width: 60).multilineTextAlignment(.trailing)
            }
            TextField("Título de la experiencia", text: $expTitle)
            TextField("Descripción (opcional)", text: $expDescription)
            
            Button("Publicar experiencia") {
                guard !expTitle.isEmpty else { return }
                Task {
                    try? await APIService.shared.createExperience(title: expTitle, description: expDescription, emoji: expEmoji)
                    expTitle = ""
                    expDescription = ""
                    showTemporaryToast("Experiencia publicada para agendar ✨")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.rosePrimary)
            .frame(maxWidth: .infinity, alignment: .trailing)
        } header: {
            Label("Agregar Experiencia (Cita)", systemImage: "calendar.badge.plus")
        }
    }

    // MARK: - Administrador de Datos Curiosos
    private var factsManagerCard: some View {
        Section {
            HStack {
                TextField("Escribe un nuevo dato curioso o recuerdo...", text: $newFactText)
                Button {
                    Task { await createFact() }
                } label: {
                    if isCreatingFact {
                        ProgressView()
                    } else {
                        Image(systemName: "plus.circle.fill")
                    }
                }
                .disabled(newFactText.trimmingCharacters(in: .whitespaces).isEmpty || isCreatingFact)
            }

            if !customFacts.isEmpty {
                ForEach(customFacts) { fact in
                    Text("💡 \(fact.fact)")
                        .font(.system(.subheadline, design: .rounded))
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await deleteFact(id: fact.id) }
                            } label: { Label("Eliminar", systemImage: "trash") }
                        }
                }
            }
        } header: {
            Label("Base de Datos Curiosos & Recuerdos", systemImage: "lightbulb.fill")
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
            showTemporaryToast("Notificación enviada 💕")
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
        if let msgs = try? await APIService.shared.fetchMessages() {
            messages = msgs
        }
        isLoading = false
    }

    private func loadGirlfriendMessages() async {
        if let msgs = try? await APIService.shared.fetchGirlfriendMessages() {
            girlfriendMessages = msgs
        }
    }
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
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
    


    
    private func createFact() async {
        let text = newFactText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        isCreatingFact = true
        defer { isCreatingFact = false }
        do {
            let fact = try await APIService.shared.createFact(fact: text)
            customFacts.insert(fact, at: 0)
            newFactText = ""
            showTemporaryToast("¡Dato curioso agregado! 💡")
        } catch {
            showTemporaryToast("Error: \(error.localizedDescription)")
        }
    }
    
    private func deleteFact(id: String) async {
        do {
            try await APIService.shared.deleteFact(id: id)
            customFacts.removeAll { $0.id == id }
            showTemporaryToast("Dato eliminado")
        } catch {
            showTemporaryToast("Error al eliminar")
        }
    }
    
    private func sendGift() async {
        let message = giftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        sendingGift = true
        defer { sendingGift = false }
        
        do {
            let characterUrl = GiftCharacter.imageURL(for: selectedCharacter.id)?.absoluteString ?? ""
            try await APIService.shared.createGift(
                characterUrl: characterUrl,
                characterName: selectedCharacter.id,
                message: message,
                subtitle: giftSubtitle.isEmpty ? "Para ti" : giftSubtitle,
                giftType: "surprise"
            )
            giftMessage = ""
            showTemporaryToast("¡Sorpresa enviada! 🎁💕")
        } catch {
            showTemporaryToast("Error: \(error.localizedDescription)")
        }
    }
    
}
