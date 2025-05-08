//
//  EntryFormView.swift
//  BigPlan
//
//  Created by Gp. on 5/5/25.
//

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

   private func completeAction() {
	  // This function will now handle both scenarios:
	  // 1. If presented modally/navigation, dismiss will work.
	  // 2. If embedded in TabView, selectedTab will change.
	  // One of them will be a no-op depending on context, which is fine.
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
			ScrollView {
			   VStack(alignment: .leading, spacing: 20) {
				  VStack(alignment: .leading, spacing: 4) {
					 Text(bigPlanViewModel.isEditing ? "Edit Entry" : "New Entry")
						.font(.title)
						.fontWeight(.semibold)
					 DatePicker(
						"Entry Date",
						selection: $bigPlanViewModel.date,
						displayedComponents: .date
					 )
					 .labelsHidden()
					 .font(.subheadline)
					 .foregroundColor(.gray)
				  }
				  .padding(.horizontal)

				  VStack(spacing: 24) {

					 // DateTimeView(bigPlanViewModel: bigPlanViewModel)
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

				  Spacer(minLength: 20)
				  AppConstants.VersionFooter()
			   }
			}
			.disabled(bigPlanViewModel.isInitializing || bigPlanViewModel.isSaving)
			.opacity(bigPlanViewModel.isInitializing || bigPlanViewModel.isSaving ? 0.6 : 1.0)

			if bigPlanViewModel.isInitializing {
			   VStack {
				  ProgressView()
					 .controlSize(.large)
				  Text("Loading...")
					 .foregroundColor(.secondary)
					 .padding(.top)
			   }
			}

			if bigPlanViewModel.isSaving {
			   VStack {
				  ProgressView()
					 .controlSize(.large)
				  Text("Saving...")
					 .foregroundColor(.secondary)
					 .padding(.top)
			   }
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
			   }
			   .disabled(bigPlanViewModel.isInitializing || bigPlanViewModel.isSaving)
			}
			ToolbarItem(placement: .navigationBarTrailing) {
			   Button("Done") {
				  bigPlanViewModel.saveEntry()
				  completeAction()
			   }
			   .disabled(bigPlanViewModel.isInitializing || bigPlanViewModel.isSaving)
			}
		 }
		 .alert("Save Changes?", isPresented: $showingDismissAlert) {
			Button("Don't Save", role: .destructive) {
			   completeAction()
			}
			Button("Save") {
			   bigPlanViewModel.saveEntry()
			   completeAction()
			}
			Button("Cancel", role: .cancel) { }
		 } message: {
			Text("Would you like to save your changes before exiting?")
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
