//
//  suI_zimApp.swift
//  suİzim
//
//  Created by Yusuf Serdaroğlu on 4.12.2025.
//

import SwiftUI
import SwiftData

@main
struct suI_zimApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ActivityLog.self,
            ReservoirStatus.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
