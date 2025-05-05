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
import OSLog

private let logger = Logger(subsystem: "BigPlan", category: "App")

@main
struct BigPlanApp: App {
   @StateObject private var persistenceController = PersistenceController()
   
   var body: some Scene {
	  WindowGroup {
		 BigPlanTabView()
			.environment(\.modelContext, persistenceController.container.mainContext)
	  }
   }
}

// MARK: - Persistence Controller
@MainActor
class PersistenceController: ObservableObject {
   let container: ModelContainer
   
   init() {
	  do {
		 // Create Schema
		 let schema = Schema([
			DailyHealthEntry.self,
			SanityCheckModel.self
		 ])
		 
		 let storeURL = URL.documentsDirectory.appendingPathComponent("BigPlan.store")
		 logger.info("📁 Store URL: \(storeURL.path())")
		 
		 // REMOVE THIS FOR NOW - let's not delete the store on every launch
		 // try? FileManager.default.removeItem(at: storeURL)
		 
		 let config = ModelConfiguration(
			url: storeURL,
			allowsSave: true,
			cloudKitDatabase: .none
		 )
		 
		 container = try ModelContainer(for: schema, configurations: [config])
		 
		 // Verify container setup
		 Task { @MainActor in
			let context = container.mainContext
			let descriptor = FetchDescriptor<DailyHealthEntry>()
			
			if let entries = try? context.fetch(descriptor) {
			   logger.info("🔍 Found \(entries.count) entries in store at launch")
			   entries.forEach { entry in
				  logger.info("📝 Entry: \(entry.id) from \(entry.date)")
			   }
			}
		 }
		 
		 logger.info("✅ ModelContainer initialized successfully at \(storeURL.path())")
		 
	  } catch {
		 logger.error("💥 Fatal error setting up persistence: \(error.localizedDescription)")
		 fatalError("Fatal error setting up persistence")
	  }
   }
}
