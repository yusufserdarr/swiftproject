/*
import Foundation

struct WaterCalculator {
    // Ortalama su tüketim değerleri (Litre cinsinden)
    // Kaynak: Genel kabul görmüş ortalama değerler
    static let activityRates: [String: Double] = [
        "Duş": 12.0, // Dakika başına
        "Diş Fırçalama": 6.0, // Dakika başına (musluk açıksa)
        "Bulaşık (Elde)": 100.0, // Yıkama başına
        "Bulaşık (Makine)": 12.0, // Yıkama başına
        "Çamaşır Makinesi": 50.0, // Yıkama başına
        "Sifon": 9.0, // Basış başına
        "El Yıkama": 3.0, // Yıkama başına
        "Araba Yıkama": 200.0, // Yıkama başına
        "Prompt": 4.5 //Prompt başına
    ]
    static let orderedActivities: [String] = [
            "Prompt",
            "Duş",                    // En sık yapılan en üstte
            "Sifon",
            "Bulaşık (Elde)",
            "Bulaşık (Makine)",
            "Çamaşır Makinesi",
            "Araba Yıkama"            // En az yapılan en altta
        ]
    
    static func calculateWaterUsage(activityName: String, amount: Double) -> Double {
        guard let rate = activityRates[activityName] else { return 0.0 }
        return rate * amount
    }
}
*/
/* import Foundation

struct WaterCalculator {
    
    // --- NE YAPTIN (Musluktan akanlar) ---
    static let homeActivities: [String: Double] = [
        "Duş": 12.0,
        "Sıcak Su Bekleme": 10.0,
        "Diş Fırçalama (Musluk Açık)": 6.0,
        "El Yıkama": 3.0,
        "Tıraş Olma (Musluk Açık)": 10.0,
        "Sifon": 9.0,
        "Bulaşık Makinesi": 12.0,
        "Bulaşık (Elde)": 100.0,
        "Çamaşır Makinesi": 45.0,
        "Balkon Yıkama (Hortumla)": 20.0,
        "Araba Yıkama": 200.0,
        "Bahçe Sulama": 18.0
    ]
    
    // --- NE TÜKETTİN (Yediğimiz, giydiğimiz şeyler) ---
    static let virtualActivities: [String: Double] = [
        "Hamburger": 2400.0,
        "Sığır Eti (1 Porsiyon)": 4500.0,
        "Tavuk Eti (1 Porsiyon)": 1100.0,
        "Çikolata (1 Paket)": 1700.0,
        "Kahve (1 Fincan)": 132.0,
        "Çay (1 Bardak)": 27.0,
        "Süt (1 Bardak)": 200.0,
        "Peynir (1 Dilim)": 100.0,
        "Yumurta (1 Adet)": 196.0,
        "Ekmek (1 Dilim)": 40.0,
        "Elma (1 Adet)": 82.0,
        "Muz (1 Adet)": 160.0,
        "Portakal (1 Adet)": 80.0,
        "Domates (1 Adet)": 13.0,
        "Patates (1 Adet)": 25.0,
        "Pirinç Pilavı (1 Porsiyon)": 300.0,
        "Makarna (1 Porsiyon)": 200.0,
        "Pizza (1 Dilim)": 1200.0,
        "Tişört (Pamuklu)": 2500.0,
        "Kot Pantolon": 10850.0,
        "Deri Ayakkabı": 13700.0,
        "Kağıt (A4 - 1 Sayfa)": 10.0
    ]
    
    static func calculateWaterUsage(activityName: String, amount: Double) -> Double {
        if let rate = homeActivities[activityName] { return rate * amount }
        if let rate = virtualActivities[activityName] { return rate * amount }
        return 0.0
    }
} */

        // Yoksa sanal listeye bak
import Foundation

struct WaterCalculator {
    
    // --- EV / MUSLUK (Musluktan akanlar) ---
    static let homeActivities: [String: Double] = [
        "Duş": 12.0,
        "Sıcak Su Bekleme": 10.0,
        "Diş Fırçalama (Musluk Açık)": 6.0,
        "El Yıkama": 3.0,
        "Tıraş Olma (Musluk Açık)": 10.0,
        "Sifon": 9.0,
        "Bulaşık Makinesi": 12.0,
        "Bulaşık (Elde)": 100.0,
        "Çamaşır Makinesi": 45.0,
        "Balkon Yıkama (Hortumla)": 20.0,
        "Araba Yıkama": 200.0,
        "Bahçe Sulama": 18.0,
        "Prompt" : 4.5
    ]
    
    // --- SANAL SU (Yediğimiz, giydiğimiz şeyler) ---
    static let virtualActivities: [String: Double] = [
        "Hamburger": 2400.0,
        "Sığır Eti (1 Porsiyon)": 4500.0,
        "Tavuk Eti (1 Porsiyon)": 1100.0,
        "Çikolata (1 Paket)": 1700.0,
        "Kahve (1 Fincan)": 132.0,
        "Çay (1 Bardak)": 27.0,
        "Süt (1 Bardak)": 200.0,
        "Peynir (1 Dilim)": 100.0,
        "Yumurta (1 Adet)": 196.0,
        "Ekmek (1 Dilim)": 40.0,
        "Elma (1 Adet)": 82.0,
        "Muz (1 Adet)": 160.0,
        "Portakal (1 Adet)": 80.0,
        "Domates (1 Adet)": 13.0,
        "Patates (1 Adet)": 25.0,
        "Pirinç Pilavı (1 Porsiyon)": 300.0,
        "Makarna (1 Porsiyon)": 200.0,
        "Pizza (1 Dilim)": 1200.0,
        "Tişört (Pamuklu)": 2500.0,
        "Kot Pantolon": 10850.0,
        "Deri Ayakkabı": 13700.0,
        "Kağıt (A4 - 1 Sayfa)": 10.0
    ]
    
    static func calculateWaterUsage(activityName: String, amount: Double) -> Double {
        if let rate = homeActivities[activityName] { return rate * amount }
        if let rate = virtualActivities[activityName] { return rate * amount }
        return 0.0
    }
}
