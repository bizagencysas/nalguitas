import SwiftUI

struct NotificationBellView: View {
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.meshBackground
                
                if isLoading {
                    ProgressView()
                        .tint(Theme.rosePrimary)
                } else if notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundStyle(Theme.roseLight)
                        Text("No hay notificaciones")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(notifications) { notif in
                                notificationRow(notif)
                            }
                        }
                        .padding(16)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if !notifications.isEmpty {
                        Button {
                            Task { await markAllAsRead() }
                        } label: {
                            Text("Marcar todas")
                                .font(.system(.caption, weight: .semibold, design: .rounded))
                                .foregroundStyle(Theme.rosePrimary)
                        }
                    }
                }
            }
            .task { await loadNotifications() }
        }
    }
    
    private func notificationRow(_ notif: AppNotification) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(notif.isRead ? Theme.roseLight.opacity(0.3) : Theme.rosePrimary.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: iconForType(notif.type))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(notif.isRead ? Theme.textSecondary : Theme.rosePrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notif.title)
                    .font(.system(.subheadline, weight: notif.isRead ? .regular : .semibold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                
                if !notif.body.isEmpty {
                    Text(notif.body)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
                
                Text(notif.timeAgo)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            if !notif.isRead {
                Circle()
                    .fill(Theme.rosePrimary)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(12)
        .background {
            if notif.isRead {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.clear)
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
        }
    }
    
    private func iconForType(_ type: String) -> String {
        switch type {
        case "chat": return "bubble.left.and.bubble.right.fill"
        case "message": return "heart.text.clipboard"
        case "gift": return "gift.fill"
        case "experience": return "star.fill"
        case "points": return "dollarsign.circle.fill"
        default: return "bell.fill"
        }
    }
    
    private func loadNotifications() async {
        isLoading = true
        defer { isLoading = false }
        notifications = (try? await APIService.shared.fetchNotifications()) ?? buildLocalNotifications()
    }
    
    private func markAllAsRead() async {
        // Mark all as read locally
        for i in notifications.indices {
            notifications[i].isRead = true
        }
        // Try to mark on server
        try? await APIService.shared.markAllNotificationsRead()
    }
    
    /// Builds notifications from local data when API endpoint doesn't exist
    private func buildLocalNotifications() -> [AppNotification] {
        // Build from cached chat messages
        let cached = ChatCache.load()
        let isAdmin = UserDefaults.standard.bool(forKey: "isAdminDevice")
        let mySender = isAdmin ? "admin" : "girlfriend"
        
        let unread = cached.suffix(20).filter { $0.sender != mySender }
        return unread.suffix(10).reversed().map { msg in
            AppNotification(
                id: msg.id,
                type: "chat",
                title: isAdmin ? "Tucancita" : "Isacc",
                body: msg.type == "image" ? "📷 Envió una foto" : msg.type == "video" ? "🎥 Envió un video" : msg.type == "sticker" ? "🎨 Envió un sticker" : msg.content,
                isRead: msg.seen ?? false,
                createdAt: msg.createdAt ?? "",
                timeAgo: formatTimeAgo(msg.createdAt)
            )
        }
    }
    
    private func formatTimeAgo(_ dateStr: String?) -> String {
        guard let str = dateStr else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: str) ?? ISO8601DateFormatter().date(from: str) else { return "" }
        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "Ahora" }
        if diff < 3600 { return "Hace \(Int(diff/60))m" }
        if diff < 86400 { return "Hace \(Int(diff/3600))h" }
        return "Hace \(Int(diff/86400))d"
    }
}

struct AppNotification: Identifiable {
    let id: String
    let type: String
    let title: String
    let body: String
    var isRead: Bool
    let createdAt: String
    let timeAgo: String
}
