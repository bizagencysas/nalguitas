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
            .navigationTitle(isAdmin ? "Chat con Mi Amor 💕" : "Chat con Isacc 💕")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showStickerPicker) { stickerPickerSheet }
            .sheet(isPresented: $showAIGenerator) { aiGeneratorSheet }
            .task { await loadMessages(); startPolling() }
            .onDisappear { pollTimer?.invalidate() }
        }
    }
    
    // MARK: - Message Bubble
    private func messageBubble(_ msg: ChatMessage) -> some View {
        let isMe = msg.sender == mySender
        
        return HStack {
            if isMe { Spacer(minLength: 50) }
            
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
                        Text("Stickers de la App").font(.system(.headline, weight: .bold, design: .rounded)).foregroundStyle(Theme.rosePrimary)
                        
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
                            Text("Stickers IA Generados").font(.system(.headline, weight: .bold, design: .rounded)).foregroundStyle(.purple)
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
                        .font(.system(.title2, weight: .bold, design: .rounded))
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
                        .font(.system(.body, weight: .semibold, design: .rounded))
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
        pollTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            Task { @MainActor in
                let newMsgs = try? await APIService.shared.fetchChatMessages()
                if let msgs = newMsgs, msgs.count > messages.count {
                    messages = msgs
                    try? await APIService.shared.markChatSeen(sender: mySender)
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
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
}
