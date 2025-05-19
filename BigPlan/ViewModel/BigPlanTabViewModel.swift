import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "BigPlan", category: "TabViewModel")

@MainActor
class BigPlanTabViewModel: ObservableObject {
   private let context: ModelContext

   @Published var selectedTab: Int = 0
   @Published var formViewModel: BigPlanViewModel?
   @Published var todayEntryExists: Bool = false
   @Published var entryForToday: DailyHealthEntry? = nil
   @Published var dailyFormViewId: UUID = UUID()

   init(context: ModelContext) {
	  self.context = context
   }

   func initializeViewModelForTab1() {
	  checkForTodaysEntry()
	  let oldId = formViewModel?.formInstanceId

	  if let existingEntry = entryForToday {
		 logger.debug("Today's entry FOUND (ID: \(existingEntry.id.uuidString, privacy: .public)). Creating/updating viewModel FOR EDITING.")
		 formViewModel = BigPlanViewModel(context: context, existingEntry: existingEntry)
	  } else {
		 logger.debug("Today's entry NOT found. Creating/updating viewModel FOR NEW entry.")
		 formViewModel = BigPlanViewModel(context: context)
	  }

	  if oldId != formViewModel?.formInstanceId || (formViewModel != nil && dailyFormViewId != formViewModel!.formInstanceId) {
		 dailyFormViewId = formViewModel?.formInstanceId ?? UUID()
		 logger.debug("DailyFormView ID updated to: \(self.dailyFormViewId.uuidString, privacy: .public)")
	  }

	  if let vm = formViewModel {
		 logger.debug("ViewModel for Tab 1. isEditing: \(vm.isEditing, privacy: .public), VM_ID: \(vm.formInstanceId.uuidString, privacy: .public)")
	  } else {
		 logger.error("ViewModel is unexpectedly nil after initializeViewModelForTab1.")
	  }
   }

   func checkForTodaysEntry() {
	  let calendar = Calendar.current
	  let today = calendar.startOfDay(for: Date())
	  let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

	  let predicate = #Predicate<DailyHealthEntry> { entry in
		 entry.date >= today && entry.date < tomorrow
	  }
	  let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\DailyHealthEntry.date, order: .reverse)])

	  do {
		 let entriesForToday = try context.fetch(descriptor)
		 if let firstEntry = entriesForToday.first {
			if entryForToday?.id != firstEntry.id || entryForToday == nil {
			   logger.debug("Found/Updated entry for today: ID \(firstEntry.id.uuidString, privacy: .public)")
			}
			entryForToday = firstEntry
			todayEntryExists = true
		 } else {
			if entryForToday != nil {
			   logger.debug("No entry found for today (was previously set or just deleted). Resetting state.")
			}
			entryForToday = nil
			todayEntryExists = false
		 }
	  } catch {
		 logger.error("Failed to fetch today's entry: \(error.localizedDescription)")
		 entryForToday = nil
		 todayEntryExists = false
	  }
   }
}
