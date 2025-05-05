//   BigPlanApp.swift
//   BigPlan
//
//   Created by: Gp. on 5/5/25 at 10:11 AM
//     Modified: 
//
//  Copyright © 2025 Delicious Studios, LLC. - Grant Perry
//

import SwiftUI
import SwiftData

@main
struct BigPlanApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
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
