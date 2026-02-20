import SwiftUI
import SwiftData

struct TodayView: View {
    let viewModel: AppViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedMessage.savedAt, order: .reverse) private var savedMessages: [SavedMessage]
    @State private var heartBounce: Int = 0
    @State private var appeared = false

    var body: some View {
        ZStack {
            Theme.meshBackground

            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)

                    headerSection

                    messageCard

                    saveButton

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 24)
            }
            .scrollIndicators(.hidden)
        }
        .overlay {
            if viewModel.showSavedConfirmation {
                savedConfirmationOverlay
            }
        }
        .task {
            await viewModel.loadTodayMessage()
            withAnimation(.easeOut(duration: 0.8)) {
                appeared = true
            }
        }
        .refreshable {
            await viewModel.loadTodayMessage()
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
            RoundedRectangle(cornerRadius: 24)
                .fill(.white.opacity(0.75))
                .shadow(color: Theme.rosePrimary.opacity(0.12), radius: 20, y: 8)
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Theme.roseLight.opacity(0.6), lineWidth: 1)
                }
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
}
