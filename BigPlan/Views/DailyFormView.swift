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

   private func handleDismiss() {
	  if bigPlanViewModel.hasUnsavedChanges {
		 showingDismissAlert = true
	  } else {
		 if bigPlanViewModel.isEditing {
			dismiss()
		 } else {
			selectedTab = 0
		 }
	  }
   }

   var body: some View {
	  NavigationStack {
		 ScrollView {
			VStack(alignment: .leading, spacing: 20) {
			   VStack(alignment: .leading, spacing: 4) {
				  Text(bigPlanViewModel.isEditing ? "Edit Entry" : "New Entry")
					 .font(.title)
					 .fontWeight(.semibold)
				  Text(bigPlanViewModel.date.formatted(date: .abbreviated, time: .omitted))
					 .font(.subheadline)
					 .foregroundColor(.gray)
			   }
			   .padding(.horizontal)

			   VStack(spacing: 24) {
				  DateTimeView(bigPlanViewModel: bigPlanViewModel)
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
			}
			ToolbarItem(placement: .navigationBarTrailing) {
			   Button("Done") {
				  bigPlanViewModel.saveEntry()
				  if bigPlanViewModel.isEditing {
					 dismiss()
				  } else {
					 selectedTab = 0
				  }
			   }
			}
		 }
		 .alert("Save Changes?", isPresented: $showingDismissAlert) {
			Button("Don't Save", role: .destructive) {
			   if bigPlanViewModel.isEditing {
				  dismiss()
			   } else {
				  selectedTab = 0
			   }
			}
			Button("Save") {
			   bigPlanViewModel.saveEntry()
			   if bigPlanViewModel.isEditing {
				  dismiss()
			   } else {
				  selectedTab = 0
			   }
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
