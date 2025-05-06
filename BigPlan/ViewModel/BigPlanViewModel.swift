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

   var healthKitAuthorized = false

   var isWeatherLoaded: Bool = false
   var isLoadingWeather: Bool = false

   // ADD: Track if any changes were made since last save
   private var _hasUnsavedChanges: Bool = false

   var hasUnsavedChanges: Bool {
	  get { _hasUnsavedChanges }
	  set { _hasUnsavedChanges = newValue }
   }

   // MARK: - Form State Properties with Change Tracking

   var date: Date = .now {
	  didSet { _hasUnsavedChanges = true }
   }
   var wakeTime: Date = .now {
	  didSet { _hasUnsavedChanges = true }
   }
   var glucose: Double? = nil {
	  didSet { _hasUnsavedChanges = true }
   }
   var ketones: Double? = nil {
	  didSet { _hasUnsavedChanges = true }
   }
   var bloodPressure: String? = nil {
	  didSet { _hasUnsavedChanges = true }
   }
   var weight: Double? = nil {
	  didSet { _hasUnsavedChanges = true }
   }
   var sleepTime: String? = nil {
	  didSet { _hasUnsavedChanges = true }
   }
   var stressLevel: Int? = nil {
	  didSet { _hasUnsavedChanges = true }
   }
   var walkedAM: Bool = false {
	  didSet { _hasUnsavedChanges = true }
   }
   var walkedPM: Bool = false {
	  didSet { _hasUnsavedChanges = true }
   }
   var firstMealTime: Date? = nil {
	  didSet { _hasUnsavedChanges = true }
   }
   var lastMealTime: Date? = nil {
	  didSet { _hasUnsavedChanges = true }
   }
   var steps: Int? = nil {
	  didSet { _hasUnsavedChanges = true }
   }
   var wentToGym: Bool = false {
	  didSet { _hasUnsavedChanges = true }
   }
   var rlt: String? = nil {
	  didSet { _hasUnsavedChanges = true }
   }
   var weatherData: String? = nil {
	  didSet { _hasUnsavedChanges = true }
   }
   var notes: String? = nil {
	  didSet { _hasUnsavedChanges = true }
   }

   // MARK: - Initialization

   /// Initializes the ViewModel with the given SwiftData context, optionally loading an existing entry.
   /// - Parameters:
   ///   - context: The ModelContext provided by SwiftData.
   ///   - existingEntry: An optional existing DailyHealthEntry to edit.
   init(context: ModelContext, existingEntry: DailyHealthEntry? = nil) {
	  self.context = context
	  self.existingEntry = existingEntry
	  _hasUnsavedChanges = false  // Start with no unsaved changes

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
	  }

	  Task {
		 healthKitAuthorized = await HealthKitManager.shared.requestAuthorization()
		 if healthKitAuthorized && existingEntry == nil {
			await fetchTodaySteps()
		 }
		 if existingEntry == nil || Calendar.current.isDateInToday(date) {
			await fetchAndAppendWeather()
		 }
	  }
   }

   // MARK: - CRUD Methods

   /// Saves the current form values as a new `DailyHealthEntry`.
   func saveEntry() {
	  do {
		 let entry: DailyHealthEntry

		 if let existingEntry = self.existingEntry {
			entry = existingEntry
			entry.date = date
			entry.wakeTime = wakeTime
			entry.glucose = glucose
			entry.ketones = ketones
			entry.bloodPressure = bloodPressure
			entry.weight = weight
			entry.sleepTime = sleepTime
			entry.stressLevel = stressLevel
			entry.walkedAM = walkedAM
			entry.walkedPM = walkedPM
			entry.firstMealTime = firstMealTime
			entry.lastMealTime = lastMealTime
			entry.steps = steps
			entry.wentToGym = wentToGym
			entry.rlt = rlt
			entry.weatherData = weatherData
			entry.notes = notes
		 } else {
			entry = DailyHealthEntry(
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
			context.insert(entry)
		 }

		 logger.info("💾 Attempting to save entry: \(entry.id)")
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
		 } catch {
			logger.error("❌ Failed to delete current entry: \(error.localizedDescription)")
		 }
	  }
   }

   func requestHealthKitAuthorization() async {
	  healthKitAuthorized = await HealthKitManager.shared.requestAuthorization()
	  if healthKitAuthorized {
		 await fetchTodaySteps()
	  }
   }

   func fetchTodaySteps() async {
	  await HealthKitManager.shared.fetchTodaySteps()
	  self.steps = HealthKitManager.shared.todaySteps
   }

   func fetchAndAppendWeather() async {
	  // If we're not editing today's entry and we've already loaded weather, skip
	  guard !isWeatherLoaded || existingEntry != nil || Calendar.current.isDateInToday(date) else { return }

	  isLoadingWeather = true
	  defer { isLoadingWeather = false }

	  // If location is already available, use it immediately
	  if let location = LocationManager.shared.location {
		 await WeatherKitManager.shared.fetchWeather(for: location)
		 if let weatherString = WeatherKitManager.shared.weatherData {
			self.weatherData = weatherString
			isWeatherLoaded = true

			// Save immediately after updating weather
			saveEntry()
			return
		 }
	  }

	  // Only request location if we need it
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
