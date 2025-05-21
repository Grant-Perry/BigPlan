import OSLog
private let logger = Logger(subsystem: "BigPlan", category: "SwiftData")
import Foundation
import SwiftUI
import SwiftData

/** View for the main tab layout. Business logic is delegated to
 ``BigPlanTabViewModel`` to keep this view lightweight. */

struct BigPlanTabView: View {
   let modelContext: ModelContext
   @StateObject private var tabViewModel: BigPlanTabViewModel
   
   init(modelContext: ModelContext) {
	  self.modelContext = modelContext
	  _tabViewModel = StateObject(wrappedValue: BigPlanTabViewModel(context: modelContext))
   }
   
   @Query private var allEntries: [DailyHealthEntry]
   
   var body: some View {
	  TabView(selection: $tabViewModel.selectedTab) {
		 NavigationStack {
			DailyListView(selectedTab: $tabViewModel.selectedTab)
		 }
		 .tabItem {
			Label("History", systemImage: "clock")
		 }
		 .tag(0)
		 
		 Group {
			if let currentViewModel = tabViewModel.formViewModel {
			   NavigationStack {
				  DailyFormView(
					 selectedTab: $tabViewModel.selectedTab,
					 bigPlanViewModel: currentViewModel
				  )
				  .id(tabViewModel.dailyFormViewId)
			   }
			} else {
			   ProgressView().onAppear {
				  logger.error("DailyFormView attempted to render with a nil viewModel for tab 1.")
				  if tabViewModel.selectedTab == 1 {
					 tabViewModel.initializeViewModelForTab1()
				  }
			   }
			}
		 }
		 .tabItem {
			if tabViewModel.todayEntryExists {
			   Label("Edit Today", systemImage: "pencil.circle")
			} else {
			   Label("New Entry", systemImage: "plus.circle")
			}
		 }
		 .tag(1)
	  }
	  .onAppear {
		 tabViewModel.checkForTodaysEntry()
		 if tabViewModel.selectedTab == 1 && tabViewModel.formViewModel == nil {
			tabViewModel.initializeViewModelForTab1()
		 }
	  }
	  .onChange(of: tabViewModel.selectedTab) { oldValue, newValue in
		 if newValue == 1 {
			logger.debug("Switched to Tab 1 (New/Edit).")
			tabViewModel.initializeViewModelForTab1()
		 } else if newValue == 0 {
			logger.debug("Switched to Tab 0 (History).")
			tabViewModel.checkForTodaysEntry()
		 }
	  }
	  .onChange(of: allEntries.count) { _, _ in
		 logger.debug("Entries count changed. Re-checking for today's entry.")
		 tabViewModel.checkForTodaysEntry()
	  }
   }
   
}
