//   SleepStressView.swift
//   BigPlan
//
//   Created by: Gp. on 5/5/25 at 7:38 PM
//     Modified:
//
//  Copyright Delicious Studios, LLC. - Grant Perry
//

import SwiftUI

struct SleepStressView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @State private var sleepHoursString: String = ""
   @State private var sleepMinutesString: String = ""
   @FocusState private var focusedField: Field?
   @State private var isStressPickerFocused: Bool = false

   private enum Field {
	  case hours, minutes
   }

   var body: some View {
	  VStack(alignment: .leading, spacing: 18) {
		 Text("SLEEP & STRESS")
			.font(.system(size: 20, weight: .semibold))
			.foregroundColor(.white.opacity(0.9))
			.textCase(.uppercase)

		 VStack(spacing: 18) {
			// Sleep Time Field
			HStack {
			   Text("Sleep Time")
				  .foregroundColor(focusedField != nil ? .gpGreen : .gray.opacity(0.8))
				  .font(.system(size: 19))
			   Spacer()
			   HStack(spacing: 10) {
				  TextField("", text: $sleepHoursString)
					 .placeholder(when: sleepHoursString.isEmpty) {
						Text("H")
						   .foregroundColor(focusedField == .hours ? .gpGreen : .gray.opacity(0.3))
						   .font(.system(size: 19))
					 }
					 .keyboardType(.numberPad)
					 .multilineTextAlignment(.trailing)
					 .frame(width: 70)
					 .focused($focusedField, equals: .hours)
					 .font(.system(size: 19))

				  Text(":")
					 .foregroundColor(.gray.opacity(0.5))
					 .font(.system(size: 19))

				  TextField("", text: $sleepMinutesString)
					 .placeholder(when: sleepMinutesString.isEmpty) {
						Text("M")
						   .foregroundColor(focusedField == .minutes ? .gpGreen : .gray.opacity(0.3))
						   .font(.system(size: 19))
					 }
					 .keyboardType(.numberPad)
					 .multilineTextAlignment(.trailing)
					 .frame(width: 70)
					 .focused($focusedField, equals: .minutes)
					 .font(.system(size: 19))
			   }
			}
			.contentShape(Rectangle())
			.formFieldStyle(icon: "bed.double.fill", hasFocus: focusedField != nil)
			.onTapGesture {
			   if focusedField == nil {
				  focusedField = .hours
			   }
			}
			.onChange(of: sleepHoursString) { _, newValue in
			   if let hours = Int(newValue), hours > 24 {
				  sleepHoursString = "24"
			   }
			   if newValue.count > 2 {
				  sleepHoursString = String(newValue.prefix(2))
			   }
			   updateViewModelSleepTime()
			}
			.onChange(of: sleepMinutesString) { _, newValue in
			   if let minutes = Int(newValue), minutes > 59 {
				  sleepMinutesString = "59"
			   }
			   if newValue.count > 2 {
				  sleepMinutesString = String(newValue.prefix(2))
			   }
			   updateViewModelSleepTime()
			}

			// Stress Level Field
			HStack {
			   Text("Stress Level")
				  .foregroundColor(isStressPickerFocused ? .gpGreen : .gray.opacity(0.8))
				  .font(.system(size: 19))
			   Spacer()
			   Picker("", selection: Binding(
				  get: {
					 switch bigPlanViewModel.stressLevel {
						case 1: return "Low"
						case 2: return "Medium"
						case 3: return "High"
						default: return ""
					 }
				  },
				  set: { newValue in
					 switch newValue {
						case "Low": bigPlanViewModel.stressLevel = 1
						case "Medium": bigPlanViewModel.stressLevel = 2
						case "High": bigPlanViewModel.stressLevel = 3
						default: bigPlanViewModel.stressLevel = nil
					 }
					 isStressPickerFocused = true
				  }
			   )) {
				  Text("").tag("")
				  Text("Low").tag("Low")
					 .font(.system(size: 19))
				  Text("Medium").tag("Medium")
					 .font(.system(size: 19))
				  Text("High").tag("High")
					 .font(.system(size: 19))
			   }
			   .labelsHidden()
			   .scaleEffect(1.1)
			}
			.contentShape(Rectangle())
			.formFieldStyle(icon: "brain.head.profile", hasFocus: isStressPickerFocused)
			.onTapGesture {
			   isStressPickerFocused = true
			   focusedField = nil
			}
		 }
	  }
	  .formSectionStyle()
	  .animation(.none, value: focusedField)
	  .animation(.none, value: isStressPickerFocused)
	  .onChange(of: bigPlanViewModel.sleepTime) { _, _ in
		 updateLocalSleepStrings()
	  }
   }

   private func updateViewModelSleepTime() {
	  if sleepHoursString.isEmpty && sleepMinutesString.isEmpty {
		 bigPlanViewModel.sleepTime = nil
		 return
	  }

	  let hours = Int(sleepHoursString) ?? 0
	  let minutes = Int(sleepMinutesString) ?? 0

	  // Validate hours and minutes
	  // Allow hours up to 24 (e.g., for total sleep in a day rather than clock time)
	  guard hours >= 0, hours <= 24, minutes >= 0, minutes <= 59 else {
		 // If validation fails, consider clearing or not updating,
		 // or provide user feedback. For now, let's prevent bad data.
		 // bigPlanViewModel.sleepTime = nil // or some other handling
		 return
	  }

	  // Format the time string
	  // Ensure minutes are always two digits
	  let formattedTime = "\(hours):\(String(format: "%02d", minutes))"
	  if bigPlanViewModel.sleepTime != formattedTime {
		 bigPlanViewModel.sleepTime = formattedTime
	  }
   }

   private func updateLocalSleepStrings() {
	  // Only update if the ViewModel's value is different from what would be generated by current local strings
	  let currentLocalFormattedTime: String?
	  if sleepHoursString.isEmpty && sleepMinutesString.isEmpty {
		 currentLocalFormattedTime = nil
	  } else {
		 let h = Int(sleepHoursString) ?? 0
		 let m = Int(sleepMinutesString) ?? 0
		 currentLocalFormattedTime = "\(h):\(String(format: "%02d", m))"
	  }

	  if bigPlanViewModel.sleepTime == currentLocalFormattedTime {
		 return // No change needed, prevents potential loops
	  }

	  guard let timeString = bigPlanViewModel.sleepTime else {
		 sleepHoursString = ""
		 sleepMinutesString = ""
		 return
	  }

	  let components = timeString.split(separator: ":").map(String.init)
	  if components.count == 2 {
		 sleepHoursString = components[0]
		 // Ensure minutes string from view model correctly pads if it was stored like "8:5"
		 if let minInt = Int(components[1]) {
			sleepMinutesString = String(format: "%02d", minInt)
		 } else {
			sleepMinutesString = components[1] // Fallback if not an int
		 }

	  } else {
		 // If format is unexpected, clear local strings
		 sleepHoursString = ""
		 sleepMinutesString = ""
	  }
   }
}
