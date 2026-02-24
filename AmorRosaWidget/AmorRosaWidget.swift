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
        LoveEntry(date: .now, message: "Te quiero mucho 💕", subtitle: "Para ti", sparkleIndex: 0)
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
            if hoursSinceUpdate < 86400 {
                let subtitle = defaults?.string(forKey: "todaySubtitle") ?? "Para ti"
                return LoveEntry(date: date, message: message, subtitle: subtitle, sparkleIndex: sparkleIndex)
            }
        }
        return LoveEntry(date: date, message: "", subtitle: "", sparkleIndex: sparkleIndex)
    }
}

// MARK: - Small Widget (Home Screen)
struct SmallWidgetView: View {
    let entry: LoveEntry
    
    private let rose = Color(red: 0.91, green: 0.58, blue: 0.65)
    private let blush = Color(red: 0.95, green: 0.73, blue: 0.78)
    private let textDark = Color(red: 0.30, green: 0.20, blue: 0.22)
    private let textMuted = Color(red: 0.55, green: 0.42, blue: 0.45)

    var body: some View {
        if entry.message.isEmpty {
            emptyState
        } else {
            messageState
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(rose.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "heart.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(rose)
            }
            
            Text("Esperando\nun mensaje...")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(textMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
    }
    
    private var messageState: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: decorative dots + heart
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(rose.opacity(0.3 - Double(i) * 0.08))
                        .frame(width: 4, height: 4)
                        .padding(.trailing, 3)
                }
                Spacer()
                Image(systemName: sparkleIcon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(rose.opacity(0.6))
            }
            .padding(.bottom, 8)
            
            Spacer(minLength: 0)
            
            // Message
            Text(entry.message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(textDark)
                .lineLimit(4)
                .lineSpacing(2)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: false)
            
            Spacer(minLength: 0)
            
            // Bottom: subtitle + time
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(LinearGradient(colors: [rose, blush], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 12, height: 2)
                
                Text(entry.subtitle)
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundStyle(textMuted)
                
                Spacer()
                
                Text("💌")
                    .font(.system(size: 10))
            }
        }
        .padding(14)
    }
    
    private var sparkleIcon: String {
        switch entry.sparkleIndex {
        case 0: return "heart.fill"
        case 1: return "sparkle"
        default: return "star.fill"
        }
    }
}

// MARK: - Medium Widget (Home Screen)
struct MediumWidgetView: View {
    let entry: LoveEntry
    
    private let rose = Color(red: 0.91, green: 0.58, blue: 0.65)
    private let blush = Color(red: 0.95, green: 0.73, blue: 0.78)
    private let roseLight = Color(red: 0.98, green: 0.88, blue: 0.90)
    private let textDark = Color(red: 0.30, green: 0.20, blue: 0.22)
    private let textMuted = Color(red: 0.55, green: 0.42, blue: 0.45)

    var body: some View {
        if entry.message.isEmpty {
            emptyState
        } else {
            messageState
        }
    }
    
    private var emptyState: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(rose.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(rose)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Nalguitas")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(textDark)
                Text("Esperando un mensaje...")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(textMuted)
            }
            Spacer()
        }
        .padding(16)
    }
    
    private var messageState: some View {
        HStack(spacing: 14) {
            // Left: icon column
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [rose, blush],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 42, height: 42)
                    
                    Text("💌")
                        .font(.system(size: 20))
                }
                
                Text("Nalguitas")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(textMuted)
            }
            .frame(width: 50)
            
            // Divider line
            RoundedRectangle(cornerRadius: 1)
                .fill(LinearGradient(colors: [rose.opacity(0.3), roseLight.opacity(0.1)], startPoint: .top, endPoint: .bottom))
                .frame(width: 1.5)
                .padding(.vertical, 4)
            
            // Right: message content
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(textDark)
                    .lineLimit(3)
                    .lineSpacing(2)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: false)
                
                Spacer(minLength: 0)
                
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(rose.opacity(0.4 - Double(i) * 0.1))
                            .frame(width: 3, height: 3)
                    }
                    
                    Text(entry.subtitle)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(textMuted)
                    
                    Spacer()
                    
                    Text(entry.date, style: .time)
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(textMuted.opacity(0.7))
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Lock Screen Widgets
struct AccessoryRectangularView: View {
    let entry: LoveEntry

    var body: some View {
        if entry.message.isEmpty {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12, weight: .medium))
                    .widgetAccentable()
                VStack(alignment: .leading, spacing: 1) {
                    Text("Nalguitas")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .widgetAccentable()
                    Text("Esperando mensaje...")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 8, weight: .bold))
                        .widgetAccentable()
                    Text("Nalguitas")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .widgetAccentable()
                    Text("•")
                        .font(.system(size: 6))
                        .foregroundStyle(.secondary)
                    Text(entry.subtitle)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Text(entry.message)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .lineSpacing(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
                    .font(.system(size: 18, weight: .medium))
                    .widgetAccentable()
            } else {
                VStack(spacing: 1) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13, weight: .bold))
                        .widgetAccentable()
                    Text("💌")
                        .font(.system(size: 8))
                }
            }
        }
    }
}

struct AccessoryInlineView: View {
    let entry: LoveEntry

    var body: some View {
        if entry.message.isEmpty {
            Label("Nalguitas", systemImage: "heart.fill")
        } else {
            Label {
                Text(entry.message)
                    .lineLimit(1)
            } icon: {
                Image(systemName: "heart.fill")
            }
        }
    }
}

// MARK: - Widget Router
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
        case .accessoryInline:
            AccessoryInlineView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration
struct AmorRosaWidget: Widget {
    let kind: String = "AmorRosaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LoveProvider()) { entry in
            LoveWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    ZStack {
                        // Warm gradient base
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.98, blue: 0.97),
                                Color(red: 0.99, green: 0.93, blue: 0.94),
                                Color(red: 0.98, green: 0.88, blue: 0.90).opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        // Subtle corner glow
                        Circle()
                            .fill(Color(red: 0.91, green: 0.58, blue: 0.65).opacity(0.08))
                            .frame(width: 120, height: 120)
                            .offset(x: 60, y: -40)
                            .blur(radius: 30)
                    }
                }
        }
        .configurationDisplayName("Nalguitas 💕")
        .description("Mensajes de amor en tu pantalla")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}
