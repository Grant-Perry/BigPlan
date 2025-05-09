//   MealsView.swift
//   BigPlan
//
//   Created by: Gp. on 5/5/25 at 7:39 PM
//     Modified:
//
//  Copyright Delicious Studios, LLC. - Grant Perry

import SwiftUI

struct MealsView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @State private var focusedField: String?

   var body: some View {
	  VStack(alignment: .leading, spacing: 18) {
		 Text("MEALS")
			.font(.system(size: 20, weight: .semibold))
			.foregroundColor(.white.opacity(0.9))
			.textCase(.uppercase)

		 VStack(spacing: 18) {
			// First Meal Time
			HStack {
			   Text("First Meal")
				  .foregroundColor(focusedField == "firstMeal" ? .gpGreen : .gray.opacity(0.8))
				  .font(.system(size: 19))
			   Spacer()
			   DatePicker("", selection: Binding(
				  get: { bigPlanViewModel.firstMealTime ?? Date() },
				  set: {
					 bigPlanViewModel.firstMealTime = $0
					 focusedField = "firstMeal"
				  }
			   ), displayedComponents: .hourAndMinute)
			   .labelsHidden()
			   .scaleEffect(1.1)
			   .colorMultiply(focusedField == "firstMeal" ? .gpGreen : .white)
			}
			.contentShape(Rectangle())
			.formFieldStyle(icon: "sunrise.fill", hasFocus: focusedField == "firstMeal")
			.onTapGesture {
			   focusedField = "firstMeal"
			}

			// Last Meal Time
			HStack {
			   Text("Last Meal")
				  .foregroundColor(focusedField == "lastMeal" ? .gpGreen : .gray.opacity(0.8))
				  .font(.system(size: 19))
			   Spacer()
			   DatePicker("", selection: Binding(
				  get: { bigPlanViewModel.lastMealTime ?? Date() },
				  set: {
					 bigPlanViewModel.lastMealTime = $0
					 focusedField = "lastMeal"
				  }
			   ), displayedComponents: .hourAndMinute)
			   .labelsHidden()
			   .scaleEffect(1.1)
			   .colorMultiply(focusedField == "lastMeal" ? .gpGreen : .white)
			}
			.contentShape(Rectangle())
			.formFieldStyle(icon: "sunset.fill", hasFocus: focusedField == "lastMeal")
			.onTapGesture {
			   focusedField = "lastMeal"
			}
		 }
	  }
	  .formSectionStyle()
	  .contentShape(Rectangle())
	  .onTapGesture {
		 // Clear focus when tapping outside
		 focusedField = nil
	  }
	  .animation(.none, value: focusedField) // Remove animation for instant focus
   }
}
