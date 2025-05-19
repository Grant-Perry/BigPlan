import SwiftUI
import SwiftData
import OSLog
import HealthKit

private let logger = Logger(subsystem: "BigPlan", category: "SaveDebug")

struct DailyFormView: View {
   @Binding var selectedTab: Int
   @Environment(\.modelContext) private var modelContext
   @StateObject var bigPlanViewModel: BigPlanViewModel
   @Environment(\.dismiss) private var dismiss
   @State private var showingDismissAlert = false
   @State private var isLoading = true
   @State private var liveSteps: Int = 0
   @State private var showingSyncAlert = false

   private func completeAction() {
	  dismiss()
	  selectedTab = 0
   }

   private func handleDismiss() {
	  if bigPlanViewModel.hasUnsavedChanges {
		 showingDismissAlert = true
	  } else {
		 completeAction()
	  }
   }

   var body: some View {
	  NavigationStack {
		 ZStack {
			if isLoading {
			   LoadingView()
			} else {
			   //  MARK: menu bar  at bottom of screen
			   ScrollView {
				  VStack(alignment: .leading, spacing: 4) {
					 // Header with just the date
					 HStack(alignment: .top) {
						Spacer()
						DateDisplayView(date: bigPlanViewModel.date, selectedDate: $bigPlanViewModel.date)
					 }
					 .padding(.horizontal)

					 // Form Content
					 FormContentView(bigPlanViewModel: bigPlanViewModel, selectedTab: $selectedTab, liveSteps: $liveSteps)
						.padding(.horizontal)
						.offset(y: -25)
				  }
			   }
			   .disabled(bigPlanViewModel.isInitializing || bigPlanViewModel.isSaving)
			   .opacity(bigPlanViewModel.isInitializing || bigPlanViewModel.isSaving ? 0.6 : 1.0)
			}

			// Loading Overlay
			if bigPlanViewModel.isInitializing || bigPlanViewModel.isSaving {
			   LoadingView()
			}
		 }
		 .onChange(of: bigPlanViewModel.formValuesString) { _, _ in
			bigPlanViewModel.hasUnsavedChanges = true
		 }
		 .onAppear {
			bigPlanViewModel.hasUnsavedChanges = false
		 }
		 .scrollDismissesKeyboard(.immediately)
		 .navigationBarTitleDisplayMode(.inline)
		 .navigationBarBackButtonHidden(true)
		 .toolbar {
			ToolbarItem(placement: .navigationBarLeading) {
			   Button {
				  handleDismiss()
			   } label: {
				  HStack(spacing: 5) {
					 Image(systemName: "chevron.left")
					 Text("Health History")
				  }
				  .font(.system(size: 23))
			   }
			   .disabled(bigPlanViewModel.isInitializing || bigPlanViewModel.isSaving)
			}
			ToolbarItem(placement: .navigationBarTrailing) {
			   HStack(spacing: 18) {
				  Button("Done") {
					 bigPlanViewModel.steps = liveSteps // SYNC actual steps
					 bigPlanViewModel.saveEntry()
					 completeAction()
				  }
				  .font(.system(size: 23))
				  .disabled(bigPlanViewModel.isInitializing || bigPlanViewModel.isSaving)

				  Button {
					 showingSyncAlert = true
				  } label: {
					 Image(systemName: "arrow.clockwise.circle")
				  }
			   }
			}
		 }
		 .alert("Save Changes?", isPresented: $showingDismissAlert) {
			Button("Don't Save", role: .destructive) {
			   completeAction()
			}
			.font(.system(size: 23))

			Button("Save") {
			   bigPlanViewModel.saveEntry()
			   completeAction()
			}
			.font(.system(size: 23))

			Button("Cancel", role: .cancel) { }
			   .font(.system(size: 23))
		 } message: {
			Text("Would you like to save your changes before exiting?")
			   .font(.system(size: 23))
		 }
		 .alert("Replace existing data?", isPresented: $showingSyncAlert) {
			Button("Fill Empty Only") {
			   Task {
				  await self.bigPlanViewModel.syncWithHealthKit(overwrite: false)
			   }
			}
			Button("Replace All", role: .destructive) {
			   Task {
				  await self.bigPlanViewModel.syncWithHealthKit(overwrite: true)
			   }
			}
			Button("Cancel", role: .cancel) { }
		 } message: {
			Text("Do you want to overwrite all fields with Apple Health data, or only fill empty fields?")
		 }
	  }
	  .preferredColorScheme(.dark)
	  .task {
		 await withTaskGroup(of: Void.self) { group in
			group.addTask {
			   await bigPlanViewModel.fetchAndAppendWeather()
			}
			group.addTask {
			   await bigPlanViewModel.requestHealthKitAuthorization()
			   await bigPlanViewModel.fetchTodaySteps()
			}
			await group.waitForAll()
			isLoading = false
		 }
	  }
   }
}

// MARK: - View Extensions
extension View {
   func placeholder<Content: View>(
	  when shouldShow: Bool,
	  alignment: Alignment = .leading,
	  @ViewBuilder placeholder: () -> Content
   ) -> some View {
	  ZStack(alignment: alignment) {
		 placeholder().opacity(shouldShow ? 1 : 0)
		 self
	  }
   }
}

struct DailyFormView_Previews: PreviewProvider {
   static var previews: some View {
	  let container = try! ModelContainer(for: DailyHealthEntry.self)
	  let context = ModelContext(container)
	  return DailyFormView(
		 selectedTab: .constant(0),
		 bigPlanViewModel: BigPlanViewModel(context: context)
	  )
	  .modelContainer(container)
   }
}
