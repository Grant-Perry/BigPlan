//
//  BigPlanViewModel.swift
//  BigPlan
//
//  Created by Grant Perry on 2025-05-05.
//

import Foundation
import SwiftData
import OSLog
import HealthKit
private let logger = Logger(subsystem: "BigPlan", category: "BigPlanViewModel")

/// ViewModel for BigPlan, handling form state and CRUD operations for DailyHealthEntry.
@MainActor
@Observable
class BigPlanViewModel: ObservableObject {
   // MARK: - Stored Properties

   /// The SwiftData context for persistence operations.
   private let context: ModelContext

   private var existingEntry: DailyHealthEntry?

   /// All saved entries, sorted by date descending.
   var entries: [DailyHealthEntry] {
	  (try? context.fetch(
		 FetchDescriptor<DailyHealthEntry>(
			sortBy: [SortDescriptor(\DailyHealthEntry.date, order: .reverse)]
		 )
	  )) ?? []
   }

   private(set) var healthKitAuthorized: Bool = false

   var isWeatherLoaded: Bool = false
   var isLoadingWeather: Bool = false

   private var _hasUnsavedChanges: Bool = false

   var hasUnsavedChanges: Bool {
	  get { _hasUnsavedChanges }
	  set { _hasUnsavedChanges = newValue }
   }

   var isSaving = false
   var isInitializing = false

   let formInstanceId: UUID

   // MARK: - Form State Properties
   var date: Date = .now
   var wakeTime: Date = .now
   var glucose: Double? = nil
   var ketones: Double? = nil
   var bloodPressure: String? = nil
   var weight: Double? = nil
   var sleepTime: String? = nil
   var stressLevel: Int? = nil
   var walkedAM: Bool = false
   var walkedPM: Bool = false
   var firstMealTime: Date? = nil
   var lastMealTime: Date? = nil
   var steps: Int? = nil
   var wentToGym: Bool = false
   var rlt: String? = nil
   var weatherData: String? = nil
   var notes: String? = nil

   var formValues: [String: Any] {
	  [
		 "glucose": glucose as Any,
		 "ketones": ketones as Any,
		 "bloodPressure": bloodPressure as Any,
		 "weight": weight as Any,
		 "sleepTime": sleepTime as Any,
		 "stressLevel": stressLevel as Any,
		 "walkedAM": walkedAM,
		 "walkedPM": walkedPM,
		 "firstMealTime": firstMealTime as Any,
		 "lastMealTime": lastMealTime as Any,
		 "steps": steps as Any,
		 "wentToGym": wentToGym,
		 "rlt": rlt as Any,
		 "notes": notes as Any
	  ]
   }

   var formValuesString: String {
   """
   glucose:\(String(describing: glucose))
   ketones:\(String(describing: ketones))
   bloodPressure:\(String(describing: bloodPressure))
   weight:\(String(describing: weight))
   sleepTime:\(String(describing: sleepTime))
   stressLevel:\(String(describing: stressLevel))
   walkedAM:\(walkedAM)
   walkedPM:\(walkedPM)
   firstMealTime:\(String(describing: firstMealTime))
   lastMealTime:\(String(describing: lastMealTime))
   steps:\(String(describing: steps))
   wentToGym:\(wentToGym)
   rlt:\(String(describing: rlt))
   notes:\(String(describing: notes))
   """
   }

   // MARK: - Initialization

