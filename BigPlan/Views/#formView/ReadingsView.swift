
import SwiftUI

// MARK: - Form Fields
enum ReadingsField {
   case glucose, ketones, systolic, diastolic, weight
}

struct ReadingsView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @State private var systolic: String = ""
   @State private var diastolic: String = ""
   @FocusState private var focusedField: ReadingsField?

   private let hintSize: CGFloat = AppConstants.hintSize

   var body: some View {
	  VStack(alignment: .leading, spacing: 18) {
		 Text("READINGS")
			.font(.system(size: 20, weight: .semibold))
			.foregroundColor(.white.opacity(0.9))
			.textCase(.uppercase)

		 VStack(spacing: 18) {
			// Glucose Field
			HStack {
			   Text("Glucose")
				  .foregroundColor(focusedField == .glucose ? .gpGreen : .gray.opacity(0.8))
				  .font(.system(size: 19))
			   Spacer()
			   TextField("", value: $bigPlanViewModel.glucose, format: .number.rounded())
				  .keyboardType(.decimalPad)
				  .multilineTextAlignment(.trailing)
				  .focused($focusedField, equals: .glucose)
				  .font(.system(size: 19))
				  .placeholder(when: bigPlanViewModel.glucose == nil) {
					 Text("mg/dL")
						.foregroundColor(focusedField == .glucose ? .gpGreen : .gray.opacity(0.3))
						.font(.system(size: hintSize))
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
				  .font(.system(size: 19))
			   Spacer()
			   TextField("", value: $bigPlanViewModel.ketones, format: .number.rounded())
				  .keyboardType(.decimalPad)
				  .multilineTextAlignment(.trailing)
				  .focused($focusedField, equals: .ketones)
				  .font(.system(size: 19))
				  .placeholder(when: bigPlanViewModel.ketones == nil) {
					 Text("mmol/L")
						.foregroundColor(focusedField == .ketones ? .gpGreen : .gray.opacity(0.3))
						.font(.system(size: hintSize))
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
				  .font(.system(size: 19))
				  .lineLimit(2)
				  .fixedSize(horizontal: false, vertical: true)
				  .frame(maxWidth: .infinity, alignment: .leading)
				  .minimumScaleFactor(0.45)
			   Spacer()
			   HStack(spacing: 10) {
				  TextField("", text: $systolic)
					 .placeholder(when: systolic.isEmpty) {
						Text("sys")
						   .foregroundColor((focusedField == .systolic || focusedField == .diastolic) ? .gpGreen : .gray.opacity(0.3))
						   .font(.system(size: hintSize))
					 }
					 .keyboardType(.numberPad)
					 .multilineTextAlignment(.trailing)
					 .frame(width: 70)
					 .focused($focusedField, equals: .systolic)
					 .font(.system(size: 19))

				  Text("/")
					 .foregroundColor(.gray.opacity(0.5))
					 .font(.system(size: 19))

				  TextField("", text: $diastolic)
					 .placeholder(when: diastolic.isEmpty) {
						Text("dia")
						   .foregroundColor((focusedField == .systolic || focusedField == .diastolic) ? .gpGreen : .gray.opacity(0.3))
						   .font(.system(size: hintSize))
					 }
					 .keyboardType(.numberPad)
					 .multilineTextAlignment(.trailing)
					 .frame(width: 70)
					 .focused($focusedField, equals: .diastolic)
					 .font(.system(size: 19))
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
			WeightSection(
			   bigPlanViewModel: bigPlanViewModel,
			   isFocused: focusedField == .weight,
			   onTapField: { focusedField = .weight },
			   hintSize: hintSize
			)
		 }
	  }
	  .formSectionStyle()
	  .animation(.none, value: focusedField)
	  .onAppear {
		 DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			focusedField = .glucose  // Set initial focus with slight delay for better UX
		 }
		 loadBloodPressure()
	  }
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

// MARK: - Weight Section
private struct WeightSection: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   let isFocused: Bool
   let onTapField: () -> Void
   let hintSize: CGFloat

   var body: some View {
	  VStack(alignment: .leading, spacing: 8) {
		 // Main Weight Input
		 HStack {
			Text("Weight")
			   .foregroundColor(isFocused ? .gpGreen : .gray.opacity(0.8))
			   .font(.system(size: 19))
			Spacer()
			TextField("", value: $bigPlanViewModel.weight, format: .number.rounded())
			   .keyboardType(.decimalPad)
			   .multilineTextAlignment(.trailing)
			   .font(.system(size: 19))
			   .placeholder(when: bigPlanViewModel.weight == nil) {
				  Text("lbs")
					 .foregroundColor(isFocused ? .gpGreen : .gray.opacity(0.3))
					 .font(.system(size: hintSize))
			   }
		 }
		 .formFieldStyle(icon: "scalemass.fill", hasFocus: isFocused)
		 .contentShape(Rectangle())
		 .onTapGesture(perform: onTapField)

		 // Weight Comparisons
		 if bigPlanViewModel.weight != nil {
			WeightComparisons(viewModel: bigPlanViewModel)
		 }
	  }
   }
}

// MARK: - Weight Comparisons
private struct WeightComparisons: View {
   let viewModel: BigPlanViewModel

   var body: some View {
	  VStack(alignment: .leading, spacing: 4) {
		 if let (diff, isUp) = viewModel.weightDiffFromLastEntry {
			HStack(spacing: 4) {
			   Text("Last:")
				  .foregroundStyle(.gray)
			   Image(systemName: isUp ? "arrow.up" : "arrow.down")
				  .foregroundStyle(isUp ? .green : .green)
			   Text(String(format: "%.1f", diff))
				  .foregroundStyle(isUp ? .green : .green)
			   Text("lbs")
				  .foregroundStyle(.gray)
			}
			.font(.system(size: 16))
		 }

		 if let (diff, isUp) = viewModel.weightDiffFromGoal {
			HStack(spacing: 4) {
			   Text("Remain:")
				  .foregroundStyle(.gray)
			   Text(String(format: "%.1f", diff))
				  .foregroundStyle(isUp ? .green : .green)
			   Text("lbs")
				  .foregroundStyle(.gray)
			}
			.font(.system(size: 16))
		 }
	  }
	  .padding(.leading, 30)
   }
}
