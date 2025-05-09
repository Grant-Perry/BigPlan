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
   @FocusState private var focusedField: Field?

   private enum Field {
	  case glucose, ketones, systolic, diastolic, weight
   }

   var body: some View {
	  VStack(alignment: .leading, spacing: 18) {
		 Text("READINGS")
			.font(.system(size: 24, weight: .semibold))
			.foregroundColor(.white.opacity(0.9))
			.textCase(.uppercase)

		 VStack(spacing: 18) {
			// Glucose Field
			HStack {
			   Text("Glucose")
				  .foregroundColor(focusedField == .glucose ? .gpGreen : .gray.opacity(0.8))
				  .font(.system(size: 23))
			   Spacer()
			   TextField("", value: $bigPlanViewModel.glucose, format: .number.rounded())
				  .keyboardType(.decimalPad)
				  .multilineTextAlignment(.trailing)
				  .focused($focusedField, equals: .glucose)
				  .font(.system(size: 23))
				  .placeholder(when: bigPlanViewModel.glucose == nil) {
					 Text("mg/dL")
						.foregroundColor(focusedField == .glucose ? .gpGreen : .gray.opacity(0.3))
						.font(.system(size: 23))
				  }
			}
			.formFieldStyle(icon: "drop.fill", hasFocus: focusedField == .glucose)
			.contentShape(Rectangle()) // Makes entire area tappable
			.onTapGesture {
			   focusedField = .glucose
			}

			// Ketones Field
			HStack {
			   Text("Ketones")
				  .foregroundColor(focusedField == .ketones ? .gpGreen : .gray.opacity(0.8))
				  .font(.system(size: 23))
			   Spacer()
			   TextField("", value: $bigPlanViewModel.ketones, format: .number.rounded())
				  .keyboardType(.decimalPad)
				  .multilineTextAlignment(.trailing)
				  .focused($focusedField, equals: .ketones)
				  .font(.system(size: 23))
				  .placeholder(when: bigPlanViewModel.ketones == nil) {
					 Text("mmol/L")
						.foregroundColor(focusedField == .ketones ? .gpGreen : .gray.opacity(0.3))
						.font(.system(size: 23))
				  }
			}
			.formFieldStyle(icon: "flame.fill", hasFocus: focusedField == .ketones)
			.contentShape(Rectangle()) // Makes entire area tappable
			.onTapGesture {
			   focusedField = .ketones
			}

			// Blood Pressure Field
			HStack {
			   Text("Blood Pressure")
				  .foregroundColor((focusedField == .systolic || focusedField == .diastolic) ? .gpGreen : .gray.opacity(0.8))
				  .font(.system(size: 23))
			   Spacer()
			   HStack(spacing: 10) {
				  TextField("", text: $systolic)
					 .placeholder(when: systolic.isEmpty) {
						Text("sys")
						   .foregroundColor((focusedField == .systolic || focusedField == .diastolic) ? .gpGreen : .gray.opacity(0.3))
					 }
					 .keyboardType(.numberPad)
					 .multilineTextAlignment(.trailing)
					 .frame(width: 70)
					 .focused($focusedField, equals: .systolic)
					 .font(.system(size: 23))

				  Text("/")
					 .foregroundColor(.gray.opacity(0.5))
					 .font(.system(size: 23))

				  TextField("", text: $diastolic)
					 .placeholder(when: diastolic.isEmpty) {
						Text("dia")
						   .foregroundColor((focusedField == .systolic || focusedField == .diastolic) ? .gpGreen : .gray.opacity(0.3))
					 }
					 .keyboardType(.numberPad)
					 .multilineTextAlignment(.trailing)
					 .frame(width: 70)
					 .focused($focusedField, equals: .diastolic)
					 .font(.system(size: 23))
			   }
			}
			.formFieldStyle(icon: "heart.fill", hasFocus: focusedField == .systolic || focusedField == .diastolic)
			.contentShape(Rectangle()) // Makes entire area tappable
			.onTapGesture {
			   if focusedField == .systolic {
				  focusedField = .diastolic
			   } else {
				  focusedField = .systolic
			   }
			}
			.onChange(of: systolic) { _, newValue in
			   if newValue.count >= 3 {
				  systolic = String(newValue.prefix(3))
				  focusedField = .diastolic
			   }
			   updateBloodPressure()
			}
			.onChange(of: diastolic) { _, newValue in
			   if newValue.count >= 3 {
				  diastolic = String(newValue.prefix(3))
			   }
			   updateBloodPressure()
			}

			// Weight Field
			HStack {
			   Text("Weight")
				  .foregroundColor(focusedField == .weight ? .gpGreen : .gray.opacity(0.8))
				  .font(.system(size: 23))
			   Spacer()
			   TextField("", value: $bigPlanViewModel.weight, format: .number.rounded())
				  .keyboardType(.decimalPad)
				  .multilineTextAlignment(.trailing)
				  .focused($focusedField, equals: .weight)
				  .font(.system(size: 23))
				  .placeholder(when: bigPlanViewModel.weight == nil) {
					 Text("lbs")
						.foregroundColor(focusedField == .weight ? .gpGreen : .gray.opacity(0.3))
						.font(.system(size: 23))
				  }
			}
			.formFieldStyle(icon: "scalemass.fill", hasFocus: focusedField == .weight)
			.contentShape(Rectangle()) // Makes entire area tappable
			.onTapGesture {
			   focusedField = .weight
			}
		 }
	  }
	  .formSectionStyle()
	  .animation(.none, value: focusedField) // Remove animation for focus changes
	  .onAppear { loadBloodPressure() }
	  .onChange(of: bigPlanViewModel.bloodPressure) { _, _ in
		 loadBloodPressure()
	  }
   }

   private let sectionBackground = Color(UIColor.systemGray5).opacity(0.7)
   private let fieldBackground = Color.black.opacity(0.3)

   private func loadBloodPressure() {
	  if let bpString = bigPlanViewModel.bloodPressure, bpString != "\(systolic)/\(diastolic)" {
		 let bpComponents = bpString.split(separator: "/")
		 if !bpComponents.isEmpty {
			systolic = String(bpComponents[0])
			if bpComponents.count > 1 {
			   diastolic = String(bpComponents[1])
			} else {
			   diastolic = ""
			}
		 } else {
			systolic = ""
			diastolic = ""
		 }
	  } else if bigPlanViewModel.bloodPressure == nil && (!systolic.isEmpty || !diastolic.isEmpty) {
		 systolic = ""
		 diastolic = ""
	  }
   }

   private func updateBloodPressure() {
	  if !systolic.isEmpty && !diastolic.isEmpty {
		 bigPlanViewModel.bloodPressure = "\(systolic)/\(diastolic)"
	  } else if !systolic.isEmpty && diastolic.isEmpty {
		 bigPlanViewModel.bloodPressure = nil
	  }
	  else {
		 bigPlanViewModel.bloodPressure = nil
	  }
   }
}
