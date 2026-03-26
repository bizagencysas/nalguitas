import SwiftUI
import SwiftData
import WidgetKit

struct TodayView: View {
    let viewModel: AppViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedMessage.savedAt, order: .reverse) private var savedMessages: [SavedMessage]
    @State private var heartBounce: Int = 0
    @State private var appeared = false
    @AppStorage("widgetCTADismissed") private var widgetCTADismissed = false
    @State private var hasWidgetInstalled = false
    @State private var showWidgetInstructions = false
    @State private var girlfriendMessage: String = ""
    @State private var isSendingGirlfriendMsg = false
    @State private var showGirlfriendSentConfirmation = false
    @State private var currentGift: Gift? = nil
    @State private var showGiftOverlay = false
    @State private var unreadChatCount = 0
    @State private var showNotifications = false
    
    // Holographic Magic
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    
    // Antigravity Confetti Magic
    @StateObject private var confettiManager = ConfettiManager()
    
    // Easter Egg Tracker
    @State private var secretTapCount = 0
    @State private var showSecretModal = false

    var body: some View {
        ZStack {
            Theme.meshBackground

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)

                    headerSection

                    messageCard

                    saveButton

                    girlfriendSendSection

                    if !widgetCTADismissed && !hasWidgetInstalled {
                        widgetCTA
                    }

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)
            
            // Floating chat button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        NotificationCenter.default.post(name: .switchToChatTab, object: nil)
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.rosePrimary, Theme.blush],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                                .shadow(color: Theme.rosePrimary.opacity(0.35), radius: 10, y: 4)
                                .overlay(
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(.white)
                                )
                            
                            if unreadChatCount > 0 {
                                Text("\(unreadChatCount)")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(.red))
                                    .offset(x: 6, y: -4)
                            }
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
            
            // Magical Confetti Layer
            ConfettiView(manager: confettiManager)
                .ignoresSafeArea()
        }
        .overlay(alignment: .topTrailing) {
            Button { showNotifications = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.rosePrimary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.ultraThinMaterial))
                        .shadow(color: Theme.rosePrimary.opacity(0.15), radius: 8, y: 2)
                    
                    if unreadChatCount > 0 {
                        Circle()
                            .fill(.red)
                            .frame(width: 10, height: 10)
                            .offset(x: 2, y: -1)
                    }
                }
            }
            .padding(.trailing, 20)
            .padding(.top, 56)
        }
        .sheet(isPresented: $showNotifications) {
            NotificationBellView()
                .presentationDetents([.medium, .large])
        }
        .overlay {
            if viewModel.showSavedConfirmation {
                savedConfirmationOverlay
            }
        }
        .overlay {
            if showGiftOverlay, let gift = currentGift {
                GiftOverlayView(gift: gift) {
                    showGiftOverlay = false
                    currentGift = nil
                }
                .transition(.opacity)
            }
        }
        .task {
            await viewModel.loadTodayMessage(context: modelContext)
            await checkForGifts()
            await PointsService.shared.awardDailyOpenPoint()
            let isAdmin = UserDefaults.standard.bool(forKey: "isAdminDevice")
            unreadChatCount = (try? await APIService.shared.fetchUnseenCount(sender: isAdmin ? "admin" : "girlfriend")) ?? 0
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
        }
        .refreshable {
            await viewModel.loadTodayMessage(context: modelContext)
        }
        .task {
            await checkWidgetInstalled()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            Task { await viewModel.loadTodayMessage(context: modelContext) }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didReceiveRemoteMessage)) { _ in
            Task {
                // Don't pass modelContext here — on cold start it may not be ready
                // and accessing it causes a crash. History save skipped for push-triggered loads.
                await viewModel.loadTodayMessage()
                await checkForGifts()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.system(size: 28))
                .foregroundStyle(Theme.rosePrimary)
                .symbolEffect(.breathe, options: .repeating)

            Text(greetingText)
                .font(.system(.title3, design: .rounded, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .onTapGesture {
                    secretTapCount += 1
                    if secretTapCount == 7 {
                        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        AmbientAudio.shared.playSuccess()
                        confettiManager.burst()
                        withAnimation { showSecretModal = true }
                        secretTapCount = 0
                    } else if secretTapCount > 4 {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    
                    // Reset tap count if they stop tapping
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        if secretTapCount < 7 { secretTapCount = 0 }
                    }
                }

            Text(viewModel.todayDateString)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
    }

    private var greetingText: String {
        let petNames = ["nalguitas", "tucancita", "futura esposa"]
        let name = petNames.randomElement()!
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Buenos d\u{00ED}as, \(name)"
        case 12..<18: return "Buenas tardes, \(name)"
        case 18..<22: return "Buenas noches, \(name)"
        default: return "Para ti, siempre"
        }
    }

    private var messageCard: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView()
                    .tint(Theme.rosePrimary)
                    .scaleEffect(1.2)
                    .frame(height: 120)
            } else if let message = viewModel.todayMessage {
                VStack(spacing: 16) {
                    Text("\u{201C}")
                        .font(.system(size: 48, weight: .ultraLight, design: .serif))
                        .foregroundStyle(Theme.blush)
                        .offset(y: 8)

                    Text(message.content)
                        .font(.system(.title2, design: .rounded, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(Theme.rosePrimary.opacity(0.5))
                            .frame(width: 4, height: 4)
                        Text(message.displaySubtitle)
                            .font(.system(.footnote, design: .rounded, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                        Circle()
                            .fill(Theme.rosePrimary.opacity(0.5))
                            .frame(width: 4, height: 4)
                    }
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 24)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "heart.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.roseLight)
                        .symbolEffect(.breathe, options: .repeating)

                    Text("A\u{00FA}n no hay mensaje")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)

                    Text("Cuando llegue uno, aparecer\u{00E1} aqu\u{00ED} para ti")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Theme.textSecondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Theme.rosePrimary.opacity(0.1), radius: 20, y: 8)
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.7), Theme.roseLight.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
        }
        // Holographic Tilt Magic
        .rotation3DEffect(
            .degrees(isDragging ? Double(dragOffset.width / -15) : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .rotation3DEffect(
            .degrees(isDragging ? Double(dragOffset.height / 15) : 0),
            axis: (x: 1, y: 0, z: 0)
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.7)) {
                        isDragging = true
                        dragOffset = value.translation
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        isDragging = false
                        dragOffset = .zero
                    }
                }
        )
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            confettiManager.burst()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    private var saveButton: some View {
        Group {
            if let message = viewModel.todayMessage {
                let isSaved = viewModel.isMessageSaved(message, savedMessages: savedMessages)

                Button {
                    if !isSaved {
                        viewModel.saveMessage(message, context: modelContext)
                        heartBounce += 1
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .symbolEffect(.bounce, value: heartBounce)
                            .foregroundStyle(isSaved ? .white : Theme.rosePrimary)

                        Text(isSaved ? "Guardado" : "Guardar este mensaje")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(isSaved ? .white : Theme.textPrimary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background {
                        Capsule()
                            .fill(isSaved ? AnyShapeStyle(Theme.accentGradient) : AnyShapeStyle(Color.white.opacity(0.8)))
                            .shadow(color: Theme.rosePrimary.opacity(0.15), radius: 8, y: 4)
                    }
                    .overlay {
                        Capsule()
                            .stroke(isSaved ? Color.clear : Theme.roseLight, lineWidth: 1)
                    }
                }
                .sensoryFeedback(.impact(flexibility: .soft), trigger: heartBounce)
                .disabled(isSaved)
                .opacity(appeared ? 1 : 0)
            }
        }
    }

    private var girlfriendSendSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .font(.caption)
                    .foregroundStyle(Theme.rosePrimary)
                Text("Enviar mensaje")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }

            HStack(spacing: 10) {
                TextField("Escribe algo bonito...", text: $girlfriendMessage)
                    .font(.system(.subheadline, design: .rounded))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background {
                        Capsule()
                            .fill(.white)
                            .stroke(Theme.roseLight, lineWidth: 1)
                    }

                Button {
                    Task { await sendGirlfriendMessage() }
                } label: {
                    Group {
                        if isSendingGirlfriendMsg {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background {
                        Circle().fill(Theme.accentGradient)
                    }
                }
                .disabled(girlfriendMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSendingGirlfriendMsg)
                .opacity(girlfriendMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            }

            if showGirlfriendSentConfirmation {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text("Mensaje enviado")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Theme.rosePrimary.opacity(0.06), radius: 12, y: 4)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), Theme.roseLight.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
        }
        .opacity(appeared ? 1 : 0)
        .sensoryFeedback(.success, trigger: showGirlfriendSentConfirmation)
    }

    private func sendGirlfriendMessage() async {
        let content = girlfriendMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        isSendingGirlfriendMsg = true
        defer { isSendingGirlfriendMsg = false }
        do {
            try await APIService.shared.sendGirlfriendMessage(content: content)
            girlfriendMessage = ""
            withAnimation(.spring(duration: 0.3)) {
                showGirlfriendSentConfirmation = true
            }
            Task {
                try? await Task.sleep(for: .seconds(2.5))
                withAnimation(.easeOut) {
                    showGirlfriendSentConfirmation = false
                }
            }
        } catch {}
    }

    private var widgetCTA: some View {
        Button {
            showWidgetInstructions = true
        } label: {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundStyle(Theme.rosePrimary)

                    Text("Lleva tu mensaje al inicio")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)

                    Spacer()

                    Button {
                        withAnimation(.easeOut(duration: 0.3)) {
                            widgetCTADismissed = true
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.textSecondary.opacity(0.5))
                            .frame(width: 24, height: 24)
                    }
                }

                Text("Agrega el widget y tendr\u{00E1}s cada mensaje cerquita, sin abrir la app \u{1F49D}")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineSpacing(2)
            }
        }
        .buttonStyle(.plain)
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: Theme.rosePrimary.opacity(0.06), radius: 12, y: 4)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.6), Theme.roseLight.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
        }
        .opacity(appeared ? 1 : 0)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .sheet(isPresented: $showWidgetInstructions) {
            WidgetInstructionsSheet()
                .presentationDetents([.medium])
        }
    }

    private func checkWidgetInstalled() async {
        do {
            let configs = try await WidgetCenter.shared.currentConfigurations()
            if !configs.isEmpty {
                hasWidgetInstalled = true
            }
        } catch {
            // ignore
        }
    }

    private var savedConfirmationOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 36))
                .foregroundStyle(Theme.rosePrimary)

            Text("Guardado con amor")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20)
        }
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation(.easeOut) {
                    viewModel.showSavedConfirmation = false
                }
            }
        }
    }
    
    private func checkForGifts() async {
        do {
            let gifts = try await APIService.shared.fetchUnseenGifts()
            if let gift = gifts.first {
                try? await Task.sleep(for: .seconds(1.5))
                await MainActor.run {
                    currentGift = gift
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showGiftOverlay = true
                    }
                }
            }
        } catch {
            // Silent fail - gifts are optional
        }
    }
}

// MARK: - Easter Egg Modal View
struct EasterEggModalView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Theme.meshBackground.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.rosePrimary)
                    .symbolEffect(.pulse)
                
                Text("¡Desbloqueaste el Secreto!")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Esta app está hecha con muchísimo amor. Eres nuestro VIP absoluto. No hay nadie más importante para Nalguitas que tú. ✨💖")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
                
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .rigid)
                    impact.impactOccurred()
                    dismiss()
                } label: {
                    Text("Guardar el secreto 🤫")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(Capsule().fill(Theme.rosePrimary))
                        .shadow(color: Theme.rosePrimary.opacity(0.3), radius: 8, y: 4)
                }
            }
            .padding()
        }
    }
}
