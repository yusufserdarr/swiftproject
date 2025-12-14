/*import SwiftUI
import SwiftData

struct ActivityInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedActivity = "Duş"
    @State private var amount: Double = 10.0
    
    let activities = Array(WaterCalculator.activityRates.keys).sorted()
    
    var calculatedUsage: Double {
        WaterCalculator.calculateWaterUsage(activityName: selectedActivity, amount: amount)
    }
    
    var unit: String {
        switch selectedActivity {
        case "Duş", "Diş Fırçalama": return "Dakika"
        case "Sifon": return "Basış"
        default: return "Adet/Yıkama"
        }
    }

    var sliderRange: ClosedRange<Double> {
        switch selectedActivity {
        case "Duş": return 1...120
        case "Diş Fırçalama": return 1...10
        case "Sifon": return 1...20
        case "Çamaşır Makinesi", "Bulaşık Makinesi": return 1...5
        default: return 1...60
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Aktivite Seçimi")) {
                    Picker("Aktivite", selection: $selectedActivity) {
                        ForEach(activities, id: \.self) { activity in
                            Text(activity).tag(activity)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: selectedActivity) { oldValue, newValue in
                        // Reset amount to plausible default when activity changes
                         amount = (newValue == "Duş") ? 10.0 : 1.0
                    }
                }
                
                Section(header: Text("Miktar (\(unit))")) {
                    HStack {
                        Text("\(Int(amount))")
                            .frame(width: 50)
                        Slider(value: $amount, in: sliderRange, step: 1)
                    }
                    Text("Maksimum \(Int(sliderRange.upperBound)) \(unit.lowercased()) seçilebilir.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section(header: Text("Tahmini Tüketim")) {
                    HStack {
                        Text("Su Ayak İzi:")
                        Spacer()
                        Text(String(format: "%.1f Litre", calculatedUsage))
                            .bold()
                            .foregroundStyle(.blue)
                    }
                }
                
                Section {
                    Button(action: saveActivity) {
                        Text("Kaydet")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .listRowBackground(Color.blue)
                    .foregroundStyle(.white)
                }
            }
            .navigationTitle("Aktivite Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveActivity() {
        let newActivity = ActivityLog(
            name: selectedActivity,
            amount: amount,
            unit: unit,
            totalWaterLiters: calculatedUsage
        )
        modelContext.insert(newActivity)
        dismiss()
    }
}

#Preview {
    ActivityInputView()
        .modelContainer(for: ActivityLog.self, inMemory: true)
}
*/

import SwiftUI
import SwiftData
import WidgetKit

// YENİ: Arama işleminin yapılacağı özel seçim sayfası
struct SearchableActivityList: View {
    let items: [String]         // Listelenecek veriler
    @Binding var selection: String // Seçilen veriyi geri göndermek için
    @Environment(\.dismiss) private var dismiss // Seçince sayfayı kapatmak için
    @State private var searchText = "" // Arama metni
    
