import SwiftUI

struct FormContentView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @Binding var selectedTab: Int
   @Binding var liveSteps: Int

   var body: some View {
	  VStack(spacing: 24) {
		 ReadingsView(bigPlanViewModel: bigPlanViewModel)
		 SleepStressView(bigPlanViewModel: bigPlanViewModel)
		 ActivityView(bigPlanViewModel: bigPlanViewModel, liveSteps: $liveSteps)
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
