import SwiftUI
import PhotosUI
import LinkPresentation
import AVKit
import Photos

struct ChatView: View {
    let isAdmin: Bool
    @State private var messages: [ChatMessage] = ChatCache.load()
    @State private var messageText = ""
    @State private var isSending = false
    @State private var showPhotosPicker = false
    @State private var showVideoPicker = false
    @State private var showStickerPicker = false
    @State private var showAIGenerator = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedVideoItem: PhotosPickerItem?
    @State private var aiPrompt = ""
    @State private var isGeneratingSticker = false
    @State private var cachedStickers: [AISticker] = []
    @State private var scrollProxy: ScrollViewProxy?
    @State private var pollTimer: Timer?
    
    // Nalguitas Pay
    @State private var showPaymentSheet = false
    @State private var paymentAmount = ""
    @State private var paymentNote = ""
    
    // Link previews cache
    @State private var linkPreviews: [String: LinkPreviewData] = [:]
    
    // Full-screen photo viewer with Matched Geometry Flow
    @State private var fullScreenData: (image: UIImage, id: String)?
    @Namespace private var imageAnimation
    @State private var viewerDragOffset: CGSize = .zero
    
    // Optimistic sending: tracks messages waiting to be confirmed by server
    @State private var pendingMessages: Set<String> = []
    
    // BBM-style profiles
    @State private var myProfile: UserProfile?
    @State private var partnerProfile: UserProfile?
    @State private var showProfileSheet = false
    @State private var editDisplayName = ""
    @State private var editStatus = ""
    @State private var editAvatarItem: PhotosPickerItem?
    @State private var editAvatarData: Data?
    
    // Swipe to Reply
    @State private var replyingToMessage: ChatMessage?
    
    // Typing Indicator
    @State private var isPartnerTyping = false
    
    private var mySender: String { isAdmin ? "admin" : "girlfriend" }
    
