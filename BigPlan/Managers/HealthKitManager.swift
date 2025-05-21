import Foundation
import HealthKit
import OSLog

private let logger = Logger(subsystem: "BigPlan", category: "HealthKitManager")

@MainActor
class HealthKitManager: ObservableObject {
   let healthStore = HKHealthStore()
   
   // MARK: - Supported HealthKit Types
   
   let weight = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
   let bodyFatPercentage = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!
   let bmi = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex)!
   let muscleMass = HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!
   let bmr = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!
   let bloodGlucose = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
   let sleepAnalysis = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
   let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate)!
   let respiratoryRate = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
   
   @Published var todaySteps: Int = 0
   
   static let shared = HealthKitManager()
   
   private init() {}
   
   func requestAuthorization() async -> Bool {
	  guard HKHealthStore.isHealthDataAvailable() else {
		 logger.error("HealthKit is not available on this device")
		 return false
	  }
	  
	  do {
		 try await healthStore.requestAuthorization(
			toShare: [],
			read: [
			   HKQuantityType.quantityType(forIdentifier: .stepCount)!,
			   weight,
			   bodyFatPercentage,
			   bmi,
			   muscleMass,
			   bmr,
			   bloodGlucose,
			   sleepAnalysis,
			   heartRate,
			   respiratoryRate
			]
		 )
		 await fetchTodaySteps()
		 return true
	  } catch {
		 logger.error("Failed to request HealthKit authorization: \(error.localizedDescription)")
		 return false
	  }
   }
   
   func fetchTodaySteps() async {
	  let stepsQuantityType = HKQuantityType(.stepCount)
	  let now = Date()
	  let startOfDay = Calendar.current.startOfDay(for: now)
	  
	  let predicate = HKQuery.predicateForSamples(
		 withStart: startOfDay,
		 end: now
	  )
	  
	  do {
		 let sumOfSteps = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
			let query = HKStatisticsQuery(
			   quantityType: stepsQuantityType,
			   quantitySamplePredicate: predicate,
			   options: .cumulativeSum
			) { _, statistics, error in
			   if let error = error {
				  continuation.resume(throwing: error)
				  return
			   }
			   
			   let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
			   continuation.resume(returning: steps)
			}
			
			healthStore.execute(query)
		 }
		 
		 logger.info("Successfully fetched \(Int(sumOfSteps)) steps for today")
		 self.todaySteps = Int(sumOfSteps)
		 
	  } catch {
		 logger.error("Failed to fetch steps: \(error.localizedDescription)")
	  }
   }
   
   /// Fetch steps for any custom date, returns the value directly
   func steps(for targetDate: Date) async -> Int {
	  let stepsQuantityType = HKQuantityType(.stepCount)
	  let calendar = Calendar.current
	  let startOfDay = calendar.startOfDay(for: targetDate)
	  guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return 0 }
	  
	  let predicate = HKQuery.predicateForSamples(
		 withStart: startOfDay,
		 end: endOfDay
	  )
	  
	  do {
		 let sumOfSteps = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
			let query = HKStatisticsQuery(
			   quantityType: stepsQuantityType,
			   quantitySamplePredicate: predicate,
			   options: .cumulativeSum
			) { _, statistics, error in
			   if let error = error {
				  continuation.resume(throwing: error)
				  return
			   }
			   let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
			   continuation.resume(returning: steps)
			}
			self.healthStore.execute(query)
		 }
		 logger.info("Fetched \(Int(sumOfSteps)) steps for \(startOfDay) directly")
		 return Int(sumOfSteps)
	  } catch {
		 logger.error("Failed to fetch steps: \(error.localizedDescription)")
		 return 0
	  }
   }
   
   /// Fetch steps for a custom date (not just today)
   func fetchSteps(for targetDate: Date) async {
	  let stepsQuantityType = HKQuantityType(.stepCount)
	  let startOfDay = Calendar.current.startOfDay(for: targetDate)
	  guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else { return }
	  
	  let predicate = HKQuery.predicateForSamples(
		 withStart: startOfDay,
		 end: endOfDay
	  )
	  
	  do {
		 let sumOfSteps = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
			let query = HKStatisticsQuery(
			   quantityType: stepsQuantityType,
			   quantitySamplePredicate: predicate,
			   options: .cumulativeSum
			) { _, statistics, error in
			   if let error = error {
				  continuation.resume(throwing: error)
				  return
			   }
			   let steps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
			   continuation.resume(returning: steps)
			}
			self.healthStore.execute(query)
		 }
		 logger.info("Fetched \(Int(sumOfSteps)) steps for \(startOfDay)")
		 self.todaySteps = Int(sumOfSteps)
	  } catch {
		 logger.error("Failed to fetch steps: \(error.localizedDescription)")
		 self.todaySteps = 0
	  }
   }
   
   func fetchSleepAnalysis(for date: Date) async -> String? {
	  let sleepAnalysisType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
	  let calendar = Calendar.current
	  // Look for sleep that ENDED on this date
	  let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) ?? date
	  let startOfDay = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: date)) ?? date
	  
	  logger.debug("Fetching sleep between \(startOfDay) and \(endOfDay)")
	  
	  let predicate = HKQuery.predicateForSamples(
		 withStart: startOfDay,
		 end: endOfDay,
		 options: .strictEndDate
	  )
	  
	  do {
		 let sleepSamples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
			let query = HKSampleQuery(
			   sampleType: sleepAnalysisType,
			   predicate: predicate,
			   limit: HKObjectQueryNoLimit,
			   sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
			) { _, samples, error in
			   if let error = error {
				  continuation.resume(throwing: error)
				  return
			   }
			   continuation.resume(returning: samples as? [HKCategorySample] ?? [])
			}
			self.healthStore.execute(query)
		 }
		 
		 logger.debug("Found \(sleepSamples.count) sleep samples")
		 
		 // Calculate total sleep duration from all sleep samples
		 var totalSleepDuration: TimeInterval = 0
		 for sample in sleepSamples {
			if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
			   totalSleepDuration += sample.endDate.timeIntervalSince(sample.startDate)
			   logger.debug("Sleep sample: \(sample.startDate) to \(sample.endDate), duration: \(sample.endDate.timeIntervalSince(sample.startDate)/3600)h")
			}
		 }
		 
		 if totalSleepDuration > 0 {
			let hours = Int(totalSleepDuration / 3600)
			let minutes = Int((totalSleepDuration.truncatingRemainder(dividingBy: 3600)) / 60)
			let result = "\(hours)h \(minutes)m"
			logger.info("Successfully fetched sleep data for \(date): \(result)")
			return result
		 }
		 
		 logger.info("No sleep data found for \(date)")
		 return nil
	  } catch {
		 logger.error("Failed to fetch sleep analysis: \(error.localizedDescription)")
		 return nil
	  }
   }
   
   func fetchStressLevel(for date: Date) async -> Int? {
	  // Implement stress level fetching logic here
	  return nil
   }
   
   func fetchHeartRateStats(for date: Date) async -> (min: Double?, max: Double?, avg: Double?) {
	  let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
	  let calendar = Calendar.current
	  let startOfDay = calendar.startOfDay(for: date)
	  guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
		 return (nil, nil, nil)
	  }
	  
	  let predicate = HKQuery.predicateForSamples(
		 withStart: startOfDay,
		 end: endOfDay
	  )
	  
	  do {
		 let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics?, Error>) in
			let query = HKStatisticsQuery(
			   quantityType: heartRateType,
			   quantitySamplePredicate: predicate,
			   options: [.discreteMin, .discreteMax, .discreteAverage]
			) { _, statistics, error in
			   if let error = error {
				  continuation.resume(throwing: error)
				  return
			   }
			   continuation.resume(returning: statistics)
			}
			self.healthStore.execute(query)
		 }
		 
		 let minRate = statistics?.minimumQuantity()?.doubleValue(for: .init(from: "count/min"))
		 let maxRate = statistics?.maximumQuantity()?.doubleValue(for: .init(from: "count/min"))
		 let avgRate = statistics?.averageQuantity()?.doubleValue(for: .init(from: "count/min"))
		 
		 return (minRate, maxRate, avgRate)
	  } catch {
		 logger.error("Failed to fetch heart rate stats: \(error.localizedDescription)")
		 return (nil, nil, nil)
	  }
   }
   
   func bloodGlucose(for date: Date) async -> Double? {
	  let bloodGlucoseType = HKQuantityType.quantityType(forIdentifier: .bloodGlucose)!
	  let calendar = Calendar.current
	  let startOfDay = calendar.startOfDay(for: date)
	  guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }
	  let predicate = HKQuery.predicateForSamples(
		 withStart: startOfDay,
		 end: endOfDay
	  )
	  do {
		 let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
			let query = HKSampleQuery(
			   sampleType: bloodGlucoseType,
			   predicate: predicate,
			   limit: 1,
			   sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
			) { _, samples, error in
			   if let error = error {
				  continuation.resume(throwing: error)
				  return
			   }
			   continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
			}
			self.healthStore.execute(query)
		 }
		 if let sample = samples.first {
			// HealthKit glucose is mg/dL by default
			return sample.quantity.doubleValue(for: .init(from: "mg/dL"))
		 }
		 return nil
	  } catch {
		 logger.error("Failed to fetch blood glucose: \(error.localizedDescription)")
		 return nil
	  }
   }
   
   // MARK: - Weight Fetching
   func fetchWeight(for date: Date) async -> Double? {
	  let calendar = Calendar.current
	  let startOfDay = calendar.startOfDay(for: date)
	  guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }
	  
	  let predicate = HKQuery.predicateForSamples(
		 withStart: startOfDay,
		 end: endOfDay
	  )
	  
	  do {
		 let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
			let query = HKSampleQuery(
			   sampleType: weight,
			   predicate: predicate,
			   limit: 1,
			   sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
			) { _, samples, error in
			   if let error = error {
				  continuation.resume(throwing: error)
				  return
			   }
			   continuation.resume(returning: samples as? [HKQuantitySample] ?? [])
			}
			self.healthStore.execute(query)
		 }
		 
		 if let sample = samples.first {
			// Convert to pounds since that's what we use in the app
			return sample.quantity.doubleValue(for: .pound())
		 }
		 return nil
	  } catch {
		 logger.error("Failed to fetch weight: \(error.localizedDescription)")
		 return nil
	  }
   }
}
