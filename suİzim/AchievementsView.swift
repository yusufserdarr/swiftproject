import SwiftUI
import SwiftData

// MARK: - Models

struct Achievement: Identifiable, Codable {
    var id = UUID()
    let title: String
    let description: String
    let iconName: String
    let targetValue: Double // Örn: 1000 litre
    var currentValue: Double = 0.0
    var isUnlocked: Bool = false
    let type: AchievementType
    
    enum AchievementType: String, Codable {
        case totalSavings = "Tasarruf"
        case streak = "Seri"
        case dailyLimit = "Günlük Hedef"
    }
    
    var progress: Double {
        min(currentValue / targetValue, 1.0)
    }
}

// MARK: - ViewModel / Manager

@Observable
class AchievementManager {
    var achievements: [Achievement] = [
        // --- Başlangıç ---
        Achievement(
            title: "Başlangıç",
            description: "İlk verini kaydet",
            iconName: "flag.fill",
            targetValue: 1,
            type: .totalSavings // Generic type usage
        ),
        Achievement(
            title: "Tasarruf Çırağı",
            description: "Toplam 500L su kullanımı kaydet",
            iconName: "drop.circle.fill",
            targetValue: 500,
            type: .totalSavings
        ),
        
        // --- Alışkanlık ---
        Achievement(
            title: "Barista Diyeti",
            description: "3 gün üst üste kahve içme",
            iconName: "cup.and.saucer.fill",
            targetValue: 3,
            type: .streak
        ),
        Achievement(
            title: "Yeşil Dostu",
            description: "Bugün hiç et yemedin!",
            iconName: "leaf.fill",
            targetValue: 1,
            type: .dailyLimit
        ),
        Achievement(
            title: "Eski Toprak",
            description: "30 gündür kıyafet almadın",
            iconName: "tshirt.fill",
            targetValue: 30,
            type: .streak
        ),
        
        // --- Zorlu ---
        Achievement(
            title: "Çöl Bedevisi",
            description: "Günlük tüketim 80L altında",
            iconName: "sun.max.fill",
            targetValue: 1,
            type: .dailyLimit
        ),
        Achievement(
            title: "Hızlı Duşçu",
            description: "4 dakikadan kısa duş aldın",
            iconName: "timer",
            targetValue: 1,
            type: .dailyLimit
        ),
        
        // --- Eğlence ---
        Achievement(
            title: "Erkenci Kuş",
            description: "07:00 - 09:00 arası veri girişi",
            iconName: "sunrise.fill",
            targetValue: 1,
            type: .dailyLimit
        ),
        Achievement(
            title: "Gece Bekçisi",
            description: "00:00 - 03:00 arası veri girişi",
            iconName: "moon.stars.fill",
            targetValue: 1,
            type: .dailyLimit
        )
    ]
    
    // UserDefaults key
    private let saveKey = "SavedAchievements"
    
    init() {
        loadProgress()
    }
    
    func updateProgress(activities: [ActivityLog]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayActivities = activities.filter { calendar.isDateInToday($0.date) }
        
        // 1. Toplam Veri (Başlangıç & Çırak)
        let totalLogs = Double(activities.count)
        updateAchievement(title: "Başlangıç", current: totalLogs) // Basit count
        
        let totalLiters = activities.reduce(0) { $0 + $1.totalWaterLiters }
        updateAchievement(title: "Tasarruf Çırağı", current: totalLiters)
        
        // 2. Barista Diyeti (Son 3 günde kahve yok)
        // Logic: Son 3 günü tarar, kahve varsa sıfırlar, yoksa 3 olur.
        let coffeeFreeStreak = calculateCoffeeFreeStreak(activities: activities)
        updateAchievement(title: "Barista Diyeti", current: Double(coffeeFreeStreak))
        
        // 3. Yeşil Dostu (Bugün et yok)
        let meatFree = !todayActivities.contains { isMeat($0.name) } && !todayActivities.isEmpty
        updateAchievement(title: "Yeşil Dostu", current: meatFree ? 1 : 0)
        
        // 4. Eski Toprak (Son 30 gün kıyafet yok)
        let shopFreeDays = calculateShoppingFreeDays(activities: activities)
        updateAchievement(title: "Eski Toprak", current: Double(shopFreeDays))
        
        // 5. Çöl Bedevisi (Bugün < 80L)
        let todayTotal = todayActivities.reduce(0) { $0 + $1.totalWaterLiters }
        let desertMode = todayTotal > 0 && todayTotal < 80
        updateAchievement(title: "Çöl Bedevisi", current: desertMode ? 1 : 0)
        
        // 6. Hızlı Duşçu (Duş < 4dk)
        let fastShower = activities.contains { $0.name == "Duş" && $0.amount < 4 }
        updateAchievement(title: "Hızlı Duşçu", current: fastShower ? 1 : 0)
        
        // 7. Erkenci Kuş (07-09)
        let earlyBird = activities.contains {
            let hour = calendar.component(.hour, from: $0.date)
            return hour >= 7 && hour < 9
        }
        updateAchievement(title: "Erkenci Kuş", current: earlyBird ? 1 : 0)
        
        // 8. Gece Bekçisi (00-03)
        let nightOwl = activities.contains {
            let hour = calendar.component(.hour, from: $0.date)
            return hour >= 0 && hour < 3
        }
        updateAchievement(title: "Gece Bekçisi", current: nightOwl ? 1 : 0)
        
        saveProgress()
    }
    
