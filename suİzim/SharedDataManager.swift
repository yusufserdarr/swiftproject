import Foundation

/// Shared data manager for communication between main app and widget
/// Uses App Groups to share UserDefaults
class SharedDataManager {
    static let shared = SharedDataManager()
    
    private let suiteName = "group.com.serdaroglu.suizim"
    private let userDefaults: UserDefaults?
    
    // Keys
    private let reservoirRateKey = "reservoirRate"
    private let selectedCityKey = "selectedCity"
    private let dailyFootprintKey = "dailyFootprint"
    private let lastUpdateKey = "lastUpdate"
    
    private init() {
        userDefaults = UserDefaults(suiteName: suiteName)
    }
    
    // MARK: - Reservoir Data
    
    var reservoirRate: Double {
        get { userDefaults?.double(forKey: reservoirRateKey) ?? 0.0 }
        set { userDefaults?.set(newValue, forKey: reservoirRateKey) }
    }
    
    var selectedCity: String {
        get { userDefaults?.string(forKey: selectedCityKey) ?? "İstanbul" }
        set { userDefaults?.set(newValue, forKey: selectedCityKey) }
    }
    
    // MARK: - Water Footprint
    
    var dailyFootprint: Double {
        get { userDefaults?.double(forKey: dailyFootprintKey) ?? 0.0 }
        set { userDefaults?.set(newValue, forKey: dailyFootprintKey) }
    }
    
    var lastUpdate: Date? {
        get { userDefaults?.object(forKey: lastUpdateKey) as? Date }
        set { userDefaults?.set(newValue, forKey: lastUpdateKey) }
    }
    
    // MARK: - Convenience Methods
    
    func saveReservoirData(rate: Double, city: String) {
        reservoirRate = rate
        selectedCity = city
        lastUpdate = Date()
    }
    
    func saveDailyFootprint(_ footprint: Double) {
        dailyFootprint = footprint
        lastUpdate = Date()
    }
}
