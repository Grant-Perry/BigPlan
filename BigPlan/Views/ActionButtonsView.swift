//   ActionButtonsView.swift
//   BigPlan
//
//   Created by: Gp. on 5/5/25 at 7:41 PM
//     Modified:
//
//  Copyright Delicious Studios, LLC. - Grant Perry
//

import SwiftUI

struct ActionButtonsView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @Binding var selectedTab: Int
   @Environment(\.dismiss) private var dismiss
   @State private var showDeleteConfirmation = false

   private func completeAction() {
	  dismiss()
	  selectedTab = 0
   }

   var body: some View {
	  VStack(alignment: .leading, spacing: 12) {
		 Text("Actions")
			.font(.headline)
			.padding(.top)

		 VStack(spacing: 12) {
			Button("Save Entry") {
			   bigPlanViewModel.saveEntry()
			   completeAction()
			}
			.frame(maxWidth: .infinity)
			.buttonStyle(.borderedProminent)

			if bigPlanViewModel.isEditing {
			   Button(role: .destructive) {
				  showDeleteConfirmation = true
			   } label: {
				  Text("Delete Entry")
			   }
			   .alert("Are you sure?", isPresented: $showDeleteConfirmation) {
				  Button("Delete", role: .destructive) {
					 bigPlanViewModel.deleteThisEntry()
					 completeAction()
				  }
				  Button("Cancel", role: .cancel) { }
			   }
			   .frame(maxWidth: .infinity)
			}
		 }
	  }
   }
}
