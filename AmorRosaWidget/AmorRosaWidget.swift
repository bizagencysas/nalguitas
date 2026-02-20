import WidgetKit
import SwiftUI

nonisolated struct LoveEntry: TimelineEntry {
    let date: Date
    let message: String
    let subtitle: String
    let sparkleIndex: Int
}

nonisolated struct LoveProvider: TimelineProvider {
    private let appGroupID = "group.app.rork.amor-rosa-app"

    private let fallbackMessages: [(String, String)] = [
        ("Te quiero mucho", "Para ti"),
        ("Eres lo mejor de mi vida", "Siempre"),
        ("Hoy te ves preciosa", "Un susurro"),
        ("Pienso en ti todo el tiempo", "De coraz\u{00F3}n"),
        ("Eres mi lugar tranquilo", "Solo para ti"),
        ("Ojalá est\u{00E9}s sonriendo", "Pensando en ti"),
    ]

    func placeholder(in context: Context) -> LoveEntry {
        LoveEntry(date: .now, message: "Te quiero mucho", subtitle: "Para ti", sparkleIndex: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (LoveEntry) -> Void) {
        let entry = loadEntry(date: .now, sparkleIndex: 0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LoveEntry>) -> Void) {
        var entries: [LoveEntry] = []
        let now = Date()

        for i in 0..<6 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: i * 4, to: now)!
            let entry = loadEntry(date: entryDate, sparkleIndex: i % 3)
            entries.append(entry)
        }

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 4, to: now)!
        completion(Timeline(entries: entries, policy: .after(nextUpdate)))
    }

    private func loadEntry(date: Date, sparkleIndex: Int) -> LoveEntry {
        let defaults = UserDefaults(suiteName: appGroupID)
        if let message = defaults?.string(forKey: "todayMessage") {
            let subtitle = defaults?.string(forKey: "todaySubtitle") ?? "Para ti"
            return LoveEntry(date: date, message: message, subtitle: subtitle, sparkleIndex: sparkleIndex)
        }

        let dayIndex = Calendar.current.component(.day, from: date) % fallbackMessages.count
        let fallback = fallbackMessages[dayIndex]
        return LoveEntry(date: date, message: fallback.0, subtitle: fallback.1, sparkleIndex: sparkleIndex)
    }
}

struct SmallWidgetView: View {
    let entry: LoveEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                sparkleIcon
            }

            Spacer()

            Text(entry.message)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color(red: 0.30, green: 0.20, blue: 0.22))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .minimumScaleFactor(0.8)

            Spacer()

            Text(entry.subtitle)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(Color(red: 0.55, green: 0.42, blue: 0.45))
        }
        .padding(14)
    }

    private var sparkleIcon: some View {
        Group {
            switch entry.sparkleIndex {
            case 0:
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.91, green: 0.58, blue: 0.65))
            case 1:
                Image(systemName: "sparkle")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.95, green: 0.73, blue: 0.78))
            default:
                Image(systemName: "heart.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.91, green: 0.58, blue: 0.65).opacity(0.7))
            }
        }
    }
}

struct MediumWidgetView: View {
    let entry: LoveEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.title3)
                    .foregroundStyle(Color(red: 0.91, green: 0.58, blue: 0.65))

                Text("Amor\nRosa")
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color(red: 0.55, green: 0.42, blue: 0.45))
                    .multilineTextAlignment(.center)
            }
            .frame(width: 60)

            VStack(alignment: .leading, spacing: 8) {
                Text(entry.message)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color(red: 0.30, green: 0.20, blue: 0.22))
                    .lineSpacing(3)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(red: 0.91, green: 0.58, blue: 0.65).opacity(0.5))
                        .frame(width: 3, height: 3)
                    Text(entry.subtitle)
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(Color(red: 0.55, green: 0.42, blue: 0.45))
                    Circle()
                        .fill(Color(red: 0.91, green: 0.58, blue: 0.65).opacity(0.5))
                        .frame(width: 3, height: 3)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }
}

struct LoveWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LoveEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
    }
}

struct AmorRosaWidget: Widget {
    let kind: String = "AmorRosaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LoveProvider()) { entry in
            LoveWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.98, blue: 0.97),
                            Color(red: 0.99, green: 0.93, blue: 0.94),
                            Color(red: 0.98, green: 0.88, blue: 0.90).opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Amor Rosa")
        .description("Mensajes de amor en tu pantalla")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
