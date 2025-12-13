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
        Achievement(
            title: "Başlangıç",
            description: "İlk verini kaydet",
            iconName: "drop.fill",
            targetValue: 1,
            type: .totalSavings
        ),
        Achievement(
            title: "Tasarruf Çırağı",
            description: "Toplam 500L su kullanımı kaydet",
            iconName: "drop.circle.fill",
            targetValue: 500,
            type: .totalSavings
        ),
        Achievement(
            title: "Su Koruyucusu",
            description: "Toplam 5000L su kullanımı kaydet",
            iconName: "shield.fill",
            targetValue: 5000,
            type: .totalSavings
        ),
        Achievement(
            title: "İstikrar",
            description: "3 gün üst üste veri gir",
            iconName: "flame.fill",
            targetValue: 3,
            type: .streak
        ),
        Achievement(
            title: "Süper Seri",
            description: "7 gün üst üste veri gir",
            iconName: "star.fill",
            targetValue: 7,
            type: .streak
        ),
        Achievement(
            title: "Hedefçi",
            description: "Bir gün 150L altında kal",
            iconName: "target",
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
        // 1. Toplam Kullanım (Total Savings mantığı yerine Toplam Kullanım Takibi olarak düşünüldü)
        // Not: Gerçek tasarruf için 'standart kullanım - benim kullanımım' gerekir ama şimdilik toplam veri girişi üzerinden gidiyoruz.
        let totalLiters = activities.reduce(0) { $0 + $1.totalWaterLiters }
        
        updateAchievement(type: .totalSavings) { achievement in
            achievement.currentValue = totalLiters
        }
        
        // 2. Seri (Streak)
        let streak = calculateStreak(activities: activities)
        updateAchievement(type: .streak) { achievement in
            achievement.currentValue = Double(streak)
        }
        
        // 3. Günlük Hedef (150L altı)
        // En az 1 gün 150L altı varsa
        let daysUnderLimit = calculateDaysUnderLimit(activities: activities)
        updateAchievement(type: .dailyLimit) { achievement in
            if daysUnderLimit > 0 {
                achievement.currentValue = 1 // Unlocked
            }
        }
        
        saveProgress()
    }
    
    private func updateAchievement(type: Achievement.AchievementType, update: (inout Achievement) -> Void) {
        for i in 0..<achievements.count {
            if achievements[i].type == type {
                update(&achievements[i])
                
                // Unlock check
                if achievements[i].currentValue >= achievements[i].targetValue {
                    achievements[i].isUnlocked = true
                }
            }
        }
    }
    
    private func calculateStreak(activities: [ActivityLog]) -> Int {
        // Basit streak hesaplama
        let sortedDates = Set(activities.map { Calendar.current.startOfDay(for: $0.date) }).sorted(by: >)
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())
        
        // Eğer bugün veri yoksa düne bak, varsa seriyi devam ettir
        if !sortedDates.contains(currentDate) {
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
        }
        
        for date in sortedDates {
            if date == currentDate {
                streak += 1
                currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        return streak
    }
    
    private func calculateDaysUnderLimit(activities: [ActivityLog]) -> Int {
        let grouped = Dictionary(grouping: activities) { Calendar.current.startOfDay(for: $0.date) }
        var count = 0
        for (_, dayActs) in grouped {
            let total = dayActs.reduce(0) { $0 + $1.totalWaterLiters }
            if total < 150 && total > 0 {
                count += 1
            }
        }
        return count
    }
    
    private func saveProgress() {
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            // Mevcut tanımları koru, sadece progressleri güncelle (yeni achievement eklenirse diye)
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
