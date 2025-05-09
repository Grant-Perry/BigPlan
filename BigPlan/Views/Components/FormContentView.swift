import SwiftUI

struct FormContentView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @Binding var selectedTab: Int

   var body: some View {
	  VStack(spacing: 24) {
		 ReadingsView(bigPlanViewModel: bigPlanViewModel)
		 SleepStressView(bigPlanViewModel: bigPlanViewModel)
		 ActivityView(bigPlanViewModel: bigPlanViewModel)
		 MealsView(bigPlanViewModel: bigPlanViewModel)
		 NotesView(bigPlanViewModel: bigPlanViewModel)
		 ActionButtonsView(
			bigPlanViewModel: bigPlanViewModel,
			selectedTab: $selectedTab
		 )
	  }
	  .padding(.horizontal)
   }
}
