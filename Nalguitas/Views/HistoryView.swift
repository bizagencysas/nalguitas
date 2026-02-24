import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MessageHistory.receivedAt, order: .reverse) private var history: [MessageHistory]
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground

                if history.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(groupedByDate, id: \.key) { group in
                            Section {
                                ForEach(group.messages) { entry in
                                    historyRow(entry)
                                        .listRowInsets(EdgeInsets())
                                        .listRowSeparator(.hidden)
                                        .listRowBackground(Color.clear)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                                withAnimation {
                                                    modelContext.delete(entry)
                                                }
                                            } label: {
                                                Label("Eliminar", systemImage: "trash")
                                            }
                                        }
                                        
                                        if entry.id != group.messages.last?.id {
                                            Divider()
                                                .overlay(Theme.roseLight.opacity(0.5))
                                                .padding(.horizontal, 20)
                                                .listRowInsets(EdgeInsets())
                                                .listRowSeparator(.hidden)
                                                .listRowBackground(Color.clear)
                                        }
                                }
                            } header: {
                                sectionHeader(group.key)
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollIndicators(.hidden)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44))
                .foregroundStyle(Theme.roseLight)
                .symbolEffect(.breathe, options: .repeating)

            Text("Sin historial aún")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)

            Text("Los mensajes que recibas aparecerán aquí")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.textSecondary.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .opacity(appeared ? 1 : 0)
    }

    private func historyRow(_ entry: MessageHistory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.content)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
                .lineSpacing(3)

            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(Theme.rosePrimary.opacity(0.6))

                Text(entry.subtitle)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(Theme.textSecondary)

                Spacer()

                Text(entry.receivedAt, format: .dateTime.hour().minute())
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(Theme.blush)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(.caption, design: .rounded, weight: .bold))
                .foregroundStyle(Theme.textSecondary.opacity(0.8))
                .textCase(.uppercase)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private var groupedByDate: [(key: String, messages: [MessageHistory])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: history) { entry in
            if calendar.isDateInToday(entry.receivedAt) {
                return "Hoy"
            } else if calendar.isDateInYesterday(entry.receivedAt) {
                return "Ayer"
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "es_MX")
                formatter.dateFormat = "d 'de' MMMM"
                return formatter.string(from: entry.receivedAt)
            }
        }

        let order: [String: Int] = {
            var map: [String: Int] = [:]
            for entry in history {
                let key: String
                if calendar.isDateInToday(entry.receivedAt) {
                    key = "Hoy"
                } else if calendar.isDateInYesterday(entry.receivedAt) {
                    key = "Ayer"
                } else {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "es_MX")
                    formatter.dateFormat = "d 'de' MMMM"
                    key = formatter.string(from: entry.receivedAt)
                }
                if map[key] == nil {
                    map[key] = map.count
                }
            }
            return map
        }()

        return grouped
            .map { (key: $0.key, messages: $0.value.sorted { $0.receivedAt > $1.receivedAt }) }
            .sorted { (order[$0.key] ?? 999) < (order[$1.key] ?? 999) }
    }
}
