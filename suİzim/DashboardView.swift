import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activities: [ActivityLog]
    
    @State private var reservoirData: [ReservoirStatus] = []
    @State private var generalOccupancy: Double = 0.0
    @State private var dataDate: String = ""
    @State private var selectedCity: City = .istanbul
    @State private var isLoading = true
    @State private var errorMessage: String?
    @StateObject private var reservoirService = ReservoirService()
    
    var dailyWaterUsage: Double {
        let calendar = Calendar.current
        let todayActivities = activities.filter { calendar.isDateInToday($0.date) }
        return todayActivities.reduce(0) { $0 + $1.totalWaterLiters }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Gradient
                LinearGradient(colors: [Color.blue.opacity(0.1), Color.white], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // City Picker
                        Picker("Şehir Seçin", selection: $selectedCity) {
                            ForEach(City.allCases, id: \.self) { city in
                                Text(city.rawValue).tag(city)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: selectedCity) {
                            Task { await loadReservoirData() }
                        }
                        
                        // Summary Card
                        VStack(spacing: 16) {
                            Text("Bugünkü Su Ayak İzin")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.9))
                            
                            Text(String(format: "%.1f Litre", dailyWaterUsage))
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(radius: 2)
                            
                            Text(SuggestionEngine.getSuggestion(for: dailyWaterUsage))
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(8)
                                .background(.white.opacity(0.2))
                                .cornerRadius(10)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .cornerRadius(24)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        // Reservoir Status
                        VStack(alignment: .leading, spacing: 16) {
                            Text("\(selectedCity.rawValue) Baraj Doluluk Oranları")
                                .font(.title3)
                                .bold()
                                .foregroundStyle(.primary)
                            
                            if isLoading {
                                ProgressView("Veriler Yükleniyor...")
                                    .frame(maxWidth: .infinity, minHeight: 100)
                            } else if reservoirData.isEmpty && generalOccupancy == 0.0 {
                                ContentUnavailableView(
                                    "Veri Alınamadı",
                                    systemImage: "wifi.slash",
                                    description: Text("Veriler alınırken bir sorun oluştu.")
                                )
                                .frame(height: 200)
                            } else if reservoirData.isEmpty {
                                // Show General Rate Only (For Istanbul & Ankara)
                                VStack(spacing: 12) {
                                    Text("\(selectedCity.rawValue) Geneli")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    
                                    ZStack {
                                        Circle()
                                            .stroke(lineWidth: 15)
                                            .opacity(0.3)
                                            .foregroundColor(Color.blue)
                                        
                                        Circle()
                                            .trim(from: 0.0, to: CGFloat(min(generalOccupancy / 100, 1.0)))
                                            .stroke(style: StrokeStyle(lineWidth: 15, lineCap: .round, lineJoin: .round))
                                            .foregroundColor(generalOccupancy < 50 ? .orange : .green)
                                            .rotationEffect(Angle(degrees: 270.0))
                                            .animation(.linear, value: generalOccupancy)
                                        
                                        Text(String(format: "%%%.1f", generalOccupancy))
                                            .font(.largeTitle)
                                            .bold()
                                    }
                                    .frame(width: 150, height: 150)
                                    .padding()
                                    
                                    VStack(spacing: 4) {
                                        Text("Veri Kaynağı: \(sourceName)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        
                                        if !dataDate.isEmpty {
                                            Text("Son Güncelleme: \(dataDate)")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Link("Veriyi Doğrula", destination: sourceURL)
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                            .padding(.top, 4)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            } else {
                                // List of Dams (For Izmir or if Istanbul adds individual data)
                                HStack {
                                    Spacer()
                                    Text(String(format: "Ort. %%%.1f", generalOccupancy))
                                        .font(.subheadline)
                                        .bold()
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(generalOccupancy < 50 ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
                                        .foregroundStyle(generalOccupancy < 50 ? .orange : .green)
                                        .cornerRadius(20)
                                }
                                
                                ForEach(reservoirData) { reservoir in
                                    VStack(spacing: 8) {
                                        HStack {
                                            Text(reservoir.name)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Text(String(format: "%%%.1f", reservoir.occupancyRate))
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundStyle(.primary)
                                        }
                                        
                                        GeometryReader { geometry in
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(height: 8)
                                                
                                                Capsule()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [.blue, .cyan],
                                                            startPoint: .leading,
                                                            endPoint: .trailing
                                                        )
                                                    )
                                                    .frame(width: geometry.size.width * (reservoir.occupancyRate / 100), height: 8)
                                            }
                                        }
                                        .frame(height: 8)
                                    }
                                }
                                
                                // Source info for list view
                                VStack(spacing: 4) {
                                    Text("Veri Kaynağı: \(sourceName)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Link("Doğrula", destination: sourceURL)
                                        .font(.caption2)
                                        .foregroundStyle(.blue)
                                }
                                .padding(.top, 10)
                            }
                        }
                        .padding(20)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                        
                        // Quick Tip
                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: "lightbulb.fill")
                                .font(.title2)
                                .foregroundStyle(.yellow)
                                .padding(12)
                                .background(Color.yellow.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Günün İpucu")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                
                                Text(SuggestionEngine.getRandomTip())
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                    }
                    .padding()
                }
            }
            .navigationTitle("Su İzim")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadReservoirData()
            }
        }
    }
    
    private var sourceName: String {
        switch selectedCity {
        case .istanbul: return "İBB Açık Veri Portalı"
        case .ankara: return "ASKİ"
        case .izmir: return "İzmir Açık Veri Portalı"
        case .bursa: return "Bursa Büyükşehir Belediyesi Açık Veri"
        }
    }
    
    private var sourceURL: URL {
        switch selectedCity {
        case .istanbul: return URL(string: "https://data.ibb.gov.tr/dataset/istanbul-baraj-doluluk-oranlari")!
        case .ankara: return URL(string: "https://www.aski.gov.tr/tr/Baraj.aspx")!
        // Revert to base URL to rely on WKWebView's redirect handling
        case .izmir: return URL(string: "https://www.izsu.gov.tr/tr/Barajlar/BarajSuDolulukOranlari")!
        case .bursa: return URL(string: "https://bapi.bursa.bel.tr/apigateway/bbbAcikVeri_Buski/baraj")!
        }
    }
    
    private func loadReservoirData() async {
        isLoading = true
        reservoirData = await reservoirService.fetchReservoirData(for: selectedCity)
        
        // Optimization: If we have individual dam data, calculate general rate locally
        // to avoid a second network request (preventing rate-limiting/delays).
        if !reservoirData.isEmpty {
            let total = reservoirData.reduce(0.0) { $0 + $1.occupancyRate }
            generalOccupancy = total / Double(reservoirData.count)
            dataDate = "Canlı Veri"
            
            // For Bursa, try to find "Geneli" item specifically if exists
            if selectedCity == .bursa, let geneli = reservoirData.first(where: { $0.name.contains("Geneli") }) {
                generalOccupancy = geneli.occupancyRate
            }
        } else {
            // Only fetch general rate separately if list is empty (e.g. Ankara)
            let result = await reservoirService.getGeneralOccupancyRate(for: selectedCity)
            generalOccupancy = result.rate
            dataDate = result.date
        }
        
        isLoading = false
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [ActivityLog.self, ReservoirStatus.self], inMemory: true)
}
