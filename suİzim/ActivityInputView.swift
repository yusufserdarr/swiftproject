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

struct ActivityInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedActivity = "Duş"
    @State private var amount: Double = 10.0
    
    let activities = Array(WaterCalculator.activityRates.keys).sorted()
    
    var calculatedUsage: Double {
        WaterCalculator.calculateWaterUsage(activityName: selectedActivity, amount: amount)
    }
    
    // 1. KULLANICIYA SORULACAK SORU (Başlık)
    // "Miktar" yerine artık insani sorular soruyoruz.
    var headerTitle: String {
        switch selectedActivity {
        case "Duş":
            return "Duş ne kadar sürdü?"
        case "Diş Fırçalama":
            return "Ne kadar sürdü?"
        case "Bulaşık (Elde)":
            return "Bulaşıkları kaç dakika yıkadın?" //
        case "Bulaşık (Makine)", "Çamaşır (Makine)":
            return "Makineyi kaç kez çalıştırdın?"
        case "Sifon":
            return "Sifona kaç kez bastın?"
        case "El Yıkama":
            return "Bugün kaç kez el yıkadın?"
        case "Araba Yıkama":
            return "Arabayı kaç dakika yıkadın?"
        default:
            return "Miktar nedir?"
        }
    }
    
    // 2. SAYININ YANINDAKİ EK (Suffix)
    // Sadece sayı değil, ne olduğu belli olsun (10 dk, 3 kere vb.)
    var amountSuffix: String {
        switch selectedActivity {
        case "Duş", "Diş Fırçalama","Çamaşır (Makine)","Araba Yıkama","Bulaşık (Elde)":
            return "dakika"
        case "Sifon":
            return "basış"
        case "Bulaşık (Makine)":
            return "çalıştırma"
        default:
            return "kere"
        }
    }
    
    // 3. SLIDER ARALIĞI (Dinamik)
    // Az önceki mantığı koruyoruz, aktiviteye göre mantıklı sınırlar.
    var sliderRange: ClosedRange<Double> {
        switch selectedActivity {
        case "Duş": return 1...60
        case "Diş Fırçalama": return 1...10
        case "Araba Yıkama": return 1...60
        case "Sifon" : return 1...20
        case "El Yıkama": return 1...20
        default: return 1...15 // Makineler ve Elde bulaşık için
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Ne Yaptın?")) {
                    Picker("Aktivite", selection: $selectedActivity) {
                        ForEach(activities, id: \.self) { activity in
                            Text(activity).tag(activity)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .onChange(of: selectedActivity) {
                        // Aktivite değişince varsayılan değerleri mantıklı hale getir
                        if selectedActivity == "Duş" { amount = 10.0 }
                        else if selectedActivity == "Diş Fırçalama" { amount = 2.0 }
                        else { amount = 1.0 }
                    }
                }
                
                // BURASI DEĞİŞTİ: Artık dinamik başlık kullanıyoruz
                Section(header: Text(headerTitle)) {
                    HStack {
                        // Sayı ve Suffix yan yana: "10 dakika" veya "3 kere"
                        Text("\(Int(amount)) \(amountSuffix)")
                            .font(.system(.body, design: .rounded))
                            .bold()
                            .foregroundStyle(.blue)
                            .frame(width: 80, alignment: .leading) // Hizalama düzgün dursun diye
                        
                        Slider(value: $amount, in: sliderRange, step: 1)
                    }
                    
                    // Ekstra Açıklama (İsteğe bağlı, kafa karışıklığını tamamen bitirir)
                    if selectedActivity == "Bulaşık (Elde)" {
                        Text("Not: Tek bir tabak değil, tüm bulaşık yıkama seansı kastedilmektedir.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
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
            unit: amountSuffix, // Veritabanına da "dakika", "kere" olarak kaydedelim
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
