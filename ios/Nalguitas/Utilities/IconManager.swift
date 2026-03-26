import SwiftUI
import Combine

public enum AppIcon: String, CaseIterable, Identifiable {
    case primary = "AppIcon" // Default
    case midnight = "AppIconMidnight" // Dark mode stealth
    case ruby = "AppIconRuby" // Bright red intense
    case gold = "AppIconGold" // Premium VIP
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .primary: return "Nalguitas"
        case .midnight: return "Medianoche"
        case .ruby: return "Pasión Rubí"
        case .gold: return "Dorado VIP"
        }
    }
}

public class IconManager: ObservableObject {
    @Published public var currentIcon: AppIcon = .primary
    
    public init() {
        if let altName = UIApplication.shared.alternateIconName {
            currentIcon = AppIcon(rawValue: altName) ?? .primary
        }
    }
    
    public func setIcon(_ icon: AppIcon) {
        let name = icon == .primary ? nil : icon.rawValue
        
        guard UIApplication.shared.alternateIconName != name else { return }
        
        UIApplication.shared.setAlternateIconName(name) { [weak self] error in
            if let error = error {
                print("Error setting alternate app icon: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self?.currentIcon = icon
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            }
        }
    }
}
