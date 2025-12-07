import Foundation

struct WaterCalculator {
    // Ortalama su tüketim değerleri (Litre cinsinden)
    // Kaynak: Genel kabul görmüş ortalama değerler
    static let activityRates: [String: Double] = [
        "Duş": 12.0, // Dakika başına
        "Diş Fırçalama": 6.0, // Dakika başına (musluk açıksa)
        "Bulaşık (Elde)": 100.0, // Yıkama başına
        "Bulaşık (Makine)": 12.0, // Yıkama başına
        "Çamaşır (Makine)": 50.0, // Yıkama başına
        "Sifon": 9.0, // Basış başına
        "El Yıkama": 3.0, // Yıkama başına
        "Araba Yıkama": 200.0 // Yıkama başına
    ]
    
    static func calculateWaterUsage(activityName: String, amount: Double) -> Double {
        guard let rate = activityRates[activityName] else { return 0.0 }
        return rate * amount
    }
}
