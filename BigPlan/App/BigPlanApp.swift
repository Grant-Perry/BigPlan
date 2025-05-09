//   BigPlanApp.swift
//   BigPlan
//
//   Created by: Gp. on 5/5/25 at 10:11 AM
//     Modified:
//
//  Copyright Delicious Studios, LLC. - Grant Perry

import SwiftUI
import SwiftData
import OSLog
import CloudKit

private let logger = Logger(subsystem: "BigPlan", category: "App")

@main
struct BigPlanApp: App {
   @StateObject private var persistenceController = PersistenceController()
   @State private var showSplash = true

   var body: some Scene {
	  WindowGroup {
		 ZStack {
			BigPlanTabView()
			   .environment(\.modelContext, persistenceController.container.mainContext)

			if showSplash {
			   MainSplashView()
				  .transition(.opacity)
				  .gesture(
					 DragGesture(minimumDistance: 50)
						.onEnded { gesture in
						   if gesture.translation.width < 0 {  // Swipe left
							  withAnimation {
								 showSplash = false
							  }
						   }
						}
				  )
				  .onAppear {
					 // Auto-dismiss after 6 seconds
					 DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
						withAnimation {
						   showSplash = false
						}
					 }
				  }
			}
		 }
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
			DailyHealthEntry.self,
			Settings.self
		 ])

		 let storeURL = URL.documentsDirectory.appendingPathComponent("BigPlan.store")
		 logger.info(" Store URL: \(storeURL.path())")

		 cloudKitContainer = CKContainer(identifier: "iCloud.com.GrantPerry.BigPlan")

		 let config = ModelConfiguration(
			schema: schema,
			url: storeURL,
			allowsSave: true,
			cloudKitDatabase: .private("iCloud.com.GrantPerry.BigPlan")
		 )

		 container = try ModelContainer(for: schema, configurations: [config])

		 setupCloudKitMonitoring()
		 setupChangeMonitoring()
		 setupSyncMonitoring()

		 Task { @MainActor in
			let context = container.mainContext
			let descriptor = FetchDescriptor<DailyHealthEntry>()

			if let entries = try? context.fetch(descriptor) {
			   logger.info(" Found \(entries.count) entries in store at launch")
			   entries.forEach { entry in
				  logger.info(" Entry: \(entry.id) from \(entry.date)")
			   }
			   self.lastLoggedCount = entries.count
			}
		 }

		 logger.info(" ModelContainer initialized successfully with CloudKit at \(storeURL.path())")

	  } catch {
		 logger.error(" Fatal error setting up persistence: \(error.localizedDescription)")
		 fatalError("Fatal error setting up persistence")
	  }
   }

   private func setupCloudKitMonitoring() {
	  Task { @MainActor in
		 do {
			let status = try await cloudKitContainer.accountStatus()
			switch status {
			   case .available:
				  logger.info(" CloudKit account is available")

				  let database = cloudKitContainer.privateCloudDatabase
				  let subscription = CKDatabaseSubscription(subscriptionID: "all-changes")

				  let notificationInfo = CKSubscription.NotificationInfo()
				  notificationInfo.shouldSendContentAvailable = true
				  subscription.notificationInfo = notificationInfo

				  try await database.save(subscription)
				  logger.info(" CloudKit subscription saved")

			   case .noAccount:
				  logger.error(" No iCloud account found")
			   case .restricted:
				  logger.error(" CloudKit account is restricted")
			   case .couldNotDetermine:
				  logger.error(" Could not determine CloudKit account status")
			   case .temporarilyUnavailable:
				  logger.error(" CloudKit temporarily unavailable")
			   @unknown default:
				  logger.error(" Unknown CloudKit account status")
			}
		 } catch {
			logger.error(" Error checking CloudKit status: \(error.localizedDescription)")
		 }
	  }
   }

   private func setupSyncMonitoring() {
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
			if count != self.lastLoggedCount {
			   logger.info(" Remote change - Entries changed from \(self.lastLoggedCount) to \(count)")
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
	  logger.info(" Context will save...")
   }

   @objc private func contextDidSave(_ notification: Notification) {
	  Task { [weak self] in
		 guard let self = self else { return }
		 let descriptor = FetchDescriptor<DailyHealthEntry>()
		 if let count = try? self.container.mainContext.fetchCount(descriptor) {
			if count != self.lastLoggedCount {
			   logger.info(" Context saved - Entries changed from \(self.lastLoggedCount) to \(count)")
			   self.lastLoggedCount = count
			}
		 }
	  }
   }
}
