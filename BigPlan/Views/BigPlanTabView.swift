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
	  logger.debug("BigPlanTabView.init() called")
	  self.modelContext = modelContext
	  _tabViewModel = StateObject(wrappedValue: BigPlanTabViewModel(context: modelContext))
   }
   
   var body: some View {
	  TabView(selection: $tabViewModel.selectedTab) {
		 NavigationStack {
			DailyListView(selectedTab: $tabViewModel.selectedTab)
		 }
		 .tabItem {
			Label("History", systemImage: "clock")
		 }
		 .tag(0)
		 
		 NavigationStack {
			ImportView(selectedTab: $tabViewModel.selectedTab)
		 }
		 .tabItem {
			Label("Import", systemImage: "square.and.arrow.down")
		 }
		 .tag(1)
	  }
	  .onAppear {
		 logger.debug("TabView appeared, checking for today's entry")
		 tabViewModel.checkForTodaysEntry()
	  }
	  .onChange(of: tabViewModel.selectedTab) { _, newValue in
		 if newValue == 0 {
			logger.debug("Switched to Tab 0 (History).")
			tabViewModel.checkForTodaysEntry()
		 }
	  }
   }
}
