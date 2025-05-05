import OSLog
private let logger = Logger(subsystem: "BigPlan", category: "SwiftData")
import Foundation
import SwiftUI
import SwiftData

struct BigPlanTabView: View {
   @Environment(\.modelContext) private var modelContext
   @State private var selectedTab = 0
   @State private var viewModel: BigPlanViewModel?

   var body: some View {
	  TabView(selection: $selectedTab) {
		 DailyListView(selectedTab: $selectedTab)
			.tabItem {
			   Label("History", systemImage: "clock")
			}
			.tag(0)

		 DailyFormView(
			selectedTab: $selectedTab,
			bigPlanViewModel: viewModel ?? BigPlanViewModel(context: modelContext)
		 )
		 .tabItem {
			Label("New Entry", systemImage: "plus.circle")
		 }
		 .tag(1)
	  }
	  .onChange(of: selectedTab) { oldValue, newValue in
		 if newValue == 1 {
			// Create fresh ViewModel when switching to form tab
			viewModel = BigPlanViewModel(context: modelContext)
		 }
	  }
   }
}