    // Chat colors (rose palette, dark mode adaptive)
    private let sentGradient = LinearGradient(
        colors: [Theme.chatSentBubble, Theme.chatSentBubbleEnd],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    private let receivedColor = Theme.chatReceivedBubble
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Glass background with floating orbs
                Theme.chatMeshBackground
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
                        .defaultScrollAnchor(.bottom)
                        .scrollDismissesKeyboard(.interactively)
                        .onAppear { scrollProxy = proxy }
                        .onChange(of: messages.count) { oldCount, newCount in
                            if newCount > oldCount {
                                scrollToBottom(proxy)
                                // Soft haptic when a new message arrives and scroll triggers
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            }
                        }
                        
                        // Typing Indicator
                        if isPartnerTyping {
                            TypingIndicatorView()
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                                .transition(.asymmetric(insertion: .scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity), removal: .scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity)))
                        }
                    }
                    // iMessage-style input bar
                    VStack(spacing: 0) {
                        if let replyMsg = replyingToMessage {
                            replyPreviewBanner(replyMsg)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        iMessageInputBar
                    }
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
            .sheet(isPresented: $showPaymentSheet) { paymentSheet }
            .overlay {
                if let data = fullScreenData {
                    photoViewerOverlay(data.image, id: data.id)
                }
            }
            .task { await loadProfiles(); await loadMessages(); startPolling() }
            .onDisappear { pollTimer?.invalidate() }
        }
    }
    
    // MARK: - Reply Preview Banner
    @ViewBuilder
    private func replyPreviewBanner(_ msg: ChatMessage) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Respondiendo a \(msg.sender == mySender ? "Ti" : (isAdmin ? "Ella" : "Isacc"))")
                    .font(.caption2)
                    .foregroundStyle(Theme.rosePrimary)
                    .fontWeight(.bold)
                Text(msg.content.isEmpty ? (msg.type == "image" ? "📸 Foto" : "🎤 Audio") : msg.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            // Cancel reply
            Button {
                withAnimation { replyingToMessage = nil }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    // MARK: - Chat Header (large photo + name)
    private var iMessageHeader: some View {
        VStack(spacing: 6) {
            // Large avatar with ring
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Theme.rosePrimary, Theme.blush, Theme.roseLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 78, height: 78)
                
                if let partnerAvatar = partnerProfile?.avatar, !partnerAvatar.isEmpty,
                   let imgData = Data(base64Encoded: partnerAvatar),
                   let uiImage = UIImage(data: imgData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 72, height: 72)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Text(isAdmin ? "👩" : "👨")
                                .font(.system(size: 32))
                        )
                }
            }
            
            // Name + chevron
            HStack(spacing: 3) {
                Text(partnerProfile?.displayName.isEmpty == false ? partnerProfile!.displayName : (isAdmin ? "Tucancita" : "Isacc"))
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.top, 44)
        .padding(.bottom, 4)
    }
    
    // MARK: - Audio Message Bubble Spoof
    private func audioMessageBubble(duration: String, isMe: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "play.fill")
                .font(.system(size: 14))
                .foregroundStyle(isMe ? .white : Theme.rosePrimary)
            
            // Fake Waveform
            HStack(spacing: 3) {
                ForEach(0..<12, id: \.self) { i in
                    Capsule()
                        .fill(isMe ? .white.opacity(0.7) : Theme.textSecondary.opacity(0.5))
                        .frame(width: 3, height: CGFloat.random(in: 4...20))
                }
            }
            
            Text(duration)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(isMe ? .white : Theme.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            iMessageBubbleShape(isMe: isMe, showTail: true)
                .fill(isMe ? AnyShapeStyle(sentGradient) : AnyShapeStyle(.ultraThinMaterial))
                .shadow(color: isMe ? Theme.rosePrimary.opacity(0.15) : .black.opacity(0.04), radius: isMe ? 8 : 4, y: 2)
        )
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            // Here you'd trigger actual AVPlayer audio
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
                    Group {
                        switch msg.type {
                        case "image":
                            // Pass base64String ONLY if we just downloaded it from server (msg.mediaData acts as a fallback/first download payload)
                            AsyncBase64ImageView(base64String: msg.mediaData, msgId: msg.id, isSticker: false) { img, id in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    fullScreenData = (img, id)
                                }
                            }
                            .matchedGeometryEffect(id: msg.id, in: imageAnimation)
                        
                        case "video":
                            AsyncBase64VideoView(base64String: msg.mediaData, msgId: msg.id) { videoData in
                                saveVideoToCameraRoll(videoData)
                            }
                            
                        case "sticker":
                            AsyncBase64ImageView(base64String: msg.mediaData, msgId: msg.id, isSticker: true) { img, id in
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    fullScreenData = (img, id)
                                }
                            }
                            .matchedGeometryEffect(id: msg.id, in: imageAnimation)
                            
                        case "payment":
                            paymentBubble(amount: msg.content, note: msg.mediaUrl, isMe: isMe)
                        
                        case "link":
                            linkPreviewBubble(msg, isMe: isMe)
                        
                        case "audio":
                            audioMessageBubble(duration: msg.content, isMe: isMe)
                            
                        default: // text
                            // Check if it's just an emoji (1-3 emoji chars)
                            if msg.content.count <= 4 && msg.content.unicodeScalars.allSatisfy({ $0.properties.isEmoji }) {
                                Text(msg.content)
                                    .font(.system(size: 42))
                            } else {
                                Text(msg.content)
                                    .font(.system(size: 16, design: .rounded))
                                    .foregroundStyle(isMe ? .white : Theme.textPrimary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        iMessageBubbleShape(isMe: isMe, showTail: showTail)
                                            .fill(isMe ? AnyShapeStyle(sentGradient) : AnyShapeStyle(.ultraThinMaterial))
                                            .shadow(color: isMe ? Theme.rosePrimary.opacity(0.15) : .black.opacity(0.04), radius: isMe ? 8 : 4, y: 2)
                                    )
                            }
                        }
                    }
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = msg.content
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Label("Copiar Texto", systemImage: "doc.on.doc")
                        }
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                replyingToMessage = msg
                            }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        } label: {
                            Label("Responder", systemImage: "arrowshape.turn.up.left")
                        }
                        
                        if msg.type == "image" || msg.type == "video" {
                            Button {
                                // Visual pseudo-trigger, base functionality relies on deep viewer usually.
                                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            } label: {
                                Label("Guardar en Fotos", systemImage: "square.and.arrow.down")
                            }
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
            .onTapGesture(count: 2) {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }
        }
    }
    
    // MARK: - iMessage Bubble Shape
    private func iMessageBubbleShape(isMe: Bool, showTail: Bool) -> some Shape {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
    }
    
    // MARK: - Nalguitas Pay Bubble
    private func paymentBubble(amount: String, note: String?, isMe: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Text("Nalguitas Pay")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Image(systemName: isMe ? "arrow.up.right" : "arrow.down.left")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            
            // Amount
            Text(amount)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.top, 2)
            
            // Note
            if let note = note, !note.isEmpty {
                Text(note)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 12)
                    .padding(.top, 1)
            }
            
            // Footer
            HStack {
                Text(isMe ? "Enviado" : "Recibido")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                Text("💕")
                    .font(.system(size: 11))
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .padding(.bottom, 10)
        }
        .frame(width: 190)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Theme.rosePrimary,
                            Theme.blush,
                            Color(red: 0.82, green: 0.45, blue: 0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Theme.rosePrimary.opacity(0.25), radius: 8, y: 4)
        )
    }
    
    // MARK: - Payment Sheet
    private var paymentSheet: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemBackground).ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Apple Cash style circle
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Theme.rosePrimary, Theme.blush],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        Image(systemName: "dollarsign")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    
                    Text("Nalguitas Pay")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    
                    // Amount input
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("$")
                            .font(.system(size: 44, weight: .light, design: .rounded))
                            .foregroundStyle(.primary)
                        TextField("0", text: $paymentAmount)
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 200)
                    }
                    .padding(.vertical, 8)
                    
                    // Note field
                    TextField("Agregar nota... (opcional)", text: $paymentNote)
                        .font(.system(.body, design: .rounded))
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                        .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    // Send button  
                    Button {
                        Task { await sendPayment() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 22))
                            Text("Enviar")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule().fill(
                                paymentAmount.isEmpty
                                ? AnyShapeStyle(Color.gray.opacity(0.5))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [Theme.rosePrimary, Theme.blush],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                            )
                        )
                    }
                    .disabled(paymentAmount.isEmpty)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showPaymentSheet = false }
                }
            }
        }
    }
    
    private func sendPayment() async {
        guard !paymentAmount.isEmpty else { return }
        let amount = "$\(paymentAmount)"
        let note = paymentNote.isEmpty ? nil : paymentNote
        
        do {
            let msg = try await APIService.shared.sendChatMessage(
                sender: mySender,
                type: "payment",
                content: amount,
                mediaUrl: note
            )
            messages.append(msg)
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            paymentAmount = ""
            paymentNote = ""
            showPaymentSheet = false
        } catch {}
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
    
    // MARK: - Chat Input Bar (WhatsApp-style)
    private var iMessageInputBar: some View {
        VStack(spacing: 0) {
            Divider().opacity(0.3)
            HStack(alignment: .bottom, spacing: 6) {
                // + menu (stickers, AI, Pay, video)
                Menu {
                    Button { showStickerPicker = true } label: { Label("Sticker", systemImage: "face.smiling.inverse") }
                    Button { showAIGenerator = true } label: { Label("Sticker IA ✨", systemImage: "wand.and.stars") }
                    Button { pasteLink() } label: { Label("Pegar Link", systemImage: "link") }
                    Divider()
                    Button { showPaymentSheet = true } label: { Label("Nalguitas Pay 💸", systemImage: "dollarsign.circle.fill") }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Theme.rosePrimary.opacity(0.7))
                        .symbolRenderingMode(.hierarchical)
                }
                
                // Text field capsule
                HStack(alignment: .bottom, spacing: 6) {
                    TextField("Mensaje...", text: $messageText, axis: .vertical)
                        .lineLimit(1...5)
                        .font(.system(size: 16))
                    
                    // Camera button → directly opens photo picker
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.rosePrimary.opacity(0.6))
                    }
                    
                    // Video button
                    PhotosPicker(selection: $selectedVideoItem, matching: .videos, photoLibrary: .shared()) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.rosePrimary.opacity(0.6))
                    }
                    
                    // Send button (only when text)
                    if !messageText.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button { Task { await sendText() } } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Theme.rosePrimary)
                        }
                        .disabled(isSending)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(duration: 0.2), value: messageText)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(Color(UIColor.separator).opacity(0.4), lineWidth: 0.5)
                        )
                )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    let uiImage = UIImage(data: data)
                    if let compressed = uiImage?.jpegData(compressionQuality: 0.4) {
                        await sendMedia(type: "image", base64: compressed.base64EncodedString())
                    }
                }
                selectedPhotoItem = nil
            }
        }
        .onChange(of: selectedVideoItem) { _, newItem in
            Task {
                if let movie = try? await newItem?.loadTransferable(type: VideoTransferable.self) {
                    let data = try? Data(contentsOf: movie.url)
                    if let videoData = data, videoData.count <= 10 * 1024 * 1024 {
                        await sendMedia(type: "video", base64: videoData.base64EncodedString())
                    }
                }
                selectedVideoItem = nil
            }
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
                        .foregroundStyle(.linearGradient(colors: [Theme.rosePrimary, Theme.blush], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
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
                            LinearGradient(colors: [Theme.rosePrimary, Theme.blush], startPoint: .leading, endPoint: .trailing)
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
        // Fetch fresh messages from API in background
        do {
            let fresh = try await APIService.shared.fetchChatMessages()
            messages = fresh
            ChatCache.save(fresh)
            try? await APIService.shared.markChatSeen(sender: mySender)
        } catch {
            // Network failed — cached messages are already showing
        }
    }
    
    private func sendText() async {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let text = messageText; messageText = ""
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        let type = text.contains("http://") || text.contains("https://") ? "link" : "text"
        let mediaUrl = type == "link" ? text : nil
        
        let replyId = replyingToMessage?.id
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { replyingToMessage = nil }
        
        // 1. Optimistic: show message immediately
        let tempId = "local_\(UUID().uuidString)"
        let tempMsg = ChatMessage(id: tempId, sender: mySender, type: type, content: text, mediaData: nil, mediaUrl: mediaUrl, replyTo: replyId, seen: nil, createdAt: ISO8601DateFormatter().string(from: Date()))
        messages.append(tempMsg)
        ChatCache.save(messages)
        pendingMessages.insert(tempId)
        
        // Native Apple sent swoosh sound
        AmbientAudio.shared.playSentMessage()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { scrollProxy?.scrollTo(tempId, anchor: .bottom) }
        
        // 2. Try sending in background
        do {
            let _ = try await APIService.shared.sendChatMessage(sender: mySender, type: type, content: text, mediaUrl: mediaUrl, replyTo: replyId)
            pendingMessages.remove(tempId)
            await PointsService.shared.awardPoint(reason: "Envió mensaje 💬")
        } catch {
            // Message fails to send due to network issue - save to Drafts queue
            await MessageOutbox.shared.enqueue(sender: mySender, type: type, content: text, mediaUrl: mediaUrl, replyTo: replyId)
        }
    }
    
    private func sendMedia(type: String, base64: String) async {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        let replyId = replyingToMessage?.id
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { replyingToMessage = nil }
        
        // 1. Optimistic: show immediately
        let tempId = "local_\(UUID().uuidString)"
        let tempMsg = ChatMessage(id: tempId, sender: mySender, type: type, content: type == "sticker" ? "🎨" : "📷", mediaData: base64, mediaUrl: nil, replyTo: replyId, seen: nil, createdAt: ISO8601DateFormatter().string(from: Date()))
        messages.append(tempMsg)
        ChatCache.save(messages)
        pendingMessages.insert(tempId)
        
        // Native Apple sent swoosh sound
        AmbientAudio.shared.playSentMessage()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { scrollProxy?.scrollTo(tempId, anchor: .bottom) }
        
        // 2. Try sending in background
        do {
            let _ = try await APIService.shared.sendChatMessage(sender: mySender, type: type, content: type == "sticker" ? "🎨" : "📷", mediaData: base64, replyTo: replyId)
            pendingMessages.remove(tempId)
            await PointsService.shared.awardPoint(reason: "Envió media 📷")
        } catch {
            // Message fails to send due to network issue - save to Drafts queue
            await MessageOutbox.shared.enqueue(sender: mySender, type: type, content: type == "sticker" ? "🎨" : "📷", mediaData: base64, replyTo: replyId)
        }
    }
    
    private func sendEmoji(_ emoji: String) async {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        let replyId = replyingToMessage?.id
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { replyingToMessage = nil }
        
        let tempId = "local_\(UUID().uuidString)"
        let tempMsg = ChatMessage(id: tempId, sender: mySender, type: "text", content: emoji, mediaData: nil, mediaUrl: nil, replyTo: replyId, seen: nil, createdAt: ISO8601DateFormatter().string(from: Date()))
        messages.append(tempMsg)
        ChatCache.save(messages)
        showStickerPicker = false
        pendingMessages.insert(tempId)
        
        // Native Apple sent swoosh sound
        AmbientAudio.shared.playSentMessage()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { scrollProxy?.scrollTo(tempId, anchor: .bottom) }
        
        do {
            let _ = try await APIService.shared.sendChatMessage(sender: mySender, type: "text", content: emoji, replyTo: replyId)
            pendingMessages.remove(tempId)
        } catch {
            // Enqueue into offline outbox
            await MessageOutbox.shared.enqueue(sender: mySender, type: "text", content: emoji, replyTo: replyId)
        }
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
    
    private func saveVideoToCameraRoll(_ videoData: Data) {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
        do {
            try videoData.write(to: tempURL)
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
            } completionHandler: { success, _ in
                try? FileManager.default.removeItem(at: tempURL)
            }
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
        // Remove local temp messages that the server now has
        let localPending = messages.filter { $0.id.hasPrefix("local_") && pendingMessages.contains($0.id) }
        
        // Polling hook: If a new message from partner is detected during poll
        let oldPartnerCount = messages.filter { $0.sender != mySender }.count
        
        do {
            let fetched = newMsgs // Use newMsgs from the initial fetch
            let newPartnerCount = fetched.filter { $0.sender != mySender }.count
            
            // If there's a new message from the partner that wasn't there before
            if newPartnerCount > oldPartnerCount && !messages.isEmpty {
                // Determine the new incoming messages
                let newPartnerMsgs = fetched.filter { $0.sender != mySender }.suffix(newPartnerCount - oldPartnerCount)
                
                // Show typing indicator momentarily for the first new message
                if !isPartnerTyping {
                    withAnimation(.spring()) { isPartnerTyping = true }
                    
                    // Delay dropping the actual messages into the UI by 1.5 seconds to spool the typing animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        Task { @MainActor in
                            var merged = fetched
                            for pending in localPending {
                                let alreadySent = fetched.contains { $0.sender == pending.sender && $0.content == pending.content && $0.type == pending.type }
                                if !alreadySent {
                                    merged.append(pending)
                                } else {
                                    pendingMessages.remove(pending.id)
                                }
                            }
                            
                            withAnimation(.spring()) {
                                self.isPartnerTyping = false
                                self.messages = merged
                            }
                            
                            ChatCache.save(merged)
                            try? await APIService.shared.markChatSeen(sender: mySender)
                            // Haptic ping and Native Received Sound on arrival
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            AmbientAudio.shared.playReceivedMessage()
                        }
                    }
                    return // early exit so we don't immediately append it
                }
            }
            
            // Standard update if no new partner messages or if polling normally
            // Merge: keep server messages + any still-pending local messages
            var merged = newMsgs
            for pending in localPending {
                // Check if server already has this message (by content match)
                let alreadySent = newMsgs.contains { $0.sender == pending.sender && $0.content == pending.content && $0.type == pending.type }
                if !alreadySent {
                    merged.append(pending)
                } else {
                    pendingMessages.remove(pending.id)
                }
            }
            let oldCount = messages.count
            messages = merged
            ChatCache.save(merged)
            try? await APIService.shared.markChatSeen(sender: mySender)
            if merged.count > oldCount {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
        } catch {
            print("Poll error: \(error)")
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
                                .overlay(Circle().stroke(Theme.rosePrimary, lineWidth: 2))
                        } else {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 100, height: 100)
                                .overlay(Text(isAdmin ? "👨" : "👩").font(.system(size: 44)))
                        }
                        PhotosPicker(selection: $editAvatarItem, matching: .images) {
                            Label("Cambiar foto", systemImage: "camera.fill")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .foregroundStyle(Theme.rosePrimary)
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
    
    // MARK: - Full-Screen Photo Viewer
    @ViewBuilder
    private func photoViewerOverlay(_ image: UIImage, id: String) -> some View {
        let dragScale = max(0.6, 1.0 - abs(viewerDragOffset.height) / 1000.0)
        let bgOpacity = max(0.0, 1.0 - abs(viewerDragOffset.height) / 400.0)
        
        ZStack {
            Color.black.opacity(bgOpacity).ignoresSafeArea()
                .onTapGesture { withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { fullScreenData = nil } }
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .matchedGeometryEffect(id: id, in: imageAnimation)
                .offset(viewerDragOffset)
                .scaleEffect(dragScale)
                .gesture(
                    DragGesture()
                        .onChanged { val in
                            viewerDragOffset = val.translation
                        }
                        .onEnded { val in
                            if abs(val.translation.height) > 100 {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    fullScreenData = nil
                                    viewerDragOffset = .zero
                                }
                            } else {
                                withAnimation(.spring()) { viewerDragOffset = .zero }
                            }
                        }
                )
                .ignoresSafeArea()
                // Cinematic Parallax tilt
                .parallaxMotion(magnitude: 35)
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { fullScreenData = nil }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(16)
                    }
                }
                .opacity(bgOpacity)
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    } label: {
                        Label("Guardar", systemImage: "square.and.arrow.down")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(.ultraThinMaterial))
                    }
                    .padding(20)
                }
                .opacity(bgOpacity)
            }
        }
        .transition(.opacity)
        .zIndex(100)
    }
}

