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
    }
}
// MARK: - Views

struct SmallWidgetView: View {
    let entry: Provider.Entry
    
    var cityImageName: String {
        let normalizedCity = entry.city.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "ı", with: "i")
        
        if normalizedCity.contains("istanbul") { return "istanbul" }
        if normalizedCity.contains("ankara") { return "ankara" }
        if normalizedCity.contains("izmir") { return "izmir" }
        if normalizedCity.contains("bursa") { return "bursa" }
        return "istanbul"
    }
    
    var body: some View {
        ZStack {
            // 1. PHOTO BACKGROUND
            // 1. PHOTO BACKGROUND
            Image(cityImageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity) // Force fill
                .clipped() // Ensure no overflow
                .overlay(Color.black.opacity(0.2)) // Genel karartma
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.3), .black.opacity(0.8)], // Alt kısım daha koyu
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            // 2. CONTENT LAYER
            VStack(spacing: 0) {
                // Header
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .foregroundStyle(.cyan.gradient)
                        .font(.caption2)
                    Text(entry.city.uppercased())
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.bottom, 8)
                .padding(.top, 4)
                
                Spacer()
                
                // Percentage (Huge & Bold)
                VStack(spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", floor(entry.rate * 10) / 10))
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        Text("%")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white.opacity(0.8))
                            .offset(y: -4)
                    }
                    Text("DOLULUK")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(1)
                }
                
                Spacer()
                
                // Footer (Personal Consumption - Glassmorphism)
                VStack(spacing: 4) {
                    Divider()
                        .overlay(.white.opacity(0.3))
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Text("BUGÜN:")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white.opacity(0.9))
                        
                        Text("\(Int(entry.footprint))L")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.cyan)
                    }
                }
                .padding(.bottom, 4)
            }
            .padding(16) // Safe padding
        }
    }
}

struct MediumWidgetView: View {
    let entry: Provider.Entry
    
    var maxValue: Double {
        entry.history.map(\.totalLiters).max() ?? 200
    }
    
    var cityImageName: String {
        let normalizedCity = entry.city.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .replacingOccurrences(of: "ı", with: "i") // Extra safety for Turkish inputs
        
        if normalizedCity.contains("istanbul") { return "istanbul" }
        if normalizedCity.contains("ankara") { return "ankara" }
        if normalizedCity.contains("izmir") { return "izmir" }
        if normalizedCity.contains("bursa") { return "bursa" }
        return "istanbul"
    }
    
    var body: some View {
        ZStack {
            // BACKGROUND IMAGE - Full Width
            Image(cityImageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .overlay(Color.black.opacity(0.3)) // Genel karartma artırıldı
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.4), .black.opacity(0.9)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            HStack(spacing: 0) {
                // LEFT COLUMN: SUMMARY
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(.cyan.gradient)
                            .font(.caption2)
                        Text(entry.city.uppercased())
                            .font(.caption2)
                            .fontWeight(.heavy)
                            .foregroundStyle(.white.opacity(0.9))
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Percentage Display
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(String(format: "%.1f", floor(entry.rate * 10) / 10))
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                            Text("%")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        
                        Text("DOLULUK")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                            .tracking(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                }
                .frame(width: 140)
                .padding()
                
                // Vertical Divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1)
                    .padding(.vertical, 16)
                
            // RIGHT COLUMN: CHART (On Transparent/Glass Background)
                VStack(alignment: .leading, spacing: 12) {
                    // Header (Today's Summary)
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ÖZET")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(.white.opacity(0.7))
                                .tracking(0.5)
                            Text("Son 5 Gün")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.9)) // Daha parlak
                        }
                        Spacer()
                        Text("\(Int(entry.footprint))L")
                            .font(.system(size: 20, weight: .black, design: .rounded))
                            .foregroundStyle(.white) // Beyaz yapıldı
                            .shadow(radius: 2)
                    }
                    
                    if entry.history.isEmpty {
                        VStack {
                            Spacer()
                            Text("Veri Yok")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                            Spacer()
                        }
                    } else {
                        Chart(entry.history) { item in
                            BarMark(
                                x: .value("Gün", item.weekday),
                                y: .value("Litre", item.totalLiters)
                            )
                            .foregroundStyle(.white) // Saf beyaz çubuklar
                            .cornerRadius(2)
                        }
                        .chartXAxis {
                            AxisMarks { _ in
                                AxisValueLabel()
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white.opacity(0.8)) // Daha okunaklı eksen yazıları
                            }
                        }
                        .chartYAxis(.hidden)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.4)) // Yarı saydam arka plan paneli
                .clipShape(RoundedRectangle(cornerRadius: 12)) // Köşeleri yumuşat
                .padding(8) // Panel ile kenar arasında boşluk
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
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
                     Color.black // Arka plan fotoğrafı olduğu için container rengi önemsiz
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
