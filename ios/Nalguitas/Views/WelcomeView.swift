import SwiftUI

struct WelcomeView: View {
    @State private var currentPage: Int = 0
    @State private var showRejection: Bool = false
    @State private var appeared: Bool = false
    @State private var autoScrollTask: Task<Void, Never>?
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        ZStack {
            Theme.meshBackground

            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                verificationPage.tag(1)
                finalPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            VStack {
                Spacer()
                pageIndicator
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                appeared = true
            }
            scheduleAutoScroll()
        }
        .onDisappear {
            autoScrollTask?.cancel()
        }
        .onChange(of: currentPage) { _, _ in
            autoScrollTask?.cancel()
        }
    }

    private func scheduleAutoScroll() {
        autoScrollTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled && currentPage == 0 {
                withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
                    currentPage = 1
                }
            }
        }
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Theme.roseLight.opacity(0.4))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)

                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.rosePrimary, Theme.blush],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .symbolEffect(.breathe, options: .repeating)
                }

                VStack(spacing: 12) {
                    Text("\u{00A1}Bienvenida!")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)

                    Text("Tienes algo especial esperando")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 30)

            Spacer()

            VStack(spacing: 8) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary.opacity(0.5))

                Text("Desliza")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(Theme.textSecondary.opacity(0.4))
            }
            .padding(.bottom, 100)
        }
    }

    // MARK: - Page 2: Verification

    private var verificationPage: some View {
        VStack(spacing: 0) {
            Spacer()

            if showRejection {
                rejectionContent
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                verificationContent
                    .transition(.opacity)
            }

            Spacer()
            Spacer().frame(height: 100)
        }
    }

    private var verificationContent: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(Theme.rosePale.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .blur(radius: 15)

                Text("\u{1F970}")
                    .font(.system(size: 64))
            }

            VStack(spacing: 12) {
                Text("\u{00BF}Eres Robi,")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)

                Text("mis nalguitas?")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.rosePrimary)
            }

            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                        currentPage = 2
                    }
                } label: {
                    Text("Sip \u{1F49C}")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 140, height: 52)
                        .background {
                            Capsule()
                                .fill(Theme.accentGradient)
                                .shadow(color: Theme.rosePrimary.opacity(0.3), radius: 12, y: 6)
                        }
                }
                .sensoryFeedback(.impact(flexibility: .soft), trigger: currentPage)

                Button {
                    withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                        showRejection = true
                    }
                } label: {
                    Text("Nop")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 140, height: 52)
                        .background {
                            Capsule()
                                .fill(.white.opacity(0.8))
                                .shadow(color: Theme.rosePrimary.opacity(0.1), radius: 8, y: 4)
                                .overlay {
                                    Capsule()
                                        .stroke(Theme.roseLight, lineWidth: 1)
                                }
                        }
                }
            }
        }
    }

    private var rejectionContent: some View {
        VStack(spacing: 28) {
            Text("\u{1F625}")
                .font(.system(size: 72))

            VStack(spacing: 12) {
                Text("Ay, lo siento...")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)

                Text("Esta app es \u{00FA}nicamente\npara Robi")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("Hecha con mucho amor solo para ella \u{1F49D}")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(Theme.blush)
                    .padding(.top, 4)
            }

            Button {
                withAnimation(.spring(duration: 0.4)) {
                    showRejection = false
                }
            } label: {
                Text("Volver")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background {
                        Capsule()
                            .fill(.white.opacity(0.7))
                            .overlay {
                                Capsule()
                                    .stroke(Theme.roseLight, lineWidth: 1)
                            }
                    }
            }
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Page 3: Final

    private var finalPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Theme.rosePrimary.opacity(0.08))
                            .frame(width: CGFloat(160 - i * 40), height: CGFloat(160 - i * 40))
                            .blur(radius: CGFloat(12 - i * 3))
                    }

                    Image(systemName: "sparkle")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Theme.rosePrimary, Theme.roseQuartz],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .symbolEffect(.variableColor.iterative, options: .repeating)
                }

                VStack(spacing: 14) {
                    Text("Una app para hacerte\nfeliz, nalguitas")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("Disfr\u{00FA}tala \u{2728}")
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .foregroundStyle(Theme.blush)
                }

                Button {
                    withAnimation(.spring(duration: 0.5, bounce: 0.2)) {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Comenzar")
                            .font(.system(.body, design: .rounded, weight: .bold))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        Capsule()
                            .fill(Theme.accentGradient)
                            .shadow(color: Theme.rosePrimary.opacity(0.35), radius: 16, y: 8)
                    }
                }
                .padding(.horizontal, 24)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: hasCompletedOnboarding)
            }

            Spacer()
            Spacer().frame(height: 100)
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Theme.rosePrimary : Theme.roseLight)
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.spring(duration: 0.3), value: currentPage)
            }
        }
    }
}
