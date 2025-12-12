//
//  AppIntent.swift
//  SuIzimWidget
//

import WidgetKit
import AppIntents

// Widget configuration intent
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Su İzim Widget" }
    static var description: IntentDescription { "Baraj doluluk ve su ayak izi göster" }
    
    @Parameter(title: "Görünüm", default: .reservoir)
    var viewType: WidgetViewType
}

// View type for toggle
enum WidgetViewType: String, AppEnum {
    case reservoir = "reservoir"
    case footprint = "footprint"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Görünüm Tipi"
    }
    
    static var caseDisplayRepresentations: [WidgetViewType: DisplayRepresentation] {
        [
            .reservoir: "Baraj Doluluk",
            .footprint: "Su Ayak İzi"
        ]
    }
}

// Interactive toggle intent
struct ToggleViewIntent: AppIntent {
    static var title: LocalizedStringResource { "Görünümü Değiştir" }
    
    @Parameter(title: "Yeni Görünüm")
    var newViewType: WidgetViewType
    
    init() {
        self.newViewType = .reservoir
    }
    
    init(newViewType: WidgetViewType) {
        self.newViewType = newViewType
    }
    
    func perform() async throws -> some IntentResult {
        // Toggle the view
        return .result()
    }
}
