import SwiftUI
import SwiftData

struct SavedView: View {
    @Query(sort: \SavedMessage.savedAt, order: .reverse) private var savedMessages: [SavedMessage]
    @Environment(\.modelContext) private var modelContext
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground

                if savedMessages.isEmpty {
                    emptyState
                } else {
                    messagesList
                }
            }
            .navigationTitle("Guardados")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 52))
                .foregroundStyle(Theme.blush)
                .symbolEffect(.pulse, options: .repeating)

            Text("A\u{00FA}n no has guardado mensajes")
                .font(.system(.title3, design: .rounded, weight: .medium))
                .foregroundStyle(Theme.textPrimary)

            Text("Cuando un mensaje te haga sonre\u{00ED}r,\ngu\u{00E1}rdalo aqu\u{00ED} para siempre")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }

    private var messagesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(savedMessages.enumerated()), id: \.element.persistentModelID) { index, message in
                    savedCard(message: message, index: index)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }

    private func savedCard(message: SavedMessage, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text("\u{201C}")
                    .font(.system(size: 32, weight: .ultraLight, design: .serif))
                    .foregroundStyle(Theme.blush)

                Spacer()

                toneTag(message.tone)
            }

            Text(message.content)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text(message.subtitle)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                Text(message.savedAt, format: .dateTime.day().month(.abbreviated))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(Theme.textSecondary.opacity(0.7))
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.75))
                .shadow(color: Theme.rosePrimary.opacity(0.08), radius: 12, y: 4)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.roseLight.opacity(0.5), lineWidth: 0.5)
                }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 15)
        .animation(.spring(response: 0.4).delay(Double(index) * 0.06), value: appeared)
        .contextMenu {
            Button(role: .destructive) {
                withAnimation {
                    modelContext.delete(message)
                }
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    private func toneTag(_ tone: String) -> some View {
        Text(toneEmoji(tone))
            .font(.caption2)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background {
                Capsule()
                    .fill(Theme.rosePale)
            }
    }

    private func toneEmoji(_ tone: String) -> String {
        switch tone.lowercased() {
        case "tierno": return "tierno"
        case "rom\u{00E1}ntico", "romantico": return "rom\u{00E1}ntico"
        case "profundo": return "profundo"
        case "divertido": return "divertido"
        default: return tone
        }
    }
}
