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
   @State private var focusedButton: String?

   private func completeAction() {
	  dismiss()
	  selectedTab = 0
   }

   var body: some View {
	  VStack(alignment: .leading, spacing: 18) {
		 Text("ACTIONS")
			.font(.system(size: 20, weight: .semibold))
			.foregroundColor(.white.opacity(0.9))
			.textCase(.uppercase)

		 VStack(spacing: 18) {
			// Save Button
			Button {
			   bigPlanViewModel.saveEntry()
			   completeAction()
			} label: {
			   Text("Save Entry")
				  .font(.system(size: 19, weight: .medium))
				  .foregroundColor(.white)
				  .frame(maxWidth: .infinity)
				  .padding(.vertical, 16)
				  .background {
					 RoundedRectangle(cornerRadius: 10)
						.fill(Color.accentColor)
				  }
			}
			.buttonStyle(.plain)
			.overlay(
			   RoundedRectangle(cornerRadius: 10)
				  .stroke(focusedButton == "save" ? Color.blue.opacity(0.5) : Color.white.opacity(0.05),
						  lineWidth: focusedButton == "save" ? 2 : 0.5)
			)
			.shadow(color: focusedButton == "save" ? Color.blue.opacity(0.3) : .clear, radius: 8)
			.contentShape(Rectangle())
			.onTapGesture {
			   focusedButton = "save"
			}

			// Delete Button (if editing)
			if bigPlanViewModel.isEditing {
			   Button {
				  showDeleteConfirmation = true
			   } label: {
				  Text("Delete Entry")
					 .font(.system(size: 19, weight: .medium))
					 .foregroundColor(.white)
					 .frame(maxWidth: .infinity)
					 .padding(.vertical, 16)
					 .background {
						RoundedRectangle(cornerRadius: 10)
						   .fill(Color.red.opacity(0.8))
					 }
			   }
			   .buttonStyle(.plain)
			   .overlay(
				  RoundedRectangle(cornerRadius: 10)
					 .stroke(focusedButton == "delete" ? Color.blue.opacity(0.5) : Color.white.opacity(0.05),
							 lineWidth: focusedButton == "delete" ? 2 : 0.5)
			   )
			   .shadow(color: focusedButton == "delete" ? Color.blue.opacity(0.3) : .clear, radius: 8)
			   .contentShape(Rectangle())
			   .onTapGesture {
				  focusedButton = "delete"
			   }
			}
		 }
	  }
	  .formSectionStyle()
	  .alert("Are you sure?", isPresented: $showDeleteConfirmation) {
		 Button("Delete", role: .destructive) {
			bigPlanViewModel.deleteThisEntry()
			completeAction()
		 }
		 .font(.system(size: 19))

		 Button("Cancel", role: .cancel) { }
			.font(.system(size: 19))
	  } message: {
		 Text("This action cannot be undone.")
			.font(.system(size: 19))
	  }
	  .contentShape(Rectangle())
	  .onTapGesture {
		 // Clear focus when tapping outside
		 focusedButton = nil
	  }
	  .animation(.none, value: focusedButton)
   }
}
