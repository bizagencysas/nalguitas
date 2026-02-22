import SwiftUI
import PhotosUI

struct ChatView: View {
    let isAdmin: Bool
    @State private var messages: [ChatMessage] = []
    @State private var messageText = ""
    @State private var isSending = false
    @State private var showPhotosPicker = false
    @State private var showStickerPicker = false
    @State private var showAIGenerator = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var aiPrompt = ""
    @State private var isGeneratingSticker = false
    @State private var cachedStickers: [AISticker] = []
    @State private var scrollProxy: ScrollViewProxy?
    @State private var pollTimer: Timer?
    
    // BBM-style profiles
    @State private var myProfile: UserProfile?
    @State private var partnerProfile: UserProfile?
    @State private var showProfileSheet = false
    @State private var editDisplayName = ""
    @State private var editStatus = ""
    @State private var editAvatarItem: PhotosPickerItem?
    @State private var editAvatarData: Data?
    
    private var mySender: String { isAdmin ? "admin" : "girlfriend" }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Chat background
                LinearGradient(
                    colors: [Color(red: 0.97, green: 0.95, blue: 0.98), Color(red: 0.95, green: 0.93, blue: 0.97)],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach(messages) { msg in
                                    messageBubble(msg)
                                        .id(msg.id)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onAppear { scrollProxy = proxy }
                        .onChange(of: messages.count) { _, _ in
                            scrollToBottom(proxy)
                        }
                    }
                    
                    // Input bar
                    chatInputBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button { showProfileSheet = true } label: {
                        chatHeaderView
                    }
                }
            }
            .sheet(isPresented: $showStickerPicker) { stickerPickerSheet }
            .sheet(isPresented: $showAIGenerator) { aiGeneratorSheet }
            .sheet(isPresented: $showProfileSheet) { profileEditSheet }
            .task { await loadProfiles(); await loadMessages(); startPolling() }
            .onDisappear { pollTimer?.invalidate() }
        }
    }
    
    // MARK: - BBM Chat Header
    private var chatHeaderView: some View {
        HStack(spacing: 10) {
            // Partner avatar
            if let partnerAvatar = partnerProfile?.avatar, !partnerAvatar.isEmpty,
               let imgData = Data(base64Encoded: partnerAvatar),
               let uiImage = UIImage(data: imgData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.rosePrimary.opacity(0.3), lineWidth: 1.5))
            } else {
                Circle()
                    .fill(LinearGradient(colors: [Theme.rosePrimary.opacity(0.3), Theme.rosePrimary.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(isAdmin ? "\u{1F469}" : "\u{1F468}")
                            .font(.system(size: 18))
                    )
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(partnerProfile?.displayName.isEmpty == false ? partnerProfile!.displayName : (isAdmin ? "Tucancita" : "Isacc"))
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                if let status = partnerProfile?.statusMessage, !status.isEmpty {
                    Text(status)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text("\u{1F49D}")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
            Spacer()
        }
    }
    
    // MARK: - Message Bubble
    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isMe = msg.sender == mySender
        
        return HStack(alignment: .bottom, spacing: 6) {
            if isMe { Spacer(minLength: 50) }
            
            // Partner avatar (left side)
            if !isMe {
                avatarCircle(for: partnerProfile, fallback: isAdmin ? "\u{1F469}" : "\u{1F468}")
            }
            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                // Content based on type
                switch msg.type {
                case "image":
                    if let data = msg.mediaData, let imgData = Data(base64Encoded: data), let uiImage = UIImage(data: imgData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: 220, maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Label("Foto", systemImage: "photo.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                case "sticker":
                    if let data = msg.mediaData, let imgData = Data(base64Encoded: data), let uiImage = UIImage(data: imgData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 140, height: 140)
                    }
                    
                case "link":
                    VStack(alignment: .leading, spacing: 4) {
                        if !msg.content.isEmpty {
                            Text(msg.content)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(isMe ? .white : Color(red: 0.2, green: 0.15, blue: 0.18))
                        }
                        if let url = msg.mediaUrl {
                            Link(destination: URL(string: url)!) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                    Text(url.prefix(40) + (url.count > 40 ? "..." : ""))
                                        .lineLimit(1)
                                }
                                .font(.caption)
                                .foregroundStyle(isMe ? .white.opacity(0.8) : Theme.rosePrimary)
                            }
                        }
                    }
                    
                default: // text
                    // Auto-detect links in text
                    if msg.content.contains("http") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(msg.content)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(isMe ? .white : Color(red: 0.2, green: 0.15, blue: 0.18))
                            if let linkRange = msg.content.range(of: "http[^ ]+", options: .regularExpression),
                               let url = URL(string: String(msg.content[linkRange])) {
                                Link(destination: url) {
                                    Text("Abrir enlace →")
                                        .font(.caption)
                                        .foregroundStyle(isMe ? .white.opacity(0.8) : Theme.rosePrimary)
                                }
                            }
                        }
                    } else {
                        Text(msg.content)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(isMe ? .white : Color(red: 0.2, green: 0.15, blue: 0.18))
                    }
                }
                
                // Timestamp + seen
                HStack(spacing: 4) {
                    Text(formatTime(msg.createdAt))
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(isMe ? .white.opacity(0.6) : .secondary)
                    if isMe {
                        Image(systemName: msg.seen == true ? "checkmark.circle.fill" : "checkmark.circle")
                            .font(.system(size: 10))
                            .foregroundStyle(isMe ? .white.opacity(0.6) : .secondary)
                    }
                }
            }
            .padding(.horizontal, msg.type == "sticker" ? 4 : 14)
            .padding(.vertical, msg.type == "sticker" ? 4 : 10)
            .background {
                if msg.type != "sticker" {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isMe
                              ? LinearGradient(colors: [Theme.rosePrimary, Theme.roseQuartz], startPoint: .topLeading, endPoint: .bottomTrailing)
                              : LinearGradient(colors: [Color.white, Color.white.opacity(0.9)], startPoint: .top, endPoint: .bottom))
                        .shadow(color: (isMe ? Theme.rosePrimary : Color.black).opacity(0.08), radius: 4, y: 2)
                }
            }
            
            if !isMe { Spacer(minLength: 50) }
        }
    }
    
    // MARK: - Input Bar
    private var chatInputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 8) {
                // Attachments button
                Menu {
                    Button { showPhotosPicker = true } label: { Label("Foto", systemImage: "photo.fill") }
                    Button { showStickerPicker = true } label: { Label("Sticker", systemImage: "face.smiling.inverse") }
                    Button { showAIGenerator = true } label: { Label("Sticker IA ✨", systemImage: "wand.and.stars") }
                    Button { pasteLink() } label: { Label("Pegar Link", systemImage: "link") }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Theme.rosePrimary)
                }
                
                // Photo picker (hidden)
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    EmptyView()
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            let uiImage = UIImage(data: data)
                            if let compressed = uiImage?.jpegData(compressionQuality: 0.4) {
                                await sendMedia(type: "image", base64: compressed.base64EncodedString())
                            }
                        }
                    }
                }
                .frame(width: 0, height: 0).opacity(0)
                
                // Text field
                HStack {
                    TextField("Escribe un mensaje...", text: $messageText, axis: .vertical)
                        .lineLimit(1...4)
                        .font(.system(.body, design: .rounded))
                    
                    if !messageText.isEmpty {
                        Button { Task { await sendText() } } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Theme.rosePrimary)
                        }
                        .disabled(isSending)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white).shadow(color: .black.opacity(0.05), radius: 4, y: 1))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Sticker Picker
    private var stickerPickerSheet: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Stickers de la App").font(.system(.headline, design: .rounded, weight: .bold)).foregroundStyle(Theme.rosePrimary)
                        
                        let emojis = ["🐹", "🐰", "🐻", "🐱", "🐶", "🐧", "🦄", "🦊", "🐥", "🐼", "🐨", "🦥", "🦉", "🐹", "🦌", "🦝", "🐘", "🐢", "🦁", "🐯", "🐷", "🐸", "🦖", "🐙"]
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 10) {
                            ForEach(emojis, id: \.self) { emoji in
                                Button {
                                    Task { await sendEmoji(emoji) }
                                } label: {
                                    Text(emoji)
                                        .font(.system(size: 40))
                                        .frame(width: 65, height: 65)
                                        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                                }
                            }
                        }
                        
                        if !cachedStickers.isEmpty {
                            Divider().padding(.vertical, 8)
                            Text("Stickers IA Generados").font(.system(.headline, design: .rounded, weight: .bold)).foregroundStyle(.purple)
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                                ForEach(cachedStickers) { sticker in
                                    Button {
                                        Task { await sendMedia(type: "sticker", base64: sticker.imageData) }
                                        showStickerPicker = false
                                    } label: {
                                        if let data = Data(base64Encoded: sticker.imageData), let img = UIImage(data: data) {
                                            Image(uiImage: img)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(width: 75, height: 75)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                }
                            }
                        }
                    }.padding(20)
                }
            }
            .navigationTitle("Stickers 🎨")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { showStickerPicker = false } } }
            .task { cachedStickers = (try? await APIService.shared.fetchAIStickers()) ?? [] }
        }
    }
    
    // MARK: - AI Sticker Generator
    private var aiGeneratorSheet: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 50))
                        .foregroundStyle(LinearGradient(colors: [.purple, Theme.rosePrimary], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    Text("Generador de Stickers IA")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(Theme.rosePrimary)
                    
                    Text("Describe el sticker que quieres crear, ¡será único!")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    TextField("Ej: osito abrazando un corazón gigante", text: $aiPrompt, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial))
                    
                    Button {
                        Task { await generateSticker() }
                    } label: {
                        HStack {
                            if isGeneratingSticker {
                                ProgressView().tint(.white)
                                Text("Creando magia...").foregroundStyle(.white)
                            } else {
                                Image(systemName: "sparkles")
                                Text("Generar Sticker ✨")
                            }
                        }
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 16).fill(
                            LinearGradient(colors: [.purple, Theme.rosePrimary], startPoint: .leading, endPoint: .trailing)
                        ))
                    }
                    .disabled(aiPrompt.isEmpty || isGeneratingSticker)
                    
                    Spacer()
                    Spacer()
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { showAIGenerator = false } } }
        }
    }
    
    // MARK: - Actions
    private func loadMessages() async {
        do {
            messages = try await APIService.shared.fetchChatMessages()
            try? await APIService.shared.markChatSeen(sender: mySender)
        } catch {}
    }
    
    private func sendText() async {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let text = messageText; messageText = ""
        isSending = true; defer { isSending = false }
        
        // Auto-detect if it's a link
        let type = text.contains("http://") || text.contains("https://") ? "link" : "text"
        let mediaUrl = type == "link" ? text : nil
        
        do {
            let msg = try await APIService.shared.sendChatMessage(sender: mySender, type: type, content: text, mediaUrl: mediaUrl)
            messages.append(msg)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } catch { messageText = text }
    }
    
    private func sendMedia(type: String, base64: String) async {
        do {
            let msg = try await APIService.shared.sendChatMessage(sender: mySender, type: type, content: type == "sticker" ? "🎨" : "📷", mediaData: base64)
            messages.append(msg)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } catch {}
    }
    
    private func sendEmoji(_ emoji: String) async {
        do {
            let msg = try await APIService.shared.sendChatMessage(sender: mySender, type: "text", content: emoji)
            messages.append(msg)
            showStickerPicker = false
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } catch {}
    }
    
    private func pasteLink() {
        if let clipText = UIPasteboard.general.string, clipText.contains("http") {
            messageText = clipText
        }
    }
    
    private func generateSticker() async {
        isGeneratingSticker = true; defer { isGeneratingSticker = false }
        do {
            let sticker = try await APIService.shared.generateAISticker(prompt: aiPrompt)
            await sendMedia(type: "sticker", base64: sticker.imageData)
            aiPrompt = ""
            showAIGenerator = false
        } catch {}
    }
    
    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                await pollNewMessages()
            }
        }
        // Also listen for push notifications for instant delivery
        NotificationCenter.default.addObserver(forName: .didReceiveRemoteMessage, object: nil, queue: .main) { _ in
            Task { @MainActor in
                await pollNewMessages()
            }
        }
    }
    
    private func pollNewMessages() async {
        guard let newMsgs = try? await APIService.shared.fetchChatMessages() else { return }
        if newMsgs.count > messages.count {
            let oldCount = messages.count
            messages = newMsgs
            try? await APIService.shared.markChatSeen(sender: mySender)
            if newMsgs.count > oldCount {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        }
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let last = messages.last {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
    
    private func formatTime(_ dateStr: String?) -> String {
        guard let str = dateStr else { return "" }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: str) ?? ISO8601DateFormatter().date(from: str) else { return "" }
        let df = DateFormatter(); df.dateFormat = "h:mm a"
        return df.string(from: date)
    }
    
    // MARK: - Avatar Circle
    private func avatarCircle(for profile: UserProfile?, fallback: String) -> some View {
        Group {
            if let av = profile?.avatar, !av.isEmpty,
               let imgData = Data(base64Encoded: av),
               let uiImage = UIImage(data: imgData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 24, height: 24)
                    .clipShape(Circle())
            } else {
                Text(fallback)
                    .font(.system(size: 12))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.gray.opacity(0.1)))
            }
        }
    }
    
    // MARK: - Load Profiles
    private func loadProfiles() async {
        myProfile = try? await APIService.shared.fetchProfile(username: mySender)
        let partner = isAdmin ? "girlfriend" : "admin"
        partnerProfile = try? await APIService.shared.fetchProfile(username: partner)
    }
    
    // MARK: - Profile Edit Sheet
    private var profileEditSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current avatar
                    VStack(spacing: 12) {
                        if let data = editAvatarData ?? (myProfile?.avatar.isEmpty == false ? Data(base64Encoded: myProfile!.avatar) : nil),
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Theme.rosePrimary, lineWidth: 2))
                        } else {
                            Circle()
                                .fill(LinearGradient(colors: [Theme.rosePrimary.opacity(0.3), Theme.rosePrimary.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                                .frame(width: 100, height: 100)
                                .overlay(Text(isAdmin ? "\u{1F468}" : "\u{1F469}").font(.system(size: 44)))
                        }
                        PhotosPicker(selection: $editAvatarItem, matching: .images) {
                            Label("Cambiar foto", systemImage: "camera.fill")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundStyle(Theme.rosePrimary)
                        }
                        .onChange(of: editAvatarItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    // Compress to JPEG
                                    if let uiImage = UIImage(data: data),
                                       let jpeg = uiImage.jpegData(compressionQuality: 0.3) {
                                        editAvatarData = jpeg
                                    }
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nombre").font(.system(.caption, design: .rounded, weight: .bold)).foregroundStyle(.secondary)
                        TextField("Tu nombre...", text: $editDisplayName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Estado (como en BBM \u{1F609})").font(.system(.caption, design: .rounded, weight: .bold)).foregroundStyle(.secondary)
                        TextField("Ej: Pensando en ti...", text: $editStatus)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Button {
                        Task {
                            let avatarStr: String
                            if let data = editAvatarData {
                                avatarStr = data.base64EncodedString()
                            } else {
                                avatarStr = myProfile?.avatar ?? ""
                            }
                            try? await APIService.shared.updateProfile(
                                username: mySender,
                                displayName: editDisplayName,
                                avatar: avatarStr,
                                statusMessage: editStatus
                            )
                            await loadProfiles()
                            showProfileSheet = false
                        }
                    } label: {
                        Text("Guardar")
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Capsule().fill(Theme.rosePrimary))
                    }
                }.padding(24)
            }
            .navigationTitle("Mi Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { showProfileSheet = false } }
            }
            .onAppear {
                editDisplayName = myProfile?.displayName ?? (isAdmin ? "Isacc" : "Tucancita")
                editStatus = myProfile?.statusMessage ?? ""
            }
        }
    }
}

