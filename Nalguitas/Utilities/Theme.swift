import SwiftUI

enum Theme {
    static let rosePrimary = Color(red: 0.91, green: 0.58, blue: 0.65)
    static let roseLight = Color(red: 0.98, green: 0.88, blue: 0.90)
    static let rosePale = Color(red: 0.99, green: 0.93, blue: 0.94)
    static let cream = Color(red: 0.99, green: 0.97, blue: 0.95)
    static let blush = Color(red: 0.95, green: 0.73, blue: 0.78)
    static let roseQuartz = Color(red: 0.96, green: 0.76, blue: 0.76)
    static let warmWhite = Color(red: 1.0, green: 0.98, blue: 0.97)
    static let textPrimary = Color(red: 0.30, green: 0.20, blue: 0.22)
    static let textSecondary = Color(red: 0.55, green: 0.42, blue: 0.45)
    
    // MARK: - Dark Mode Adaptive Chat Colors
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
            : UIColor(red: 0.94, green: 0.92, blue: 0.93, alpha: 1.0)
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

    static var meshBackground: some View {
        MeshGradient(
            width: 3, height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                warmWhite, rosePale, cream,
                rosePale, roseLight.opacity(0.4), warmWhite,
                cream, warmWhite, rosePale
            ]
        )
        .ignoresSafeArea()
    }
}
