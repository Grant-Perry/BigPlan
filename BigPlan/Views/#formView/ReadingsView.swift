import SwiftUI

// MARK: - Form Fields
enum ReadingsField {
   case glucose, ketones, systolic, diastolic, weight, heartMin, heartMax, steps
}

struct ReadingsView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @State private var systolic: String = ""
   @State private var diastolic: String = ""
   @FocusState private var focusedField: ReadingsField?
   @State private var hkUpdatedGlucose = false
   @State private var hkUpdatedKetones = false
   @State private var hkUpdatedBP = false
   @State private var hkUpdatedWeight = false
   @State private var hkUpdatedHeartRate = false

   private let hintSize: CGFloat = AppConstants.hintSize

   var body: some View {
	  VStack(alignment: .leading, spacing: 18) {
		 //		 DateHeader(bigPlanViewModel: bigPlanViewModel)
		 Text("READINGS")
			.font(.system(size: 20, weight: .semibold))
			.foregroundColor(.white.opacity(0.9))
			.textCase(.uppercase)
		 VStack(spacing: 18) {

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
			   HKBadgeView(show: bigPlanViewModel.hkUpdatedGlucose, hasValue: bigPlanViewModel.glucose != nil)
			}
			.formFieldStyle(icon: "drop.fill", hasFocus: focusedField == .glucose)
			.contentShape(Rectangle())
			.onTapGesture {
			   focusedField = .glucose
			}
			.onChange(of: bigPlanViewModel.glucose) { oldValue, newValue in
			   if !bigPlanViewModel.isSyncingFromHK {
				  bigPlanViewModel.hkUpdatedGlucose = false
			   }
			}

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
			   HKBadgeView(show: bigPlanViewModel.hkUpdatedKetones, hasValue: bigPlanViewModel.ketones != nil)
			}
			.formFieldStyle(icon: "flame.fill", hasFocus: focusedField == .ketones)
			.contentShape(Rectangle())
			.onTapGesture {
			   focusedField = .ketones
			}
			.onChange(of: bigPlanViewModel.ketones) { oldValue, newValue in
			   if !bigPlanViewModel.isSyncingFromHK {
				  bigPlanViewModel.hkUpdatedKetones = false
			   }
			}

			HStack {
			   Text("Blood Pressure")
				  .lineLimit(1)
				  .fixedSize()
				  .foregroundColor((focusedField == .systolic || focusedField == .diastolic) ? .gpGreen : .gray.opacity(0.8))
				  .font(.system(size: 19))
			   Spacer()

			   HStack(spacing: 12) {
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

			   HKBadgeView(show: bigPlanViewModel.hkUpdatedBloodPressure, hasValue: !(systolic.isEmpty || diastolic.isEmpty))
			}
			.formFieldStyle(icon: "heart.fill", hasFocus: focusedField == .systolic || focusedField == .diastolic)
			.contentShape(Rectangle())
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
			.onChange(of: bigPlanViewModel.bloodPressure) { oldValue, newValue in
			   if !bigPlanViewModel.isSyncingFromHK {
				  bigPlanViewModel.hkUpdatedBloodPressure = false
			   }
			}

			HStack(alignment: .top) {
			   VStack(alignment: .leading, spacing: 8) {
				  Text("Heart")
					 .foregroundColor((focusedField == .heartMin || focusedField == .heartMax) ? .gpGreen : .gray.opacity(0.8))
					 .font(.system(size: 19))
					 .lineLimit(1)

				  Grid(horizontalSpacing: 16, verticalSpacing: 4) {
					 GridRow {
						Text("max")
						   .font(.system(size: 13))
						   .foregroundColor(.gray)
						Text("min")
						   .font(.system(size: 13))
						   .foregroundColor(.gray)
						Text("avg")
						   .font(.system(size: 13))
						   .foregroundColor(.gray)
					 }

					 GridRow {
						TextField("", value: $bigPlanViewModel.maxHeartRate, format: .number.rounded())
						   .keyboardType(.decimalPad)
						   .frame(width: 50)
						   .focused($focusedField, equals: .heartMax)
						   .font(.system(size: 19))
						   .foregroundColor(.red)
						   .multilineTextAlignment(.center)
						   .placeholder(when: bigPlanViewModel.maxHeartRate == nil) {
							  Text("--")
								 .foregroundColor(focusedField == .heartMax ? .gpGreen : .gray.opacity(0.3))
						   }

						TextField("", value: $bigPlanViewModel.minHeartRate, format: .number.rounded())
						   .keyboardType(.decimalPad)
						   .frame(width: 50)
						   .focused($focusedField, equals: .heartMin)
						   .font(.system(size: 19))
						   .foregroundColor(.blue)
						   .multilineTextAlignment(.center)
						   .placeholder(when: bigPlanViewModel.minHeartRate == nil) {
							  Text("--")
								 .foregroundColor(focusedField == .heartMin ? .gpGreen : .gray.opacity(0.3))
						   }

						Text(bigPlanViewModel.avgHeartRate.map { "\(Int($0))" } ?? "--")
						   .font(.system(size: 19))
						   .foregroundColor(bigPlanViewModel.avgHeartRate != nil ? .purple : .gray.opacity(0.3))
					 }
				  }
			   }

			   Spacer()

			   HKBadgeView(show: bigPlanViewModel.hkUpdatedHeartRate, hasValue: bigPlanViewModel.minHeartRate != nil || bigPlanViewModel.maxHeartRate != nil)
			}
			.formFieldStyle(icon: "heart.fill", hasFocus: focusedField == .heartMin || focusedField == .heartMax)
			.contentShape(Rectangle())
			.onTapGesture {
			   focusedField = .heartMin
			}
			.onChange(of: bigPlanViewModel.minHeartRate) { oldValue, newValue in
			   if !bigPlanViewModel.isSyncingFromHK {
				  bigPlanViewModel.hkUpdatedHeartRate = false
			   }
			}
			.onChange(of: bigPlanViewModel.maxHeartRate) { oldValue, newValue in
			   if !bigPlanViewModel.isSyncingFromHK {
				  bigPlanViewModel.hkUpdatedHeartRate = false
			   }
			}

			WeightSection(
			   bigPlanViewModel: bigPlanViewModel,
			   isFocused: focusedField == .weight,
			   onTapField: { focusedField = .weight },
			   hintSize: hintSize
			)
			.overlay(
			   HKBadgeView(show: bigPlanViewModel.hkUpdatedWeight, hasValue: bigPlanViewModel.weight != nil)
				  .padding(.trailing, 6),
			   alignment: .trailing
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
		 if !bigPlanViewModel.isSyncingFromHK {
			bigPlanViewModel.hkUpdatedBloodPressure = false
		 }
	  } else if !systolic.isEmpty && diastolic.isEmpty {
		 bigPlanViewModel.bloodPressure = nil
		 if !bigPlanViewModel.isSyncingFromHK {
			bigPlanViewModel.hkUpdatedBloodPressure = false
		 }
	  }
	  else {
		 bigPlanViewModel.bloodPressure = nil
		 if !bigPlanViewModel.isSyncingFromHK {
			bigPlanViewModel.hkUpdatedBloodPressure = false
		 }
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
		 .onChange(of: bigPlanViewModel.weight) { oldValue, newValue in
			if !bigPlanViewModel.isSyncingFromHK {
			   bigPlanViewModel.hkUpdatedWeight = false
			}
		 }

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

// MARK: - Date Header
//struct DateHeader: View {
//   @ObservedObject var bigPlanViewModel: BigPlanViewModel
//
//   var body: some View {
//	  VStack(alignment: .trailing, spacing: 0) {
//		 Text(bigPlanViewModel.date.formatted(.dateTime.month(.wide)).uppercased())
//			.font(.system(size: 35, weight: .bold))
//			.foregroundColor(.white)
//			.lineLimit(1)
//		 Text(bigPlanViewModel.date.formatted(.dateTime.day()))
//			.font(.system(size: 55, weight: .bold, design: .rounded))
//			.foregroundColor(.gpRed)
//			.minimumScaleFactor(0.7)
//		 Text(bigPlanViewModel.date.formatted(.dateTime.year()))
//			.font(.system(size: 19, weight: .medium))
//			.foregroundColor(.gray)
//	  }
//   }
//}
