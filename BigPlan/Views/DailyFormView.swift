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
			   // FIX: Use the full type name
			   AppConstants.VersionFooter()
			}
		 }
		 .scrollDismissesKeyboard(.immediately)
		 .navigationBarTitleDisplayMode(.inline)
		 .toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
			   Button("Done") {
				  bigPlanViewModel.saveEntry() // Add this line to save
				  if bigPlanViewModel.isEditing {
					 dismiss()
				  } else {
					 selectedTab = 0
				  }
			   }
			}
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
