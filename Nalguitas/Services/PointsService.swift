import Foundation

@MainActor
class PointsService {
    static let shared = PointsService()
    
    private let userDefaultsKey = "nalguitas_daily_points_date"
    
    private init() {}
    
    /// Award 1 point for an app action (only for girlfriend)
    func awardPoint(reason: String) async {
        let isAdmin = UserDefaults.standard.bool(forKey: "isAdminDevice")
        guard !isAdmin else { return } // Only girlfriend earns points
        
        let username = "girlfriend"
        try? await APIService.shared.addPoints(username: username, points: 1, reason: reason)
    }
    
    /// Award point for daily app open (max once per day)
    func awardDailyOpenPoint() async {
        let isAdmin = UserDefaults.standard.bool(forKey: "isAdminDevice")
        guard !isAdmin else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let lastAwardDate = UserDefaults.standard.object(forKey: userDefaultsKey) as? Date
        
        if let last = lastAwardDate, Calendar.current.isDate(last, inSameDayAs: today) {
            return // Already awarded today
        }
        
        UserDefaults.standard.set(today, forKey: userDefaultsKey)
        try? await APIService.shared.addPoints(username: "girlfriend", points: 1, reason: "Abrió la app 📱")
    }
}
