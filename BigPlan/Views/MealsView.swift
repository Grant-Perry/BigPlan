//   MealsView.swift
//   BigPlan
//
//   Created by: Gp. on 5/5/25 at 7:39 PM
//     Modified: 
//
//  Copyright © 2025 Delicious Studios, LLC. - Grant Perry
//

import SwiftUI

struct MealsView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel

   var body: some View {
	  VStack(alignment: .leading, spacing: 20) {
		 Text("MEALS")
			.font(.subheadline)
			.foregroundColor(.gray)

		 VStack(spacing: 16) {
			HStack {
			   Text("First Meal")
			   Spacer()
			   DatePicker("", selection: Binding(
				  get: { bigPlanViewModel.firstMealTime ?? Date() },
				  set: { bigPlanViewModel.firstMealTime = $0 }
			   ), displayedComponents: .hourAndMinute)
			   .labelsHidden()
			}
			Divider()

			HStack {
			   Text("Last Meal")
			   Spacer()
			   DatePicker("", selection: Binding(
				  get: { bigPlanViewModel.lastMealTime ?? Date() },
				  set: { bigPlanViewModel.lastMealTime = $0 }
			   ), displayedComponents: .hourAndMinute)
			   .labelsHidden()
			}
		 }
		 .padding()
		 .background(Color(.secondarySystemBackground))
		 .cornerRadius(10)
	  }
   }
}
