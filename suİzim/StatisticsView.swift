import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivityLog.date, order: .reverse) private var activities: [ActivityLog]
    
    @State private var selectedPeriod: TimePeriod = .week
    
    enum TimePeriod: String, CaseIterable {
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
    
    var chartData: [(date: Date, total: Double)] {
        selectedPeriod == .week ? last7DaysData : last30DaysData
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
            ScrollView {
                VStack(spacing: 20) {
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
                        .padding(.horizontal)
                        
                        // Summary Cards
                        summaryCardsView
                        
                        // Main Chart
                        chartView
                        
                        // Activity List
                        activityListView
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("İstatistikler")
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
            Text(selectedPeriod == .week ? "Son 7 Gün" : "Son 30 Gün")
                .font(.headline)
                .padding(.horizontal)
            
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
    
    // MARK: - Activity List
    
    private var activityListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Son Aktiviteler")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(activities.prefix(10)) { activity in
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
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
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
