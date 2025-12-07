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
    
    var unit: String {
        switch selectedActivity {
        case "Duş", "Diş Fırçalama": return "Dakika"
        case "Sifon": return "Basış"
        default: return "Adet/Yıkama"
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
                }
                
                Section(header: Text("Miktar (\(unit))")) {
                    HStack {
                        Text("\(Int(amount))")
                            .frame(width: 50)
                        Slider(value: $amount, in: 1...60, step: 1)
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
