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
        if let message = defaults?.string(forKey: "todayMessage"), !message.isEmpty {
            let lastUpdated = defaults?.double(forKey: "lastUpdated") ?? 0
            let hoursSinceUpdate = Date().timeIntervalSince1970 - lastUpdated
            if hoursSinceUpdate < 10800 {
                let subtitle = defaults?.string(forKey: "todaySubtitle") ?? "Para ti"
                return LoveEntry(date: date, message: message, subtitle: subtitle, sparkleIndex: sparkleIndex)
            }
        }
        return LoveEntry(date: date, message: "", subtitle: "", sparkleIndex: sparkleIndex)
    }
}

struct SmallWidgetView: View {
    let entry: LoveEntry

    var body: some View {
        if entry.message.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "heart.circle")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.91, green: 0.58, blue: 0.65).opacity(0.6))

                Text("Esperando un mensaje...")
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(Color(red: 0.55, green: 0.42, blue: 0.45))
                    .multilineTextAlignment(.center)
            }
            .padding(14)
        } else {
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
        if entry.message.isEmpty {
            HStack(spacing: 16) {
                Image(systemName: "heart.circle")
                    .font(.title2)
                    .foregroundStyle(Color(red: 0.91, green: 0.58, blue: 0.65).opacity(0.6))

                Text("Esperando un mensaje...")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(Color(red: 0.55, green: 0.42, blue: 0.45))
            }
            .padding(16)
        } else {
            HStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.title3)
                        .foregroundStyle(Color(red: 0.91, green: 0.58, blue: 0.65))

                    Text("Nalguitas")
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
}

struct AccessoryRectangularView: View {
    let entry: LoveEntry

    var body: some View {
        if entry.message.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.caption)
                Text("Esperando mensaje...")
                    .font(.system(.caption, design: .rounded, weight: .medium))
            }
        } else {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9))
                    Text("Nalguitas")
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                }

                Text(entry.message)
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

struct AccessoryCircularView: View {
    let entry: LoveEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if entry.message.isEmpty {
                Image(systemName: "heart")
                    .font(.title3)
            } else {
                Image(systemName: "heart.fill")
                    .font(.title3)
            }
        }
    }
}

struct LoveWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LoveEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
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
        .configurationDisplayName("Nalguitas")
        .description("Mensajes de amor en tu pantalla")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}
