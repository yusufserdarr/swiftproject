//
//  SuIzimWidget.swift
//  SuIzimWidget
//

import WidgetKit
import SwiftUI
import Charts

// MARK: - Models
struct DailyUsage: Codable, Identifiable {
    var id: Date { date }
    let date: Date
    let totalLiters: Double
    let weekday: String
}

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
    
    var weeklyHistory: [DailyUsage] {
        guard let data = userDefaults?.data(forKey: "weeklyHistory"),
              let decoded = try? JSONDecoder().decode([DailyUsage].self, from: data) else {
            return []
        }
        return decoded
    }
}

// MARK: - Timeline Provider
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), rate: 67.5, city: "İstanbul", footprint: 0, history: [])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let data = WidgetDataManager.shared
        let entry = SimpleEntry(
            date: Date(),
            rate: data.reservoirRate,
            city: data.selectedCity,
            footprint: data.dailyFootprint,
            history: data.weeklyHistory
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let data = WidgetDataManager.shared
        let entry = SimpleEntry(
            date: Date(),
            rate: data.reservoirRate,
            city: data.selectedCity,
            footprint: data.dailyFootprint,
            history: data.weeklyHistory
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
    let history: [DailyUsage]
}

// MARK: - Views

// MARK: - Shapes
struct Wave: Shape {
    var strength: Double
    var frequency: Double
    var phase: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = Double(rect.width)
        let height = Double(rect.height)
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * frequency * .pi * 2 + phase)
            let y = midHeight + sine * strength
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
}

struct LiquidView: View {
    let rate: Double
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Empty State (White Background)
                Rectangle()
                    .fill(.white)
                
                // Water Level
                ZStack {
                    // Back Wave (Lighter)
                    Wave(strength: 6, frequency: 1, phase: 0)
                        .fill(Color.cyan.opacity(0.3))
                        .offset(y: 3)
                    
                    // Front Wave (Stronger)
                    Wave(strength: 8, frequency: 0.8, phase: 2)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .frame(height: geo.size.height * (rate / 100))
                .animation(.easeInOut, value: rate)
            }
        }
        .clipShape(ContainerRelativeShape())
    }
}

// MARK: - Views

struct SmallWidgetView: View {
    let entry: Provider.Entry
    
    var textColor: Color {
        // If rate is high (>60%), text is on water (white). Else, text is on air (blue).
        return entry.rate > 60 ? .white : .blue
    }
    
    var body: some View {
        ZStack {
            // 1. LIQUID BACKGROUND
            LiquidView(rate: entry.rate)
            
            // 2. CONTENT LAYER
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(textColor)
                        .font(.caption2)
                    Text(entry.city.uppercased())
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundStyle(textColor)
                    Spacer()
                }
                .padding(.bottom, 8)
                
                Spacer()
                
                // Percentage (Huge & Bold)
                VStack(spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", floor(entry.rate * 10) / 10))
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(textColor)
                        Text("%")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(textColor.opacity(0.7))
                            .offset(y: -4)
                    }
                    Text("DOLULUK")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(textColor.opacity(0.8))
                        .tracking(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
                
                // Footer (Personal Consumption)
                VStack(spacing: 4) {
                    Divider()
                        .overlay(textColor.opacity(0.3))
                    
                    HStack(alignment: .bottom) {
                        Text("BUGÜN:")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(textColor.opacity(0.8))
                        
                        Text("\(Int(entry.footprint))L")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(textColor)
                            
                        Spacer()
                    }
                }
            }
            .padding()
        }
    }
}

struct MediumWidgetView: View {
    let entry: Provider.Entry
    
    var maxValue: Double {
        entry.history.map(\.totalLiters).max() ?? 200
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // LEFT COLUMN: LIQUID TANK representation
            ZStack {
                LiquidView(rate: entry.rate)
                
                VStack {
                    HStack {
                        Image(systemName: "drop.fill")
                            .font(.caption2)
                            .foregroundStyle(entry.rate > 60 ? .white : .blue)
                        Text(entry.city.uppercased())
                            .font(.caption2)
                            .fontWeight(.heavy)
                            .foregroundStyle(entry.rate > 60 ? .white : .primary)
                        Spacer()
                    }
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(String(format: "%.1f", floor(entry.rate * 10) / 10))
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundStyle(entry.rate > 60 ? .white : .blue)
                            .shadow(radius: entry.rate > 60 ? 2 : 0)
                        Text("% DOLU")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(entry.rate > 60 ? .white.opacity(0.9) : .secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                }
                .padding()
            }
            .frame(width: 130)
            
            // RIGHT COLUMN: CHART (Clean White Area)
            VStack(alignment: .leading, spacing: 12) {
                // Header (Today's Summary)
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ÖZET")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                        Text("Son 5 Gün")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(Int(entry.footprint))L")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.blue)
                }
                
                if entry.history.isEmpty {
                    VStack {
                        Spacer()
                        Text("Veri Yok")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    Chart(entry.history) { item in
                        BarMark(
                            x: .value("Gün", item.weekday),
                            y: .value("Litre", item.totalLiters)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(2)
                    }
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisValueLabel()
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.gray)
                        }
                    }
                    .chartYAxis(.hidden)
                }
            }
            .padding()
            .background(Color.white)
        }
    }
}


struct SuIzimWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
    }
}

// MARK: - Widget Definition
struct SuIzimWidget: Widget {
    let kind: String = "SuIzimWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SuIzimWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    // Soft Sky Gradient
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.9, green: 0.95, blue: 1.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Su İzim")
        .description("Baraj doluluk oranı ve analizler")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemMedium) {
    SuIzimWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        rate: 67.5,
        city: "İstanbul",
        footprint: 125,
        history: [
            DailyUsage(date: Date(), totalLiters: 120, weekday: "Pzt"),
            DailyUsage(date: Date(), totalLiters: 85, weekday: "Sal"),
            DailyUsage(date: Date(), totalLiters: 150, weekday: "Çar"),
            DailyUsage(date: Date(), totalLiters: 40, weekday: "Per"),
            DailyUsage(date: Date(), totalLiters: 125, weekday: "Cum")
        ]
    )
}