// MARK: - Link Preview Data
struct LinkPreviewData {
    let title: String?
    let url: String
    let domain: String
    let icon: UIImage?
    let image: UIImage?
    
    var platformIcon: String {
        let d = domain.lowercased()
        if d.contains("youtube") || d.contains("youtu.be") { return "▶️" }
        if d.contains("tiktok") { return "🎵" }
        if d.contains("instagram") { return "📸" }
        if d.contains("twitter") || d.contains("x.com") { return "🐦" }
        if d.contains("spotify") { return "🎧" }
        return "🔗"
    }
}

// MARK: - Link Preview Bubble Extension
extension ChatView {
    func linkPreviewBubble(_ msg: ChatMessage, isMe: Bool) -> some View {
        let urlString = msg.mediaUrl ?? msg.content
        let preview = linkPreviews[msg.id]
        
        return VStack(alignment: .leading, spacing: 0) {
            // Preview image if available
            if let image = preview?.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: 260, maxHeight: 140)
                    .clipped()
            }
            
            // Content section
            VStack(alignment: .leading, spacing: 4) {
                // Domain badge
                HStack(spacing: 4) {
                    Text(preview?.platformIcon ?? "🔗")
                        .font(.system(size: 12))
                    Text(preview?.domain ?? (URL(string: urlString)?.host ?? urlString))
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                // Title
                if let title = preview?.title, !title.isEmpty {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
                
                // URL
                Text(urlString.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: "").prefix(50) + (urlString.count > 60 ? "..." : ""))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isMe 
                      ? AnyShapeStyle(sentGradient)
                      : AnyShapeStyle(.ultraThinMaterial))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onTapGesture {
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
        .task {
            if linkPreviews[msg.id] == nil {
                await fetchLinkPreview(for: msg)
            }
        }
    }
    
    func fetchLinkPreview(for msg: ChatMessage) async {
        let urlString = msg.mediaUrl ?? msg.content
        guard let url = URL(string: urlString) else { return }
        
        let provider = LPMetadataProvider()
        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            
            var thumbnail: UIImage?
            if let imageProvider = metadata.imageProvider {
                thumbnail = await withCheckedContinuation { continuation in
                    imageProvider.loadObject(ofClass: UIImage.self) { image, _ in
                        continuation.resume(returning: image as? UIImage)
                    }
                }
            }
            
            var icon: UIImage?
            if let iconProvider = metadata.iconProvider {
                icon = await withCheckedContinuation { continuation in
                    iconProvider.loadObject(ofClass: UIImage.self) { image, _ in
                        continuation.resume(returning: image as? UIImage)
                    }
                }
            }
            
            let domain = url.host ?? urlString
            let preview = LinkPreviewData(
                title: metadata.title,
                url: urlString,
                domain: domain,
                icon: icon,
                image: thumbnail
            )
            
            await MainActor.run {
                linkPreviews[msg.id] = preview
            }
        } catch {}
    }
}

