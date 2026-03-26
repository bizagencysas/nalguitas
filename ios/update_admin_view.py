import re

with open("Nalguitas/Views/AdminView.swift", "r") as f:
    original = f.read()

# I will replace the View properties, keeping state variables and logic functions intact.
# The split is at `var body: some View {` and the methods start around `private func toastBanner`.

head_split = original.split("var body: some View {", 1)
head = head_split[0]

tail_split = head_split[1].split("private func toastBanner", 1)
tail_methods = "    private func toastBanner" + tail_split[1]

# Now let's inject the new body and UI components natively
new_body = """var body: some View {
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
                        Text(formatDate(msg.createdAt))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
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
                .font(.system(.subheadline, weight: .semibold, design: .rounded))
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
                            Text(msg.subtitle)
                            Spacer()
                            Text(msg.tone.capitalized)
                            if msg.seen {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
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

"""

full_new_file = head + new_body + tail_methods

with open("Nalguitas/Views/AdminView.swift", "w") as f:
    f.write(full_new_file)

print("Updated AdminView successfully")
