import SwiftUI
import SwiftData
import Charts
import WidgetKit

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivityLog.date, order: .reverse) private var activities: [ActivityLog]
    
    @State private var selectedPeriod: TimePeriod = .week
    
    enum TimePeriod: String, CaseIterable {
        case day = "Gün"
        case week = "Hafta"
        case month = "Ay"
    }
    
    // MARK: - Computed Data
    
    var last7DaysData: [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayActivities = activities.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let total = dayActivities.reduce(0) { $0 + $1.totalWaterLiters }
            return (date: date, total: total)
        }
    }
    
    var last30DaysData: [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<30).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayActivities = activities.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let total = dayActivities.reduce(0) { $0 + $1.totalWaterLiters }
            return (date: date, total: total)
        }
    }
    
    var todayData: [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayActivities = activities.filter { calendar.isDate($0.date, inSameDayAs: today) }
        let total = todayActivities.reduce(0) { $0 + $1.totalWaterLiters }
        return [(date: today, total: total)]
    }
    
    var todayActivities: [ActivityLog] {
        let calendar = Calendar.current
        return activities.filter { calendar.isDateInToday($0.date) }
    }
    
    var chartData: [(date: Date, total: Double)] {
        switch selectedPeriod {
        case .day: return todayData
        case .week: return last7DaysData
        case .month: return last30DaysData
        }
    }
    
    // Statistics
    var totalUsage: Double {
        chartData.reduce(0) { $0 + $1.total }
    }
    
    var averageDaily: Double {
        let activeDays = chartData.filter { $0.total > 0 }.count
        return activeDays > 0 ? totalUsage / Double(activeDays) : 0
    }
    
    var maxDay: (date: Date, total: Double)? {
        chartData.max(by: { $0.total < $1.total })
    }
    
    var comparisonPercent: Double {
        let currentTotal = last7DaysData.reduce(0) { $0 + $1.total }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let previous7DaysTotal = (7..<14).reduce(0.0) { result, daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let dayActivities = activities.filter { calendar.isDate($0.date, inSameDayAs: date) }
            return result + dayActivities.reduce(0) { $0 + $1.totalWaterLiters }
        }
        
        guard previous7DaysTotal > 0 else { return 0 }
        return ((currentTotal - previous7DaysTotal) / previous7DaysTotal) * 100
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if activities.isEmpty {
                        ContentUnavailableView(
                            "Henüz Veri Yok",
                            systemImage: "chart.bar",
                            description: Text("İstatistikleri görmek için aktivite ekleyin.")
                        )
                        .frame(height: 400)
                    } else {
                        // Period Picker
                        Picker("Dönem", selection: $selectedPeriod) {
                            ForEach(TimePeriod.allCases, id: \.self) { period in
                                Text(period.rawValue).tag(period)
                            }
                        }
                        .pickerStyle(.segmented)
                        .listRowSeparator(.hidden)
                        .padding(.bottom, 10)
                        
                        // Summary Cards
                        summaryCardsView
                            .listRowInsets(EdgeInsets()) // Full width for scroll view
                            .listRowSeparator(.hidden)
                        
                        // Main Chart
                        chartView
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 10)
                    }
                }
                .listRowBackground(Color.clear)
                
                if !activities.isEmpty {
                    activityListSection
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("İstatistikler")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Summary Cards
    
    private var summaryCardsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Toplam",
                    value: String(format: "%.0f L", totalUsage),
                    icon: "drop.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Günlük Ort.",
                    value: String(format: "%.0f L", averageDaily),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .cyan
                )
                
                if let max = maxDay, max.total > 0 {
                    StatCard(
                        title: "En Yüksek",
                        value: String(format: "%.0f L", max.total),
                        subtitle: max.date.formatted(.dateTime.weekday(.abbreviated)),
                        icon: "arrow.up.circle.fill",
                        color: .orange
                    )
                }
                
                if selectedPeriod == .week && comparisonPercent != 0 {
                    StatCard(
                        title: "Geçen Hafta",
                        value: String(format: "%+.0f%%", comparisonPercent),
                        icon: comparisonPercent > 0 ? "arrow.up.right" : "arrow.down.right",
                        color: comparisonPercent > 0 ? .red : .green
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Chart View
    
    private var chartView: some View {
        VStack(alignment: .leading, spacing: 12) {
            let chartTitle: String = {
                switch selectedPeriod {
                case .day: return "Bugün"
                case .week: return "Son 7 Gün"
                case .month: return "Son 30 Gün"
                }
            }()
            
            Text(chartTitle)
                .font(.headline)
                .padding(.horizontal)
            
            if selectedPeriod == .day {
                // Günlük görünüm - büyük sayı göster
                VStack(spacing: 8) {
                    Text(String(format: "%.0f", totalUsage))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    Text("Litre bugün kullanıldı")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                Chart(chartData, id: \.date) { item in
                    if selectedPeriod == .week {
                        BarMark(
                            x: .value("Tarih", item.date, unit: .day),
                            y: .value("Litre", item.total)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(6)
                    } else {
                        LineMark(
                            x: .value("Tarih", item.date, unit: .day),
                            y: .value("Litre", item.total)
                        )
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Tarih", item.date, unit: .day),
                            y: .value("Litre", item.total)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
            .chartXAxis {
                if selectedPeriod == .week {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                    }
                } else {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)L")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 220)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 10)
            .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Activity List Section
    
    private var activityListSection: some View {
        Section(header: Text(selectedPeriod == .day ? "Bugünkü Aktiviteler" : "Son Aktiviteler")) {
            let displayActivities = selectedPeriod == .day ? todayActivities : Array(activities.prefix(15))
            
            if displayActivities.isEmpty {
                Text("Henüz aktivite eklenmemiş")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(displayActivities) { activity in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activity.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(activity.date.formatted(.dateTime.day().month().hour().minute()))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(format: "%.0f L", activity.totalWaterLiters))
                            .font(.subheadline)
                            .bold()
                            .foregroundStyle(.blue)
                    }
                }
                .onDelete { indexSet in
                    // `displayActivities` üzerinden silme işlemi, ana array için index bulmalıyız
                    // Ancak onDelete, ForEach'in kullandığı collection üzerindeki indexSet'i verir.
                    // Burada `displayActivities` computed bir array olduğu için doğrudan silinemez.
                    // Bu yüzden activity nesnesini bulup context'ten silmeliyiz.
                    
                    for index in indexSet {
                        if index < displayActivities.count {
                             let activityToDelete = displayActivities[index]
                             deleteActivity(activityToDelete)
                        }
                    }
                }
            }
        }
    }
    
    private func deleteActivity(_ activity: ActivityLog) {
        withAnimation {
            modelContext.delete(activity)
            try? modelContext.save()
        }
        
        // Update widget if the deleted activity was from today
        if Calendar.current.isDateInToday(activity.date) {
            updateWidgetData()
        }
    }
    
    private func updateWidgetData() {
        Task {
            // Fetch fresh data to ensure accurate total
            do {
                let descriptor = FetchDescriptor<ActivityLog>()
                let allActivities = try modelContext.fetch(descriptor)
                
                let calendar = Calendar.current
                let todayActivities = allActivities.filter { calendar.isDateInToday($0.date) }
                let total = todayActivities.reduce(0) { $0 + $1.totalWaterLiters }
                
                print("Widget updated after delete. New total: \(total)")
                SharedDataManager.shared.saveDailyFootprint(total)
                WidgetCenter.shared.reloadTimelines(ofKind: "SuIzimWidget")
            } catch {
                print("Failed to update widget: \(error)")
            }
        }
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .bold()
                .foregroundStyle(color)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 100, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: ActivityLog.self, inMemory: true)
}
