import Foundation
import SwiftData

@Model
final class ActivityLog {
    var id: UUID
    var name: String
    var amount: Double // e.g., duration in minutes or count
    var unit: String // e.g., "dk", "adet"
    var totalWaterLiters: Double
    var date: Date
    
    init(name: String, amount: Double, unit: String, totalWaterLiters: Double, date: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.unit = unit
        self.totalWaterLiters = totalWaterLiters
        self.date = date
    }
}

@Model
final class ReservoirStatus {
    var name: String
    var occupancyRate: Double // 0.0 to 100.0
    var date: Date
    var cityRawValue: String = "istanbul" // Default to istanbul
    
    var city: City {
        get { City(rawValue: cityRawValue) ?? .istanbul }
        set { cityRawValue = newValue.rawValue }
    }
    
    init(name: String, occupancyRate: Double, date: Date = Date(), city: City = .istanbul) {
        self.name = name
        self.occupancyRate = occupancyRate
        self.date = date
        self.cityRawValue = city.rawValue
    }
}

enum City: String, CaseIterable, Codable {
    case istanbul = "İstanbul"
    case ankara = "Ankara"
    case izmir = "İzmir"
    case bursa = "Bursa"
}
