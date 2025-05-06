//   ReadingsView.swift
//   BigPlan
//
//   Created by: Gp. on 5/5/25 at 7:42 PM
//     Modified:
//
//  Copyright Delicious Studios, LLC. - Grant Perry
//

import SwiftUI

struct ReadingsView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @State private var systolic: String = ""
   @State private var diastolic: String = ""
   @FocusState private var focusedField: BloodPressureField?

   private enum BloodPressureField {
	  case systolic, diastolic
   }

   var body: some View {
	  VStack(alignment: .leading, spacing: 20) {
		 Text("READINGS")
			.font(.subheadline)
			.foregroundColor(.gray)

		 VStack(spacing: 16) {
			HStack {
			   Text("Glucose (mg/dL)")
			   Spacer()
			   TextField("", value: $bigPlanViewModel.glucose, format: .number.rounded())
				  .keyboardType(.decimalPad)
				  .multilineTextAlignment(.trailing)
			}
			Divider()

			HStack {
			   Text("Ketones (mmol/L)")
			   Spacer()
			   TextField("", value: $bigPlanViewModel.ketones, format: .number.rounded())
				  .keyboardType(.decimalPad)
				  .multilineTextAlignment(.trailing)
			}
			Divider()

			HStack {
			   Text("Blood Pressure")
			   Spacer()
			   TextField("", text: $systolic)
				  .placeholder(when: systolic.isEmpty) {
					 Text("120").foregroundColor(.gray.opacity(0.5))
				  }
				  .keyboardType(.numberPad)
				  .multilineTextAlignment(.trailing)
				  .frame(width: 50)
				  .focused($focusedField, equals: .systolic)
				  .onChange(of: systolic) { _, newValue in
					 if newValue.count >= 3 {
						systolic = String(newValue.prefix(3))
						focusedField = .diastolic
					 }
					 updateBloodPressure()
				  }
			   Text("/")
			   TextField("", text: $diastolic)
				  .placeholder(when: diastolic.isEmpty) {
					 Text("80").foregroundColor(.gray.opacity(0.5))
				  }
				  .keyboardType(.numberPad)
				  .multilineTextAlignment(.trailing)
				  .frame(width: 50)
				  .focused($focusedField, equals: .diastolic)
				  .onChange(of: diastolic) { _, newValue in
					 if newValue.count >= 3 {
						diastolic = String(newValue.prefix(3))
					 }
					 updateBloodPressure()
				  }
			}
			Divider()

			HStack {
			   Text("Weight (lbs)")
			   Spacer()
			   TextField("", value: $bigPlanViewModel.weight, format: .number.rounded())
				  .keyboardType(.decimalPad)
				  .multilineTextAlignment(.trailing)
			}
		 }
		 .padding()
		 .background(Color(.secondarySystemBackground))
		 .cornerRadius(10)
	  }
	  .onAppear { loadBloodPressure() }
   }

   private func loadBloodPressure() {
	  if let bp = bigPlanViewModel.bloodPressure?.split(separator: "/") {
		 systolic = String(bp[0])
		 if bp.count > 1 {
			diastolic = String(bp[1])
		 }
	  }
   }

   private func updateBloodPressure() {
	  if !systolic.isEmpty && !diastolic.isEmpty {
		 bigPlanViewModel.bloodPressure = "\(systolic)/\(diastolic)"
	  } else {
		 bigPlanViewModel.bloodPressure = nil
	  }
   }
}
