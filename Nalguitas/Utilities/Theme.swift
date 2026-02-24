import SwiftUI

public enum Theme {
    // MARK: - Core Palette
    static let rosePrimary = Color(red: 0.91, green: 0.58, blue: 0.65)
    static let roseLight = Color(red: 0.98, green: 0.88, blue: 0.90)
    static let rosePale = Color(red: 0.99, green: 0.93, blue: 0.94)
    static let cream = Color(red: 0.99, green: 0.97, blue: 0.95)
    static let blush = Color(red: 0.95, green: 0.73, blue: 0.78)
    static let roseQuartz = Color(red: 0.96, green: 0.76, blue: 0.76)
    static let warmWhite = Color(red: 1.0, green: 0.98, blue: 0.97)
    static let textPrimary = Color(red: 0.30, green: 0.20, blue: 0.22)
    static let textSecondary = Color(red: 0.55, green: 0.42, blue: 0.45)
    
    // MARK: - Sent Bubble (rose glass)
    static let sentBubble = LinearGradient(
        colors: [
            Color(red: 0.91, green: 0.58, blue: 0.65),
            Color(red: 0.88, green: 0.52, blue: 0.60)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Received Bubble (frosted glass)
    static let receivedBubble = Color(red: 0.97, green: 0.95, blue: 0.96)
    
    // MARK: - Chat adaptive colors
    static let chatSentBubble = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.75, green: 0.35, blue: 0.45, alpha: 1.0)
            : UIColor(red: 0.91, green: 0.58, blue: 0.65, alpha: 1.0)
    })
    
    static let chatSentBubbleEnd = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.65, green: 0.28, blue: 0.40, alpha: 1.0)
            : UIColor(red: 0.85, green: 0.50, blue: 0.58, alpha: 1.0)
    })
    
    static let chatReceivedBubble = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1.0)
            : UIColor(red: 0.97, green: 0.95, blue: 0.96, alpha: 1.0)
    })
    
    static let chatBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.08, green: 0.07, blue: 0.08, alpha: 1.0)
            : UIColor(red: 1.0, green: 0.98, blue: 0.97, alpha: 1.0)
    })
    
    static let chatInputBackground = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.14, green: 0.13, blue: 0.15, alpha: 1.0)
            : UIColor(red: 0.96, green: 0.94, blue: 0.95, alpha: 1.0)
    })

    // MARK: - Gradients
    static let backgroundGradient = LinearGradient(
        colors: [warmWhite, rosePale, roseLight.opacity(0.3)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [Color.white, rosePale.opacity(0.5)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [rosePrimary, blush],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Glass Card Style
    static func glassCard(cornerRadius: CGFloat = 24) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .shadow(color: rosePrimary.opacity(0.08), radius: 16, y: 6)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), roseLight.opacity(0.3), .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
    }

    // MARK: - Mesh Background
    static var meshBackground: some View {
        AnimatedMeshBackground()
    }
}

// MARK: - Animated Mesh Background
struct AnimatedMeshBackground: View {
    @State private var t: Float = 0.0
    @State private var timer: Timer?

    var body: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5 + 0.1 * sin(t), 0.5 + 0.1 * cos(t)], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                Theme.warmWhite, Theme.rosePale, Theme.cream,
                Theme.rosePale, Theme.roseLight.opacity(0.4), Theme.warmWhite,
                Theme.cream, Theme.warmWhite, Theme.rosePale
            ]
        )
        .ignoresSafeArea()
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                withAnimation(.linear(duration: 0.05)) {
                    t += 0.02
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    // MARK: - Chat Background (subtle rose tint)
    static var chatMeshBackground: some View {
        ZStack {
            Color(red: 0.99, green: 0.97, blue: 0.97)
            
            // Subtle floating orbs
            Circle()
                .fill(Theme.rosePale.opacity(0.3))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: -80, y: -200)
            
            Circle()
                .fill(Theme.roseLight.opacity(0.2))
                .frame(width: 160, height: 160)
                .blur(radius: 50)
                .offset(x: 100, y: 300)
        }
        .ignoresSafeArea()
    }
}
