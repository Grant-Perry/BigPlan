import OSLog
private let logger = Logger(subsystem: "BigPlan", category: "SwiftData")
import Foundation
import SwiftUI
import SwiftData

struct BigPlanTabView: View {
   @Environment(\.modelContext) private var modelContext
   @State private var selectedTab = 0
   @State private var viewModel: BigPlanViewModel?

   @State private var todayEntryExists: Bool = false
   @State private var entryForToday: DailyHealthEntry? = nil

   @State private var dailyFormViewId: UUID = UUID()

   @Query private var allEntries: [DailyHealthEntry]

   var body: some View {
	  TabView(selection: $selectedTab) {
		 DailyListView(selectedTab: $selectedTab)
			.tabItem {
			   Label("History", systemImage: "clock")
			}
			.tag(0)

		 Group {
			if let currentViewModel = viewModel {
			   DailyFormView(
				  selectedTab: $selectedTab,
				  bigPlanViewModel: currentViewModel
			   )
			   .id(dailyFormViewId)
			} else {
			   ProgressView().onAppear {
				  logger.error("DailyFormView attempted to render with a nil viewModel for tab 1.")
				  if selectedTab == 1 {
					 initializeViewModelForTab1()
				  }
			   }
			}
		 }
		 .tabItem {
			if todayEntryExists {
			   Label("Edit Today", systemImage: "pencil.circle")
			} else {
			   Label("New Entry", systemImage: "plus.circle")
			}
		 }
		 .tag(1)
	  }
	  .onAppear {
		 checkForTodaysEntry()
		 if selectedTab == 1 && viewModel == nil {
			initializeViewModelForTab1()
		 }
	  }
	  .onChange(of: selectedTab) { oldValue, newValue in
		 if newValue == 1 {
			logger.debug("Switched to Tab 1 (New/Edit).")
			initializeViewModelForTab1()
		 } else if newValue == 0 {
			logger.debug("Switched to Tab 0 (History).")
			checkForTodaysEntry()
		 }
	  }
	  .onChange(of: allEntries.count) { _, _ in
		 logger.debug("Entries count changed. Re-checking for today's entry.")
		 checkForTodaysEntry()
	  }
   }

   private func initializeViewModelForTab1() {
	  checkForTodaysEntry()
	  let oldViewModelId = viewModel?.formInstanceId

	  if let existingEntry = entryForToday {
		 logger.debug("Today's entry FOUND (ID: \(existingEntry.id.uuidString, privacy: .public)). Creating/updating viewModel FOR EDITING.")
		 viewModel = BigPlanViewModel(context: modelContext, existingEntry: existingEntry)
	  } else {
		 logger.debug("Today's entry NOT found. Creating/updating viewModel FOR NEW entry.")
		 viewModel = BigPlanViewModel(context: modelContext)
	  }

	  if oldViewModelId != viewModel?.formInstanceId || (viewModel != nil && dailyFormViewId != viewModel!.formInstanceId) {
		 dailyFormViewId = viewModel?.formInstanceId ?? UUID()
		 logger.debug("DailyFormView ID updated to: \(dailyFormViewId.uuidString, privacy: .public)")
	  }

	  if let vm = viewModel {
		 logger.debug("ViewModel for Tab 1. isEditing: \(vm.isEditing, privacy: .public), VM_ID: \(vm.formInstanceId.uuidString, privacy: .public)")
	  } else {
		 logger.error("ViewModel is unexpectedly nil after initializeViewModelForTab1.")
	  }
   }

   private func checkForTodaysEntry() {
	  let calendar = Calendar.current
	  let today = calendar.startOfDay(for: Date())
	  let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

	  let predicate = #Predicate<DailyHealthEntry> { entry in
		 entry.date >= today && entry.date < tomorrow
	  }
	  let descriptor = FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.date, order: .reverse)])

	  do {
		 let entriesForToday = try modelContext.fetch(descriptor)
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