   /// Initializes the ViewModel with the given SwiftData context, optionally loading an existing entry.
   /// - Parameters:
   ///   - context: The ModelContext provided by SwiftData.
   ///   - existingEntry: An optional existing DailyHealthEntry to edit.
   init(context: ModelContext, existingEntry: DailyHealthEntry? = nil) {
	  self.context = context
	  self.existingEntry = existingEntry
	  self.formInstanceId = existingEntry?.id ?? UUID() // Use existing entry's ID or a new UUID for new entries

	  // Original logging for debugging:
	  // logger.debug("BigPlanViewModel initialized. Has existingEntry: \(existingEntry != nil, privacy: .public), ID: \(existingEntry?.id.uuidString ?? "N/A", privacy: .public), FormInstanceID: \(self.formInstanceId.uuidString, privacy: .public)")
	  self.isInitializing = true
	  logger.debug("BigPlanViewModel init: isInitializing synchronously set to true. FormInstanceID: \(self.formInstanceId.uuidString, privacy: .public)")


	  Task {

		 if let entry = existingEntry {
			self.date = entry.date
			self.wakeTime = entry.wakeTime
			self.glucose = entry.glucose
			self.ketones = entry.ketones
			self.bloodPressure = entry.bloodPressure
			self.weight = entry.weight
			self.sleepTime = entry.sleepTime
			self.stressLevel = entry.stressLevel
			self.walkedAM = entry.walkedAM
			self.walkedPM = entry.walkedPM
			self.firstMealTime = entry.firstMealTime
			self.lastMealTime = entry.lastMealTime
			self.steps = entry.steps
			self.wentToGym = entry.wentToGym
			self.rlt = entry.rlt
			self.weatherData = entry.weatherData
			self.notes = entry.notes
			logger.debug("Populating VM from existingEntry ID: \(entry.id.uuidString, privacy: .public)")
		 } else {
			logger.debug("Populating VM for a new entry.")
		 }


		 let healthKitAuthorization = await HealthKitManager.shared.requestAuthorization()
		 self.healthKitAuthorized = healthKitAuthorization
		 if healthKitAuthorization && existingEntry == nil {
			await fetchTodaySteps()
		 }
		 if existingEntry == nil || Calendar.current.isDateInToday(date) {
			// Ensure weather is only fetched if not already loaded recently for this entry,
			// or if it's a new entry for today.
			// The current weatherData check might be insufficient.
			await fetchAndAppendWeather()
		 }
		 // Ensure isInitializing is set to false after all async operations are complete.
		 self.isInitializing = false
		 logger.debug("BigPlanViewModel async setup complete: isInitializing set to false. FormInstanceID: \(self.formInstanceId.uuidString, privacy: .public)")
	  }
   }

   // MARK: - CRUD Methods

   /// Saves the current form values as a new `DailyHealthEntry`.
   func saveEntry() {
	  Task {
		 isSaving = true
		 defer { isSaving = false }

		 do {
			let entryToSave: DailyHealthEntry // Use a clear name

			if let currentEntry = self.existingEntry {
			   entryToSave = currentEntry
			   // Update properties of 'entryToSave' (which is self.existingEntry)
			   entryToSave.date = date
			   entryToSave.wakeTime = wakeTime
			   entryToSave.glucose = glucose
			   entryToSave.ketones = ketones
			   entryToSave.bloodPressure = bloodPressure
			   entryToSave.weight = weight
			   entryToSave.sleepTime = sleepTime
			   entryToSave.stressLevel = stressLevel
			   entryToSave.walkedAM = walkedAM
			   entryToSave.walkedPM = walkedPM
			   entryToSave.firstMealTime = firstMealTime
			   entryToSave.lastMealTime = lastMealTime
			   entryToSave.steps = steps
			   entryToSave.wentToGym = wentToGym
			   entryToSave.rlt = rlt
			   // Only update weather if it was freshly fetched by this VM instance
			   // This check might need refinement based on how/when weatherData is populated.
			   // If weatherData is nil-ed out on form load and re-fetched, this is fine.
			   entryToSave.weatherData = weatherData
			   entryToSave.notes = notes
			} else {
			   // This is the path for a NEW entry
			   entryToSave = DailyHealthEntry(
				  date: date,
				  wakeTime: wakeTime,
				  glucose: glucose,
				  ketones: ketones,
				  bloodPressure: bloodPressure,
				  weight: weight,
				  sleepTime: sleepTime,
				  stressLevel: stressLevel,
				  walkedAM: walkedAM,
				  walkedPM: walkedPM,
				  firstMealTime: firstMealTime,
				  lastMealTime: lastMealTime,
				  steps: steps,
				  wentToGym: wentToGym,
				  rlt: rlt,
				  weatherData: weatherData,
				  notes: notes
			   )
			   context.insert(entryToSave)
			   self.existingEntry = entryToSave
			}

			logger.info("💾 Attempting to save entry: \(entryToSave.id)")
			try context.save()
			logger.info("✅ Save successful")

			let descriptor = FetchDescriptor<DailyHealthEntry>()
			let savedEntries = try context.fetch(descriptor)
			logger.info("📊 Total entries after save: \(savedEntries.count)")
			_hasUnsavedChanges = false  // Reset after successful save
		 } catch {
			logger.error("❌ Save failed: \(error.localizedDescription)")
		 }
	  }
   }