    private func updateAchievement(title: String, current: Double) {
        if let index = achievements.firstIndex(where: { $0.title == title }) {
            // Sadece artış varsa güncelle (Progress düşmesi moral bozmasın diye genelde Max tutulur, ama streak bozulabilir)
            // Streak türü hariç diğerlerinde Max tutalım.
            // Ama burada basitçe overwrite yapıyoruz, Streak bozulursa 0 olur.
            achievements[index].currentValue = current
            if achievements[index].currentValue >= achievements[index].targetValue {
                achievements[index].isUnlocked = true
            }
        }
    }
    
    // --- Helpers ---
    
    private func isMeat(_ name: String) -> Bool {
        let meats = ["Hamburger", "Sığır", "Tavuk", "Kebap", "Et", "Sucuk", "Salam"]
        return meats.contains { name.contains($0) }
    }
    
    private func isClothing(_ name: String) -> Bool {
        let clothes = ["Tişört", "Pantolon", "Ayakkabı", "Gömlek", "Kazak"]
        return clothes.contains { name.contains($0) }
    }
    
    private func calculateCoffeeFreeStreak(activities: [ActivityLog]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        
        // Son 3 günü kontrol et
        for i in 0..<3 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let daysActs = activities.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let drankCoffee = daysActs.contains { $0.name.contains("Kahve") }
            
            if !drankCoffee {
                streak += 1
            } else {
                streak = 0 // Kahve içildiyse seri bozulur (son günden başladığımız için direkt 0 diyebiliriz veya zinciri kirar)
                // Ama "3 gün üst üste" mantığı için: Son 3 günün hepsinde içilmediyse kazanır.
                // Eğer bugün içtiyse streak 0. Dün içtiyse streak 0.
                // Burada basitçe: Bugün, Dün, Önceki Gün check ediyoruz.
                return 0 
            }
        }
        return streak
    }
    
    private func calculateShoppingFreeDays(activities: [ActivityLog]) -> Int {
        guard !activities.isEmpty else { return 0 } // Hiç aktivite yoksa 0
        
        // En eski aktivite tarihine bak
        // Eğer kullanıcı uygulamayı 30 gündür kullanmıyorsa bu başarım kazanılamaz.
        guard let firstActivityDate = activities.map({ $0.date }).min() else { return 0 }
        let daysSinceStart = Calendar.current.dateComponents([.day], from: firstActivityDate, to: Date()).day ?? 0
        
        if daysSinceStart < 30 {
            // Henüz 30 gündür kullanmıyor
            return daysSinceStart
        }
        
        // En son alışveriş tarihini bul
        let shoppings = activities.filter { isClothing($0.name) }
        guard let lastShop = shoppings.map({ $0.date }).max() else {
            // Hiç alışveriş yoksa ve 30 gündür kullanıyorsa
            return daysSinceStart
        }
        
        let daysSinceShop = Calendar.current.dateComponents([.day], from: lastShop, to: Date()).day ?? 0
        return daysSinceShop
    }
    
    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            for savedAch in decoded {
                if let index = achievements.firstIndex(where: { $0.title == savedAch.title }) {
                    achievements[index].currentValue = savedAch.currentValue
                    achievements[index].isUnlocked = savedAch.isUnlocked
                }
            }
        }
    }
}

// MARK: - View

struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activities: [ActivityLog]
    @State private var manager = AchievementManager()
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Status
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Toplam Başarım")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("\(manager.achievements.filter(\.isUnlocked).count) / \(manager.achievements.count)")
                                .font(.title2)
                                .bold()
                        }
                        Spacer()
                        CircularProgressView(progress: Double(manager.achievements.filter(\.isUnlocked).count) / Double(manager.achievements.count))
                            .frame(width: 50, height: 50)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(manager.achievements) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Başarılar")
            .onAppear {
                manager.updateProgress(activities: activities)
            }
            .onChange(of: activities) {
                manager.updateProgress(activities: activities)
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.iconName)
                    .font(.title)
                    .foregroundStyle(achievement.isUnlocked ? Color.blue : Color.gray)
            }
            .grayscale(achievement.isUnlocked ? 0 : 1.0)
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(achievement.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 30) // Fixed height for alignment
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 6)
                        .opacity(0.1)
                        .foregroundColor(.gray)
                    
                    Rectangle()
                        .frame(width: min(CGFloat(achievement.progress) * geometry.size.width, geometry.size.width), height: 6)
                        .foregroundColor(achievement.isUnlocked ? .green : .blue)
                }
                .cornerRadius(3)
            }
            .frame(height: 6)
            
            if achievement.isUnlocked {
                Text("KAZANILDI")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.green)
                    .padding(.top, 2)
            } else {
                Text("\(Int(achievement.currentValue)) / \(Int(achievement.targetValue))")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.gray.opacity(0.2),
                    lineWidth: 6
                )
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.blue,
                    style: StrokeStyle(
                        lineWidth: 6,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
        }
    }
}

#Preview {
    AchievementsView()
        .modelContainer(for: ActivityLog.self, inMemory: true)
}
