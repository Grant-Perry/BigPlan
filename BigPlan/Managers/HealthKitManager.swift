import Foundation
import HealthKit
import OSLog

private let logger = Logger(subsystem: "BigPlan", category: "HealthKitManager")

@MainActor
class HealthKitManager: ObservableObject {
   let healthStore = HKHealthStore()
   @Published var todaySteps: Int = 0

   static let shared = HealthKitManager()

   private init() {}

   func requestAuthorization() async -> Bool {
	  guard HKHealthStore.isHealthDataAvailable() else {
		 logger.error("HealthKit is not available on this device")
		 return false
	  }

	  let stepsQuantityType = HKQuantityType(.stepCount)

	  do {
		 try await healthStore.requestAuthorization(
			toShare: [],
			read: [stepsQuantityType]
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
}
