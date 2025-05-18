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
	  let startOfDay = Calendar.current.startOfDay(for: date)
	  guard let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }
	  
	  let predicate = HKQuery.predicateForSamples(
		 withStart: startOfDay,
		 end: endOfDay
	  )
	  
	  do {
		 let sleepSamples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
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
			   continuation.resume(returning: samples ?? [])
			}
			self.healthStore.execute(query)
		 }
		 
		 if let sample = sleepSamples.first {
			let sleepDuration = sample.endDate.timeIntervalSince(sample.startDate)
			let hours = Int(sleepDuration / 3600)
			let minutes = Int((sleepDuration.truncatingRemainder(dividingBy: 3600)) / 60)
			return "\(hours)h \(minutes)m"
		 }
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
   
   func fetchHeartRate(for date: Date) async -> Double? {
	  let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
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
			   sampleType: heartRateType,
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
			return sample.quantity.doubleValue(for: .init(from: "count/min"))
		 }
		 return nil
	  } catch {
		 logger.error("Failed to fetch heart rate: \(error.localizedDescription)")
		 return nil
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
}
