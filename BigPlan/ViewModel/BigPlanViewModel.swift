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
   
   var existingEntry: DailyHealthEntry?
   
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
   
   var weekStepsTotal: Int {
	  let calendar = Calendar.current
	  let today = calendar.startOfDay(for: .now)
	  let allEntries = entries
	  var total = 0
	  for offset in 0..<7 {
		 if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
			if let entry = allEntries.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
			   total += entry.steps ?? 0
			}
		 }
	  }
	  return total
   }
   
   var weekStepsTotal1: Int {
	  let calendar = Calendar.current
	  let today = calendar.startOfDay(for: .now)
	  let allEntries = entries
	  var total = 0
	  for offset in 0..<7 {
		 if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
			if let entry = allEntries.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
			   total += entry.steps ?? 0
			}
		 }
	  }
	  return total
   }
   
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
   var heartRate: Double? = nil
   
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
   
   // MARK: - Weight Comparison Properties
   var lastEntryWeight: Double? {
	  // Skip the current entry if we're editing
	  let currentEntryId = existingEntry?.id
	  
	  let descriptor = FetchDescriptor<DailyHealthEntry>(
		 sortBy: [SortDescriptor(\DailyHealthEntry.date, order: .reverse)]
	  )
	  
	  if let entries = try? context.fetch(descriptor) {
		 // Find the last entry that has a weight and isn't the current entry
		 return entries.first { entry in
			entry.id != currentEntryId && entry.weight != nil
		 }?.weight
	  }
	  return nil
   }
   
   var goalWeight: Double? {
	  let descriptor = FetchDescriptor<Settings>()
	  return try? context.fetch(descriptor).first?.weightTarget ?? 100.0
   }
   
   var weightDiffFromLastEntry: (diff: Double, isUp: Bool)? {
	  guard let currentWeight = weight,
			let lastWeight = lastEntryWeight else { return nil }
	  let diff = currentWeight - lastWeight
	  return (abs(diff), diff > 0)
   }
   
   var weightDiffFromGoal: (diff: Double, isUp: Bool)? {
	  guard let currentWeight = weight,
			let goalWeight = goalWeight else { return nil }
	  let diff = currentWeight - goalWeight
	  return (abs(diff), diff > 0)
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
			self.heartRate = entry.heartRate // CRITICAL FOR FORM PREFILL
			logger.debug("Populating VM from existingEntry ID: \(entry.id.uuidString, privacy: .public)")
			if entry.weekTotalSteps == nil {
			   entry.weekTotalSteps = calculateWeekSteps(for: entry.date)
			   do { try context.save() } catch { }
			}
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
			let entryToSave: DailyHealthEntry
			
			if let currentEntry = self.existingEntry {
			   entryToSave = currentEntry
			   // Copy over ALL properties each save (don't lose fields!)
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
			   entryToSave.weekTotalSteps = calculateWeekSteps(for: date)
			   entryToSave.heartRate = heartRate
			} else {
			   // Full model for NEW entry
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
				  notes: notes,
				  weekTotalSteps: calculateWeekSteps(for: date),
				  heartRate: heartRate
			   )
			   context.insert(entryToSave)
			   self.existingEntry = entryToSave
			}
			
			logger.info(" Attempting to save entry: \(entryToSave.id)")
			try context.save()
			logger.info(" Save successful")
			
			let descriptor = FetchDescriptor<DailyHealthEntry>()
			let savedEntries = try context.fetch(descriptor)
			logger.info(" Total entries after save: \(savedEntries.count)")
			_hasUnsavedChanges = false  // Reset after successful save
		 } catch {
			logger.error(" Save failed: \(error.localizedDescription)")
		 }
	  }
   }
   
   /// Deletes the specified `DailyHealthEntry` from persistence.
   /// - Parameter entry: The entry to delete.
   func delete(_ entry: DailyHealthEntry) {
	  do {
		 context.delete(entry)
		 try context.save()
		 logger.info(" Entry deleted and saved: \(entry.id)")
	  } catch {
		 logger.error(" Failed to delete entry: \(error.localizedDescription)")
	  }
   }
   
   /// Deletes the currently loaded DailyHealthEntry if this ViewModel was initialized in edit mode.
   func deleteThisEntry() {
	  if let entry = existingEntry {
		 do {
			context.delete(entry)
			try context.save()
			logger.info(" Current entry deleted and saved: \(entry.id)")
			self.existingEntry = nil // Clear it after deletion
		 } catch {
			logger.error(" Failed to delete current entry: \(error.localizedDescription)")
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
			return
		 }
	  }
	  
	  if LocationManager.shared.authorizationStatus == .notDetermined {
		 LocationManager.shared.requestAuthorization()
	  }
	  
	  LocationManager.shared.startUpdatingLocation()
   }
   
   /// Fetch step count for a date (async, HK)
   private func fetchSteps(for date: Date) async -> Int {
	  await HealthKitManager.shared.steps(for: date)
   }
   
   private func createEntryWithHealthKitData(for date: Date, steps: Int) async -> DailyHealthEntry {
	  async let hkGlucose = HealthKitManager.shared.bloodGlucose(for: date)
	  async let hkSleep = HealthKitManager.shared.fetchSleepAnalysis(for: date)
	  async let hkHeartRate = HealthKitManager.shared.fetchHeartRate(for: date)
	  
	  let glucose = await hkGlucose
	  let sleep = await hkSleep
	  let heartRate = await hkHeartRate
	  
	  let entry = DailyHealthEntry(
		 date: date,
		 wakeTime: date,
		 glucose: glucose,
		 ketones: nil,
		 bloodPressure: nil,
		 weight: nil,
		 sleepTime: sleep,
		 stressLevel: nil,
		 walkedAM: false,
		 walkedPM: false,
		 firstMealTime: nil,
		 lastMealTime: nil,
		 steps: steps,
		 wentToGym: false,
		 rlt: nil,
		 weatherData: nil,
		 notes: nil,
		 weekTotalSteps: calculateWeekSteps(for: date),
		 heartRate: heartRate
	  )
	  
	  entry.hkUpdatedGlucose = (glucose != nil)
	  entry.hkUpdatedSleepTime = (sleep != nil)
	  entry.hkUpdatedHeartRate = (heartRate != nil)
	  entry.hkUpdatedSteps = (steps > 0)
	  
	  return entry
   }
   
   /// Auto-create DailyHealthEntry objects for missing days (including today), filling step count from HealthKit.
   func backfillMissingEntries() async {
	  let allDates = entries.map { Calendar.current.startOfDay(for: $0.date) }
	  let today = Calendar.current.startOfDay(for: .now)
	  
	  if allDates.isEmpty {
		 let steps = await fetchSteps(for: today)
		 let entry = await createEntryWithHealthKitData(for: today, steps: steps)
		 context.insert(entry)
		 do {
			try context.save()
			logger.info("Backfilled first (today) entry.")
		 } catch {
			logger.error("Backfill failed: \(error.localizedDescription)")
		 }
		 return
	  }
	  
	  guard let earliest = allDates.min() else { return }
	  
	  var date = earliest
	  var missingDates: [Date] = []
	  
	  while date <= today {
		 if !allDates.contains(date) {
			missingDates.append(date)
		 }
		 guard let next = Calendar.current.date(byAdding: .day, value: 1, to: date) else { break }
		 date = next
	  }
	  
	  guard !missingDates.isEmpty else { return }
	  
	  for missingDate in missingDates {
		 let steps = await fetchSteps(for: missingDate)
		 let entry = await createEntryWithHealthKitData(for: missingDate, steps: steps)
		 context.insert(entry)
	  }
	  
	  do {
		 try context.save()
		 logger.info("Backfilled \(missingDates.count) missing DailyHealthEntry record(s) (including today if needed).")
	  } catch {
		 logger.error("Backfill failed: \(error.localizedDescription)")
	  }
   }
   
   /// Verifies the data store content for debugging purposes.
   func verifyDataStore() {
	  do {
		 logger.info(" BigPlanViewModel verification - Found \(self.entries.count) entries via computed property")
		 
		 self.entries.forEach { entry in
			logger.info(" ViewModel Entry found - ID: \(entry.id) Date: \(entry.date) Glucose: \(entry.glucose ?? 0)")
		 }
		 
		 let descriptor = FetchDescriptor<DailyHealthEntry>()
		 let fetchedEntries = try self.context.fetch(descriptor)
		 logger.info(" ViewModel verification - Found \(fetchedEntries.count) entries via explicit fetch")
		 
	  } catch {
		 logger.error(" Failed to verify data store from ViewModel: \(error.localizedDescription)")
	  }
   }
   
   /// Indicates whether this view model is editing an existing entry.
   var isEditing: Bool {
	  return existingEntry != nil
   }
   
   // MARK: - Internal state to manage source of update (only true during syncWithHealthKit)
   var isSyncingFromHK = false
   
   var hkUpdatedGlucose: Bool {
	  get { existingEntry?.hkUpdatedGlucose ?? false }
	  set { existingEntry?.hkUpdatedGlucose = newValue }
   }
   var hkUpdatedKetones: Bool {
	  get { existingEntry?.hkUpdatedKetones ?? false }
	  set { existingEntry?.hkUpdatedKetones = newValue }
   }
   var hkUpdatedBloodPressure: Bool {
	  get { existingEntry?.hkUpdatedBloodPressure ?? false }
	  set { existingEntry?.hkUpdatedBloodPressure = newValue }
   }
   var hkUpdatedWeight: Bool {
	  get { existingEntry?.hkUpdatedWeight ?? false }
	  set { existingEntry?.hkUpdatedWeight = newValue }
   }
   var hkUpdatedHeartRate: Bool {
	  get { existingEntry?.hkUpdatedHeartRate ?? false }
	  set { existingEntry?.hkUpdatedHeartRate = newValue }
   }
   var hkUpdatedSleepTime: Bool {
	  get { existingEntry?.hkUpdatedSleepTime ?? false }
	  set { existingEntry?.hkUpdatedSleepTime = newValue }
   }
   var hkUpdatedSteps: Bool {
	  get { existingEntry?.hkUpdatedSteps ?? false }
	  set { existingEntry?.hkUpdatedSteps = newValue }
   }
   
   @MainActor
   func syncWithHealthKit(overwrite: Bool) async {
	  let date = self.date
	  isSyncingFromHK = true
	  
	  let steps = await fetchSteps(for: date)
	  let entry = await createEntryWithHealthKitData(for: date, steps: steps)
	  
	  // Update existing entry or view model with new values
	  if let existingEntry = self.existingEntry {
		 if overwrite || existingEntry.glucose == nil {
			existingEntry.glucose = entry.glucose
			existingEntry.hkUpdatedGlucose = entry.hkUpdatedGlucose
			self.glucose = entry.glucose
			self.hkUpdatedGlucose = entry.hkUpdatedGlucose
		 }
		 if overwrite || existingEntry.sleepTime == nil || existingEntry.sleepTime?.isEmpty == true {
			existingEntry.sleepTime = entry.sleepTime
			existingEntry.hkUpdatedSleepTime = entry.hkUpdatedSleepTime
			self.sleepTime = entry.sleepTime
			self.hkUpdatedSleepTime = entry.hkUpdatedSleepTime
		 }
		 if overwrite || existingEntry.heartRate == nil {
			existingEntry.heartRate = entry.heartRate
			existingEntry.hkUpdatedHeartRate = entry.hkUpdatedHeartRate
			self.heartRate = entry.heartRate
			self.hkUpdatedHeartRate = entry.hkUpdatedHeartRate
		 }
		 if overwrite || existingEntry.steps == nil {
			existingEntry.steps = entry.steps
			existingEntry.hkUpdatedSteps = entry.hkUpdatedSteps
			self.steps = entry.steps
			self.hkUpdatedSteps = entry.hkUpdatedSteps
		 }
		 
		 do {
			try context.save()
		 } catch {
			print("DP: Error saving entry: \(error)")
		 }
	  }
	  isSyncingFromHK = false
   }
   
   func calculateWeekSteps(for targetDate: Date) -> Int {
	  let calendar = Calendar.current
	  let allEntries = entries
	  var total = 0
	  for offset in 0..<7 {
		 if let date = calendar.date(byAdding: .day, value: -offset, to: targetDate) {
			if let entry = allEntries.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) {
			   total += entry.steps ?? 0
			}
		 }
	  }
	  return total
   }
   
   /// Fetches the week total steps directly from HealthKit (today + past 6 days)
   func fetchWeekHealthKitTotal() async -> Int {
	  let calendar = Calendar.current
	  let today = calendar.startOfDay(for: .now)
	  var total = 0
	  
	  // Serial execution so steps add up properly
	  for offset in 0..<7 {
		 if let date = calendar.date(byAdding: .day, value: -offset, to: today) {
			let steps = await HealthKitManager.shared.steps(for: date)
			total += steps
		 }
	  }
	  return total
   }
}