   /// Deletes the specified `DailyHealthEntry` from persistence.
   /// - Parameter entry: The entry to delete.
   func delete(_ entry: DailyHealthEntry) {
	  do {
		 context.delete(entry)
		 try context.save()
		 logger.info("✅ Entry deleted and saved: \(entry.id)")
	  } catch {
		 logger.error("❌ Failed to delete entry: \(error.localizedDescription)")
	  }
   }

   /// Deletes the currently loaded DailyHealthEntry if this ViewModel was initialized in edit mode.
   func deleteThisEntry() {
	  if let entry = existingEntry {
		 do {
			context.delete(entry)
			try context.save()
			logger.info("✅ Current entry deleted and saved: \(entry.id)")
			self.existingEntry = nil // Clear it after deletion
		 } catch {
			logger.error("❌ Failed to delete current entry: \(error.localizedDescription)")
		 }
	  }
   }

   func requestHealthKitAuthorization() async {
	  self.healthKitAuthorized = await HealthKitManager.shared.requestAuthorization()
	  if healthKitAuthorized {
		 await fetchTodaySteps()
	  }
   }

   func fetchTodaySteps() async {
	  // When refreshing steps, we want to fetch regardless of existing value
	  await HealthKitManager.shared.fetchTodaySteps()

	  let currentHKSteps = HealthKitManager.shared.todaySteps
	  if currentHKSteps > 0 {
		 self.steps = currentHKSteps
	  } else {
		 if self.steps == nil {
			self.steps = 0
		 }
	  }
   }

   func fetchAndAppendWeather() async {
	  // If we're editing an entry not for today and it already has weather, don't overwrite.
	  if let existing = existingEntry, !Calendar.current.isDateInToday(existing.date), existing.weatherData != nil {
		 return
	  }
	  // If it's a new entry, or today's entry, or an old entry without weather, try to fetch.
	  // Also prevent re-fetching if weather is already loaded in this VM session and it's not a new day.
	  guard !isWeatherLoaded || existingEntry == nil || Calendar.current.isDateInToday(date) else { return }


	  isLoadingWeather = true
	  defer { isLoadingWeather = false }

	  if let location = LocationManager.shared.location {
		 await WeatherKitManager.shared.fetchWeather(for: location)
		 if let weatherString = WeatherKitManager.shared.weatherData {
			self.weatherData = weatherString
			isWeatherLoaded = true // Mark that weather has been loaded in this VM session

			// saveEntry()
			return
		 }
	  }

	  if LocationManager.shared.authorizationStatus == .notDetermined {
		 LocationManager.shared.requestAuthorization()
	  }

	  LocationManager.shared.startUpdatingLocation()
   }


   /// Verifies the data store content for debugging purposes.
   func verifyDataStore() {
	  do {
		 // Make SURE self is used for entries
		 logger.info("📋 BigPlanViewModel verification - Found \(self.entries.count) entries via computed property")

		 // Make SURE self is used for entries before forEach
		 self.entries.forEach { entry in
			// Logger is a static property, doesn't need self
			logger.info("🔍 ViewModel Entry found - ID: \(entry.id) Date: \(entry.date) Glucose: \(entry.glucose ?? 0)")
		 }

		 // Optional: Explicit fetch to compare, if desired
		 let descriptor = FetchDescriptor<DailyHealthEntry>()
		 // Make SURE self is used for context
		 let fetchedEntries = try self.context.fetch(descriptor)
		 logger.info("🔄 ViewModel verification - Found \(fetchedEntries.count) entries via explicit fetch")

	  } catch {
		 logger.error("❌ Failed to verify data store from ViewModel: \(error.localizedDescription)")
	  }
   }

   /// Indicates whether this view model is editing an existing entry.
   var isEditing: Bool {
	  return existingEntry != nil
   }
}