// MARK: - Video Transferable
struct VideoTransferable: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: tempURL)
            return Self(url: tempURL)
        }
    }
}

// MARK: - Video Bubble View
struct VideoBubbleView: View {
    let videoData: Data
    @State private var isPlaying = false
    @State private var player: AVPlayer?
    @State private var thumbnail: UIImage?
    
    var body: some View {
        ZStack {
            if isPlaying, let player = player {
                VideoPlayer(player: player)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
            } else {
                // Thumbnail with play button
                if let thumb = thumbnail {
                    Image(uiImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            ProgressView()
                                .tint(.white)
                        )
                }
                
                // Play button overlay
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                            .offset(x: 2)
                    )
                    .shadow(radius: 4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isPlaying {
                isPlaying = false
                player?.pause()
            } else {
                setupPlayer()
                isPlaying = true
            }
        }
        .task {
            await generateThumbnail()
        }
    }
    
    private func setupPlayer() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mp4")
        try? videoData.write(to: tempURL)
        player = AVPlayer(url: tempURL)
    }
    
    private func generateThumbnail() async {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)_thumb.mp4")
        try? videoData.write(to: tempURL)
        
        if let thumb = await VideoBubbleView.thumbnail(from: tempURL) {
            await MainActor.run {
                thumbnail = thumb
            }
        }
    }
    
    static func thumbnail(from videoURL: URL) async -> UIImage? {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 480)
        do {
            let cgImage = try await generator.image(at: .zero).image
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }
}

