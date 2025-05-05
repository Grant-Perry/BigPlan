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
import CloudKit

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
   private let cloudKitContainer: CKContainer
   private var lastLoggedCount: Int = 0
   
   init() {
	  do {
		 let schema = Schema([
			DailyHealthEntry.self
		 ])
		 
		 let storeURL = URL.documentsDirectory.appendingPathComponent("BigPlan.store")
		 logger.info("📁 Store URL: \(storeURL.path())")
		 
		 cloudKitContainer = CKContainer(identifier: "iCloud.com.GrantPerry.BigPlan")
		 
		 let config = ModelConfiguration(
			schema: schema,
			url: storeURL,
			allowsSave: true,
			cloudKitDatabase: .private("iCloud.com.GrantPerry.BigPlan")
		 )
		 
		 container = try ModelContainer(for: schema, configurations: [config])
		 
		 // Monitor CloudKit status and changes
		 setupCloudKitMonitoring()
		 setupChangeMonitoring()
		 setupSyncMonitoring()
		 
		 // Initial data verification
		 Task { @MainActor in
			let context = container.mainContext
			let descriptor = FetchDescriptor<DailyHealthEntry>()
			
			if let entries = try? context.fetch(descriptor) {
			   logger.info("🔍 Found \(entries.count) entries in store at launch")
			   entries.forEach { entry in
				  logger.info("📝 Entry: \(entry.id) from \(entry.date)")
			   }
			   self.lastLoggedCount = entries.count
			}
		 }
		 
		 logger.info("✅ ModelContainer initialized successfully with CloudKit at \(storeURL.path())")
		 
	  } catch {
		 logger.error("💥 Fatal error setting up persistence: \(error.localizedDescription)")
		 fatalError("Fatal error setting up persistence")
	  }
   }
   
   private func setupCloudKitMonitoring() {
	  Task { @MainActor in
		 do {
			let status = try await cloudKitContainer.accountStatus()
			switch status {
			   case .available:
				  logger.info("✅ CloudKit account is available")
				  
				  // Set up database subscription for changes
				  let database = cloudKitContainer.privateCloudDatabase
				  let subscription = CKDatabaseSubscription(subscriptionID: "all-changes")
				  
				  let notificationInfo = CKSubscription.NotificationInfo()
				  notificationInfo.shouldSendContentAvailable = true
				  subscription.notificationInfo = notificationInfo
				  
				  try await database.save(subscription)
				  logger.info("✅ CloudKit subscription saved")
				  
			   case .noAccount:
				  logger.error("❌ No iCloud account found")
			   case .restricted:
				  logger.error("❌ CloudKit account is restricted")
			   case .couldNotDetermine:
				  logger.error("❌ Could not determine CloudKit account status")
			   case .temporarilyUnavailable:
				  logger.error("❌ CloudKit temporarily unavailable")
			   @unknown default:
				  logger.error("❌ Unknown CloudKit account status")
			}
		 } catch {
			logger.error("❌ Error checking CloudKit status: \(error.localizedDescription)")
		 }
	  }
   }
   
   private func setupSyncMonitoring() {
	  // Monitor for remote changes
	  NotificationCenter.default.addObserver(
		 self,
		 selector: #selector(handleRemoteChange),
		 name: Notification.Name("NSPersistentStoreRemoteChangeNotification"),
		 object: nil
	  )
   }
   
   @objc private func handleRemoteChange(_ notification: Notification) {
	  Task { [weak self] in
		 guard let self = self else { return }
		 let descriptor = FetchDescriptor<DailyHealthEntry>()
		 if let count = try? self.container.mainContext.fetchCount(descriptor) {
			// Only log if count has changed
			if count != self.lastLoggedCount {
			   logger.info("☁️ Remote change - Entries changed from \(self.lastLoggedCount) to \(count)")
			   self.lastLoggedCount = count
			}
		 }
	  }
   }
   
   private func setupChangeMonitoring() {
	  let context = container.mainContext
	  context.autosaveEnabled = true
	  
	  NotificationCenter.default.addObserver(
		 self,
		 selector: #selector(contextWillSave),
		 name: Notification.Name("NSManagedObjectContextWillSaveNotification"),
		 object: context
	  )
	  
	  NotificationCenter.default.addObserver(
		 self,
		 selector: #selector(contextDidSave),
		 name: Notification.Name("NSManagedObjectContextDidSaveNotification"),
		 object: context
	  )
   }
   
   @objc private func contextWillSave(_ notification: Notification) {
	  logger.info("💾 Context will save...")
   }
   
   @objc private func contextDidSave(_ notification: Notification) {
	  Task { [weak self] in
		 guard let self = self else { return }
		 let descriptor = FetchDescriptor<DailyHealthEntry>()
		 if let count = try? self.container.mainContext.fetchCount(descriptor) {
			if count != self.lastLoggedCount {
			   logger.info("✅ Context saved - Entries changed from \(self.lastLoggedCount) to \(count)")
			   self.lastLoggedCount = count
			}
		 }
	  }
   }
}
