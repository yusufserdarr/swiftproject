import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ActivityLog.date, order: .reverse) private var activities: [ActivityLog]
    
    // Group activities by date for the list
    var groupedActivities: [(date: Date, activities: [ActivityLog])] {
        let grouped = Dictionary(grouping: activities) { activity in
            Calendar.current.startOfDay(for: activity.date)
        }
        return grouped.sorted { $0.key > $1.key }
            .map { (date: $0.key, activities: $0.value) }
    }
    
    // Data for the chart (last 7 days)
    var chartData: [(date: Date, total: Double)] {
        let grouped = Dictionary(grouping: activities) { activity in
            Calendar.current.startOfDay(for: activity.date)
        }
        return grouped.map { (date, acts) in
            (date: date, total: acts.reduce(0) { $0 + $1.totalWaterLiters })
        }.sorted { $0.date < $1.date }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if activities.isEmpty {
                    ContentUnavailableView(
                        "Henüz Veri Yok",
                        systemImage: "chart.bar",
                        description: Text("İstatistikleri görmek için aktivite ekleyin.")
                    )
                } else {
                    List {
                        Section(header: Text("Günlük Tüketim Grafiği")) {
                            Chart(chartData, id: \.date) { item in
                                BarMark(
                                    x: .value("Tarih", item.date, unit: .day),
                                    y: .value("Litre", item.total)
                                )
                                .foregroundStyle(Color.blue.gradient)
                            }
                            .frame(height: 250)
                            .padding(.vertical)
                        }
                        
                        ForEach(groupedActivities, id: \.date) { group in
                            Section(header: Text(group.date.formatted(date: .abbreviated, time: .omitted))) {
                                ForEach(group.activities) { activity in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(activity.name)
                                                .font(.headline)
                                            Text(activity.date.formatted(date: .omitted, time: .shortened))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(String(format: "%.1f L", activity.totalWaterLiters))
                                            .bold()
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .onDelete { indexSet in
                                    deleteItems(at: indexSet, in: group.activities)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("İstatistikler")
        }
    }
    
    private func deleteItems(at offsets: IndexSet, in sectionActivities: [ActivityLog]) {
        withAnimation {
            for index in offsets {
                let activityToDelete = sectionActivities[index]
                modelContext.delete(activityToDelete)
            }
        }
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: ActivityLog.self, inMemory: true)
}