// MARK: - Chat Media Cache
class ChatMediaCache: @unchecked Sendable {
    static let shared = ChatMediaCache()
    let images = NSCache<NSString, UIImage>()
    let videos = NSCache<NSString, NSData>()
}

// MARK: - Async Decoders
struct AsyncBase64ImageView: View {
    let base64String: String?
    let msgId: String
    let isSticker: Bool
    var onImageTapped: ((UIImage, String) -> Void)? = nil
    
    @State private var uiImage: UIImage?
    @State private var isDecoding = false
    
    var body: some View {
        Group {
            if let uiImage = uiImage {
                if isSticker {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .onTapGesture { onImageTapped?(uiImage, msgId) }
                } else {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 240, maxHeight: 240)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .onTapGesture { onImageTapped?(uiImage, msgId) }
                        .contextMenu {
                            Button { UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil) } label: { Label("Guardar", systemImage: "square.and.arrow.down") }
                        }
                }
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: isSticker ? 150 : 200, height: isSticker ? 150 : 200)
                    .shimmering()
                .task(id: msgId) {
                    // Fast path 1: RAM Cache
                    let cachedImage = ChatMediaCache.shared.images.object(forKey: msgId as NSString)
                    if let cached = cachedImage {
                        self.uiImage = cached
                        return
                    }
                    guard !isDecoding else { return }
                    isDecoding = true
                    
                    Task.detached(priority: .userInitiated) {
                        // Fast path 2: Disk File (Native Cache)
                        let type = isSticker ? "sticker" : "image"
                        if let localURL = await MediaFileManager.shared.localURL(for: msgId, type: type),
                           let data = try? Data(contentsOf: localURL),
                           let img = UIImage(data: data) {
                            await MainActor.run { 
                                ChatMediaCache.shared.images.setObject(img, forKey: msgId as NSString)
                                self.uiImage = img 
                            }
                            return
                        }
                        
                        // Slow path: Decode Base64 from payload (only happens once on first arrival)
                        if let base64String = base64String, let data = Data(base64Encoded: base64String) {
                            // Save to disk for next time
                            _ = await MediaFileManager.shared.saveBase64Media(base64String, messageId: msgId, type: type)
                            if let img = UIImage(data: data) {
                                await MainActor.run { 
                                    ChatMediaCache.shared.images.setObject(img, forKey: msgId as NSString)
                                    self.uiImage = img 
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct AsyncBase64VideoView: View {
    let base64String: String?
    let msgId: String
    let onSave: (Data) -> Void
    
    @State private var videoData: Data?
    @State private var isDecoding = false
    
    var body: some View {
        Group {
            if let videoData = videoData {
                VideoBubbleView(videoData: videoData)
                    .frame(maxWidth: 240, maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .contextMenu {
                        Button {
                            onSave(videoData)
                        } label: {
                            Label("Guardar Video", systemImage: "square.and.arrow.down")
                        }
                    }
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 200, height: 150)
                    .shimmering()
                .task(id: msgId) {
                    let cachedVideo = ChatMediaCache.shared.videos.object(forKey: msgId as NSString)
                    if let cached = cachedVideo {
                        self.videoData = cached as Data
                        return
                    }
                    guard !isDecoding else { return }
                    isDecoding = true
                    
                    Task.detached(priority: .userInitiated) {
                        // Fast path 1: Disk File
                        if let localURL = await MediaFileManager.shared.localURL(for: msgId, type: "video"),
                           let data = try? Data(contentsOf: localURL) {
                            await MainActor.run { 
                                ChatMediaCache.shared.videos.setObject(data as NSData, forKey: msgId as NSString)
                                self.videoData = data 
                            }
                            return
                        }
                        
                        // Slow path: Decode Base64 (only happens first time)
                        if let base64String = base64String, let data = Data(base64Encoded: base64String) {
                            _ = await MediaFileManager.shared.saveBase64Media(base64String, messageId: msgId, type: "video")
                            await MainActor.run { 
                                ChatMediaCache.shared.videos.setObject(data as NSData, forKey: msgId as NSString)
                                self.videoData = data 
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Typing Indicator View
struct TypingIndicatorView: View {
    @State private var step = 0
    let dotColor = Theme.rosePrimary.opacity(0.8)
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            // "Head" of the bubble connecting to partner side
            Path { path in
                path.move(to: CGPoint(x: 16, y: 16))
                path.addCurve(to: CGPoint(x: 0, y: 16), control1: CGPoint(x: 8, y: 16), control2: CGPoint(x: 0, y: 16))
                path.addCurve(to: CGPoint(x: 8, y: 8), control1: CGPoint(x: 4, y: 16), control2: CGPoint(x: 8, y: 12))
                path.addCurve(to: CGPoint(x: 16, y: 16), control1: CGPoint(x: 8, y: 16), control2: CGPoint(x: 12, y: 16))
            }
            .fill(Color(UIColor.systemGray5))
            .frame(width: 16, height: 16)
            .offset(x: 4, y: 0)
            
            // Main Bubble
            HStack(spacing: 4) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
                    .offset(y: step == 0 ? -4 : 0)
                    .animation(Animation.easeInOut(duration: 0.4).repeatForever().delay(0.0), value: step)
                
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
                    .offset(y: step == 1 ? -4 : 0)
                    .animation(Animation.easeInOut(duration: 0.4).repeatForever().delay(0.2), value: step)
                
                Circle()
                    .fill(dotColor)
                    .frame(width: 6, height: 6)
                    .offset(y: step == 2 ? -4 : 0)
                    .animation(Animation.easeInOut(duration: 0.4).repeatForever().delay(0.4), value: step)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(UIColor.systemGray5))
            )
        }
        .onAppear {
            let timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                step = (step + 1) % 4
            }
            RunLoop.current.add(timer, forMode: .common)
        }
    }
}

// MARK: - Swipe To Reply Modifier
struct SwipeToReplyModifier: ViewModifier {
    let msg: ChatMessage
    let replyAction: () -> Void
    
    @State private var dragOffset: CGFloat = 0
    @State private var hasTriggered = false
    
    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            Image(systemName: "arrowshape.turn.up.left.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(Theme.rosePrimary.opacity(0.8))
                .opacity(min(1.0, Double(-dragOffset) / 50.0))
                .scaleEffect(min(1.0, Double(-dragOffset) / 50.0))
                .padding(.leading, 16)
            
            content
                .offset(x: dragOffset)
                .gesture(
                    DragGesture(minimumDistance: 15, coordinateSpace: .local)
                        .onChanged { value in
                            guard value.translation.width < 0 else {
                                dragOffset = 0
                                return
                            }
                            
                            // Parallax dampening effect like iMessage
                            let damp = CGFloat(0.4)
                            dragOffset = value.translation.width * damp
                            
                            if dragOffset < -50 && !hasTriggered {
                                hasTriggered = true
                                replyAction()
                            } else if dragOffset > -40 {
                                hasTriggered = false
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                dragOffset = 0
                                hasTriggered = false
                            }
                        }
                )
        }
    }
}
