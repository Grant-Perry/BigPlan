import SwiftUI
import SwiftData
import OSLog
import HealthKit

private let logger = Logger(subsystem: "BigPlan", category: "SaveDebug")

//// 1. Date Display Component
//struct DateDisplayView: View {
//   let date: Date
//   @Binding var selectedDate: Date
//
//   private func formattedDate(_ date: Date) -> (month: String, day: String, year: String) {
//	  let monthFormatter = DateFormatter()
//	  monthFormatter.dateFormat = "MMM"
//	  let month = monthFormatter.string(from: date).uppercased()
//
//	  let dayFormatter = DateFormatter()
//	  dayFormatter.dateFormat = "dd"
//	  let day = dayFormatter.string(from: date)
//
//	  let yearFormatter = DateFormatter()
//	  yearFormatter.dateFormat = "yyyy"
//	  let year = yearFormatter.string(from: date)
//
//	  return (month, day, year)
//   }
//
//   var body: some View {
//	  let dateComponents = formattedDate(date)
//	  VStack(alignment: .trailing, spacing: 0) {
//		 Text(dateComponents.month)
//			.font(.system(size: 42, weight: .heavy))
//			.foregroundColor(.gpGreen)
//			.kerning(-2)
//
//		 Text(dateComponents.day)
//			.font(.system(size: 38, weight: .bold))
//			.foregroundColor(.gpPink)
//			.kerning(-1)
//			.offset(y: -5)
//
//		 Text(dateComponents.year)
//			.font(.system(size: 16, weight: .bold))
//			.foregroundColor(.white)
//			.offset(y: -5)
//	  }
//	  .padding(.vertical, 8)
//	  .padding(.horizontal, 12)
//	  .background(
//		 RoundedRectangle(cornerRadius: 18)
//			.fill(.white.opacity(0.4))
//	  )
//	  .overlay {
//		 DatePicker(
//			"Entry Date",
//			selection: $selectedDate,
//			displayedComponents: .date
//		 )
//		 .labelsHidden()
//		 .opacity(0)
//	  }
//   }
//}

// 2. Loading View Component
struct LoadingView: View {
   var body: some View {
	  VStack(spacing: 16) {
		 ProgressView()
			.scaleEffect(1.5)
		 Text("Loading...")
			.font(.system(size: 23))
			.foregroundColor(.gray)
	  }
	  .frame(maxWidth: .infinity, maxHeight: .infinity)
	  .background(Color.black.opacity(0.3))
   }
}

//// 3. Form Content Component
//struct FormContentView: View {
//   @ObservedObject var bigPlanViewModel: BigPlanViewModel
//   @Binding var selectedTab: Int
//
//   var body: some View {
//	  VStack(spacing: 24) {
//		 ReadingsView(bigPlanViewModel: bigPlanViewModel)
//		 SleepStressView(bigPlanViewModel: bigPlanViewModel)
//		 ActivityView(bigPlanViewModel: bigPlanViewModel)
//		 MealsView(bigPlanViewModel: bigPlanViewModel)
//		 NotesView(bigPlanViewModel: bigPlanViewModel)
//		 ActionButtonsView(
//			bigPlanViewModel: bigPlanViewModel,
//			selectedTab: $selectedTab
//		 )
//	  }
//	  .padding(.horizontal)
//   }
//}

struct DailyFormView: View {
   @Binding var selectedTab: Int
   @Environment(\.modelContext) private var modelContext
   @StateObject var bigPlanViewModel: BigPlanViewModel
   @Environment(\.dismiss) private var dismiss
   @State private var showingDismissAlert = false
   @State private var isLoading = true

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
			   ScrollView {
				  VStack(alignment: .leading, spacing: 20) {
					 // Header
					 HStack(alignment: .top) {
						Text(bigPlanViewModel.isEditing ? "Edit Entry" : "New Entry")
						   .font(.system(size: 28, weight: .semibold))
						Spacer()
						DateDisplayView(date: bigPlanViewModel.date, selectedDate: $bigPlanViewModel.date)
					 }
					 .padding(.horizontal)

					 // Form Content
					 FormContentView(bigPlanViewModel: bigPlanViewModel, selectedTab: $selectedTab)
						.padding(.horizontal)
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
			   Button("Done") {
				  bigPlanViewModel.saveEntry()
				  completeAction()
			   }
			   .font(.system(size: 23))
			   .disabled(bigPlanViewModel.isInitializing || bigPlanViewModel.isSaving)
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