    // Arama filtresi
    var filteredItems: [String] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredItems, id: \.self) { item in
                Button {
                    selection = item // Seçimi güncelle
                    dismiss()        // Sayfayı kapat
                } label: {
                    HStack {
                        Text(item)
                            .foregroundStyle(.primary)
                        Spacer()
                        if item == selection {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Aktivite veya ürün ara...")
        .navigationTitle("Seçim Yap")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// ANA GÖRÜNÜM
struct ActivityInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    enum Category: String, CaseIterable {
        case home = "NE YAPTINIZ"
        case virtual = "NE YEDİNİZ/İÇTİNİZ"
    }
    
    @State private var selectedCategory: Category = .home
    @State private var selectedActivity = "Duş"
    @State private var amount: Double = 1.0
    
    // Kategoriye göre listeyi getir
    var currentList: [String] {
        switch selectedCategory {
        case .home: return WaterCalculator.homeActivities.keys.sorted()
        case .virtual: return WaterCalculator.virtualActivities.keys.sorted()
        }
    }
    
    var calculatedUsage: Double {
        WaterCalculator.calculateWaterUsage(activityName: selectedActivity, amount: amount)
    }
    
    // BAŞLIKLAR
    var headerTitle: String {
        if selectedCategory == .virtual { return "Ne kadar tükettin?" }
        switch selectedActivity {
        case "Duş", "Sıcak Su Bekleme","Araba Yıkama","Bahçe Yıkama": return "Süre ne kadar?"
        case "Prompt": return "Kaç kere?"
        case "Sifon":
            return "Kaç kez?"
        default: return "Miktar nedir?"
        }
    }
    
    // BİRİMLER (Suffix)
    var amountSuffix: String {
        if selectedCategory == .virtual {
            if selectedActivity.contains("Kahve") || selectedActivity.contains("Çay") || selectedActivity.contains("Süt") { return "bardak" }
            if selectedActivity.contains("Çikolata") { return "paket" }
            if selectedActivity.contains("Tişört") || selectedActivity.contains("Pantolon") { return "adet" }
            return "porsiyon/adet"
        }
        switch selectedActivity {
        case "Duş", "Sıcak Su Bekleme", "Diş Fırçalama (Musluk Açık)","Araba Yıkama","Bahçe Yıkama": return "dakika"
        case "Sifon":
            return "basış"
        case "Prompt":
            return "kere"
        default: return "kez"
        }
    }
    
    // SLIDER ARALIĞI
    var sliderRange: ClosedRange<Double> {
        if selectedCategory == .virtual { return 1...10 }
        if selectedActivity == "Duş" { return 1...40 }
        if selectedActivity == "Prompt" { return 1...2000 }
        if selectedActivity == "Çamaşır Makinesi" { return 1...300 }
        if selectedActivity == "Araba Yıkama" { return 1...40}
        return 1...20
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // 1. KATEGORİ
                Section {
                    Picker("Kategori", selection: $selectedCategory) {
                        ForEach(Category.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedCategory) {
                        // Kategori değişince listedeki ilk elemanı seç (boş kalmasın)
                        selectedActivity = currentList.first ?? ""
                        amount = 1.0
                    }
                }
                
                // 2. AKTİVİTE SEÇİMİ (ARAMALI)
                Section(header: Text("Seçim")) {
                    // Burası artık Picker değil, tıklayınca açılan bir NavigationLink
                    NavigationLink {
                        SearchableActivityList(items: currentList, selection: $selectedActivity)
                    } label: {
                        HStack {
                            Text("Ne Yaptın?")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(selectedActivity) // Seçili olanı sağda göster
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // 3. MİKTAR
                Section(header: Text(headerTitle)) {
                    HStack {
                        Text("\(Int(amount)) \(amountSuffix)")
                            .font(.system(.body, design: .rounded))
                            .bold()
                            .foregroundStyle(selectedCategory == .virtual ? .orange : .blue)
                            .frame(width: 100, alignment: .leading)
                        
                        Slider(value: $amount, in: sliderRange, step: 1)
                            .tint(selectedCategory == .virtual ? .orange : .blue)
                    }
                }
                
                // 4. SONUÇ
                Section(header: Text("Tahmini Su Ayak İzi")) {
                    HStack {
                        Text("Toplam Tüketim:")
                        Spacer()
                        Text(String(format: "%.0f Litre", calculatedUsage))
                            .font(.title3)
                            .bold()
                            .foregroundStyle(calculatedUsage > 1000 ? .red : .primary)
                    }
                }
                
                Section {
                    Button(action: saveActivity) {
                        Text("Kaydet")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .listRowBackground(selectedCategory == .virtual ? Color.orange : Color.blue)
                    .foregroundStyle(.white)
                }
            }
            .navigationTitle("Aktivite Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }
    
    private func saveActivity() {
        let newActivity = ActivityLog(
            name: selectedActivity,
            amount: amount,
            unit: amountSuffix,
            totalWaterLiters: calculatedUsage
        )
        modelContext.insert(newActivity)
        
        // Update widget data (Simple total)
        let currentFootprint = SharedDataManager.shared.dailyFootprint
        SharedDataManager.shared.saveDailyFootprint(currentFootprint + calculatedUsage)
        
        // Update widget history (Advanced Chart Data)
        updateWidgetHistory()
        
        // Reload widget
        WidgetCenter.shared.reloadTimelines(ofKind: "SuIzimWidget")
        
        dismiss()
    }
    
    private func updateWidgetHistory() {
        do {
            try modelContext.save() // Ensure new activity is saved
            
            let descriptor = FetchDescriptor<ActivityLog>()
            let allActivities = try modelContext.fetch(descriptor)
            
            var history: [DailyUsage] = []
            let calendar = Calendar.current
            // Başlangıç tarihi olarak bugünü al
            let today = calendar.startOfDay(for: Date())
            
            // Son 5 günü hesapla (Bugün dahil geriye doğru)
            for i in 0..<5 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    let dayActivities = allActivities.filter { calendar.isDate($0.date, inSameDayAs: date) }
                    let total = dayActivities.reduce(0) { $0 + $1.totalWaterLiters }
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "EEE" // Pzt, Sal
                    formatter.locale = Locale(identifier: "tr_TR")
                    
                    history.append(DailyUsage(date: date, totalLiters: total, weekday: formatter.string(from: date)))
                }
            }
            
            // Widget için kronolojik sıra (Eskiden yeniye)
            SharedDataManager.shared.saveWeeklyHistory(history.reversed())
            
        } catch {
            print("Widget geçmişi güncellenirken hata: \(error)")
        }
    }
}

#Preview {
    ActivityInputView()
        .modelContainer(for: ActivityLog.self, inMemory: true)
}
