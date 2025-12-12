//
//  SuIzimWidget.swift
//  SuIzimWidget
//

import WidgetKit
import SwiftUI

// MARK: - Data Manager
class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let suiteName = "group.com.serdaroglu.suizim"
    private let userDefaults: UserDefaults?
    
    private init() {
        userDefaults = UserDefaults(suiteName: suiteName)
    }
    
    var reservoirRate: Double {
        let rate = userDefaults?.double(forKey: "reservoirRate") ?? 0.0
        return rate > 0 ? rate : 67.5 // Default value if not set
    }
    
    var selectedCity: String {
        userDefaults?.string(forKey: "selectedCity") ?? "İstanbul"
    }
    
    var dailyFootprint: Double {
        userDefaults?.double(forKey: "dailyFootprint") ?? 0.0
    }
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), rate: 67.5, city: "İstanbul", footprint: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let data = WidgetDataManager.shared
        let entry = SimpleEntry(
            date: Date(),
            rate: data.reservoirRate,
            city: data.selectedCity,
            footprint: data.dailyFootprint
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let data = WidgetDataManager.shared
        let entry = SimpleEntry(
            date: Date(),
            rate: data.reservoirRate,
            city: data.selectedCity,
            footprint: data.dailyFootprint
        )
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry
struct SimpleEntry: TimelineEntry {
    let date: Date
    let rate: Double
    let city: String
    let footprint: Double
}

// MARK: - Widget View
struct SuIzimWidgetEntryView: View {
    var entry: Provider.Entry
    
    var rateColor: Color {
        if entry.rate >= 70 { return .green }
        else if entry.rate >= 40 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundStyle(.blue)
                    .font(.caption)
                Text("Baraj Doluluk")
                    .font(.caption2)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Circular Progress
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: min(entry.rate / 100, 1.0))
                    .stroke(rateColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(Int(entry.rate))")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 60, height: 60)
            
            // City & Footprint
            VStack(spacing: 2) {
                Text(entry.city)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if entry.footprint > 0 {
                    Text("💧 \(Int(entry.footprint))L bugün")
                        .font(.system(size: 9))
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(12)
    }
}

// MARK: - Widget Definition
struct SuIzimWidget: Widget {
    let kind: String = "SuIzimWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SuIzimWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Su İzim")
        .description("Baraj doluluk oranı ve günlük su kullanımı")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    SuIzimWidget()
} timeline: {
    SimpleEntry(date: .now, rate: 67.5, city: "İstanbul", footprint: 125)
}
