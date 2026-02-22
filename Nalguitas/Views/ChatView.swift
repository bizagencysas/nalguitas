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
    
    // iMessage colors
    private let sentGradient = LinearGradient(
        colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.0, green: 0.4, blue: 0.9)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    private let receivedColor = Color(UIColor.systemGray5)
    
    var body: some View {
        NavigationStack {
            ZStack {
                // iOS-style subtle background
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Messages area
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 2) {
                                ForEach(Array(messages.enumerated()), id: \.element.id) { index, msg in
                                    iMessageBubble(msg, index: index)
                                        .id(msg.id)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onAppear { scrollProxy = proxy }
                        .onChange(of: messages.count) { _, _ in
                            scrollToBottom(proxy)
                        }
                    }
                    
                    // iMessage-style input bar
                    iMessageInputBar
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    // iMessage-style centered header
                    Button { showProfileSheet = true } label: {
                        iMessageHeader
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showStickerPicker) { stickerPickerSheet }
            .sheet(isPresented: $showAIGenerator) { aiGeneratorSheet }
            .sheet(isPresented: $showProfileSheet) { profileEditSheet }
            .task { await loadProfiles(); await loadMessages(); startPolling() }
            .onDisappear { pollTimer?.invalidate() }
        }
    }
    
    // MARK: - iMessage Header (centered avatar + name)
    private var iMessageHeader: some View {
        VStack(spacing: 2) {
            // Avatar
            if let partnerAvatar = partnerProfile?.avatar, !partnerAvatar.isEmpty,
               let imgData = Data(base64Encoded: partnerAvatar),
               let uiImage = UIImage(data: imgData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(isAdmin ? "👩" : "👨")
                            .font(.system(size: 16))
                    )
            }
            // Name with chevron
            HStack(spacing: 2) {
                Text(partnerProfile?.displayName.isEmpty == false ? partnerProfile!.displayName : (isAdmin ? "Tucancita" : "Isacc"))
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - iMessage Bubble
    private func iMessageBubble(_ msg: ChatMessage, index: Int) -> some View {
        let isMe = msg.sender == mySender
        let showTail = shouldShowTail(at: index)
        let showTimestamp = shouldShowTimestamp(at: index)
        
        return VStack(spacing: 0) {
            // Timestamp separator
            if showTimestamp {
                Text(formatDate(msg.createdAt))
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            }
            
            HStack(alignment: .bottom, spacing: 4) {
                if isMe { Spacer(minLength: 60) }
                
                VStack(alignment: isMe ? .trailing : .leading, spacing: 1) {
                    // Content
                    switch msg.type {
                    case "image":
                        if let data = msg.mediaData, let imgData = Data(base64Encoded: data), let uiImage = UIImage(data: imgData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(maxWidth: 240, maxHeight: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 18))
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
                                .frame(width: 150, height: 150)
                        }
                        
                    default: // text, link
                        // Check if it's just an emoji (1-3 emoji chars)
                        if msg.content.count <= 4 && msg.content.unicodeScalars.allSatisfy({ $0.properties.isEmoji }) {
                            Text(msg.content)
                                .font(.system(size: 48))
                                .padding(.vertical, 4)
                        } else {
                            Text(msg.content)
                                .font(.system(.body, design: .default))
                                .foregroundStyle(isMe ? .white : .primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    iMessageBubbleShape(isMe: isMe, showTail: showTail)
                                        .fill(isMe ? AnyShapeStyle(sentGradient) : AnyShapeStyle(receivedColor))
                                )
                        }
                    }
                    
                    // Delivery indicator (only for sent messages)
                    if isMe && index == messages.count - 1 {
                        HStack(spacing: 2) {
                            Text(msg.seen == true ? "Leído" : "Entregado")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.trailing, 4)
                        .padding(.top, 1)
                    }
                }
                
                if !isMe { Spacer(minLength: 60) }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, showTail ? 2 : 0.5)
        }
    }
    
    // MARK: - iMessage Bubble Shape
    private func iMessageBubbleShape(isMe: Bool, showTail: Bool) -> some Shape {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
    }
    
    // MARK: - Helpers
    private func shouldShowTail(at index: Int) -> Bool {
        guard index < messages.count else { return true }
        let msg = messages[index]
        if index == messages.count - 1 { return true }
        let next = messages[index + 1]
        return next.sender != msg.sender
    }
    
    private func shouldShowTimestamp(at index: Int) -> Bool {
        if index == 0 { return true }
        guard let currentDate = parseDate(messages[index].createdAt),
              let prevDate = parseDate(messages[index - 1].createdAt) else { return false }
        return currentDate.timeIntervalSince(prevDate) > 300 // 5 min gap
    }
    
    private func parseDate(_ dateStr: String?) -> Date? {
        guard let str = dateStr else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: str) ?? ISO8601DateFormatter().date(from: str)
    }
    
    // MARK: - iMessage Input Bar
    private var iMessageInputBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.3)
            HStack(alignment: .bottom, spacing: 8) {
                // Plus button for attachments
                Menu {
                    Button { showPhotosPicker = true } label: { Label("Foto", systemImage: "photo.fill") }
                    Button { showStickerPicker = true } label: { Label("Sticker", systemImage: "face.smiling.inverse") }
                    Button { showAIGenerator = true } label: { Label("Sticker IA ✨", systemImage: "wand.and.stars") }
                    Button { pasteLink() } label: { Label("Pegar Link", systemImage: "link") }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
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
                
                // iMessage-style text field
                HStack(alignment: .bottom) {
                    TextField("iMessage", text: $messageText, axis: .vertical)
                        .lineLimit(1...6)
                        .font(.system(.body))
                    
                    if !messageText.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button { Task { await sendText() } } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                        }
                        .disabled(isSending)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(duration: 0.2), value: messageText)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5)
                        )
                )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
        }
    }
    
    // MARK: - Sticker Picker
    private var stickerPickerSheet: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Stickers de la App").font(.system(.headline, design: .rounded, weight: .bold)).foregroundStyle(.primary)
                        
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
                Color(UIColor.systemBackground).ignoresSafeArea()
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 50))
                        .foregroundStyle(.linearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    Text("Generador de Stickers IA")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    
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
                            LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
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
        guard let date = parseDate(dateStr) else { return "" }
        let df = DateFormatter(); df.dateFormat = "h:mm a"
        return df.string(from: date)
    }
    
    private func formatDate(_ dateStr: String?) -> String {
        guard let date = parseDate(dateStr) else { return "" }
        let calendar = Calendar.current
        let df = DateFormatter()
        if calendar.isDateInToday(date) {
            df.dateFormat = "h:mm a"
            return df.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            df.dateFormat = "h:mm a"
            return "Ayer " + df.string(from: date)
        } else {
            df.dateFormat = "d MMM, h:mm a"
            df.locale = Locale(identifier: "es_ES")
            return df.string(from: date)
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
                    VStack(spacing: 12) {
                        if let data = editAvatarData ?? (myProfile?.avatar.isEmpty == false ? Data(base64Encoded: myProfile!.avatar) : nil),
                           let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                        } else {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 100, height: 100)
                                .overlay(Text(isAdmin ? "👨" : "👩").font(.system(size: 44)))
                        }
                        PhotosPicker(selection: $editAvatarItem, matching: .images) {
                            Label("Cambiar foto", systemImage: "camera.fill")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundStyle(.blue)
                        }
                        .onChange(of: editAvatarItem) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
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
                        Text("Estado").font(.system(.caption, design: .rounded, weight: .bold)).foregroundStyle(.secondary)
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
                            .background(Capsule().fill(.blue))
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
