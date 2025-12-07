import Foundation

struct SuggestionEngine {
    static func getSuggestion(for totalWaterUsage: Double) -> String {
        switch totalWaterUsage {
        case 0..<50:
            return "Harika gidiyorsun! Su tüketimin oldukça düşük. Bu bilinci korumaya devam et."
        case 50..<100:
            return "Ortalama bir tüketimdesin. Duş süreni 1 dakika kısaltarak günde 12 litre tasarruf edebilirsin."
        case 100..<200:
            return "Su tüketimin biraz yüksek görünüyor. Bulaşıkları makinede yıkamak elde yıkamaya göre çok daha tasarrufludur."
        default:
            return "Dikkat! Su ayak izin çok yüksek. Muslukları gereksiz yere açık bırakmamaya özen göster ve su sızıntılarını kontrol et."
        }
    }
    
    static func getRandomTip() -> String {
        let tips = [
            "Diş fırçalarken musluğu kapatmak günde ortalama 15-20 litre su tasarrufu sağlar.",
            "Sebze ve meyveleri akan su altında değil, su dolu bir kapta yıkamak yılda 18 ton su kurtarabilir.",
            "Çamaşır makinesini tam doldurmadan çalıştırmamak enerji ve su tasarrufu sağlar.",
            "Damlayan bir musluk, günde yaklaşık 30-50 litre suyun boşa gitmesine neden olabilir.",
            "Duş sürenizi 5 dakikaya indirmek, kişi başı yılda ortalama 45 ton su tasarrufu demektir."
        ]
        return tips.randomElement() ?? "Su hayattır, onu koruyalım."
    }
}
