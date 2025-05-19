import SwiftUI

struct SleepTimeInput: View {
   @Binding var sleepHoursString: String
   @Binding var sleepMinutesString: String
   let focusedField: SleepStressView.Field?
   let setFocus: (SleepStressView.Field?) -> Void
   let hkUpdatedSleep: Bool
   let hasSleepValue: Bool
   let onUpdate: () -> Void

   private func parseHKSleepFormat(_ timeString: String) -> (hours: String, minutes: String)? {
	  let components = timeString.lowercased().split(separator: "h")
	  guard let hours = components.first?.trimmingCharacters(in: .whitespaces),
			let minutes = components.last?.replacingOccurrences(of: "m", with: "").trimmingCharacters(in: .whitespaces)
	  else { return nil }
	  return (hours, minutes)
   }

   var body: some View {
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
			   .font(.system(size: 19))
			   .onTapGesture {
				  setFocus(.hours)
			   }

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
			   .font(.system(size: 19))
			   .onTapGesture {
				  setFocus(.minutes)
			   }
		 }
		 HKBadgeView(show: hkUpdatedSleep, hasValue: hasSleepValue)
	  }
	  .contentShape(Rectangle())
	  .formFieldStyle(icon: "bed.double.fill", hasFocus: focusedField != nil)
	  .onTapGesture {
		 if focusedField == nil {
			setFocus(.hours)
		 }
	  }
	  .onChange(of: sleepHoursString) { _, newValue in
		 if let hours = Int(newValue), hours > 24 {
			sleepHoursString = "24"
		 }
		 if newValue.count > 2 {
			sleepHoursString = String(newValue.prefix(2))
		 }
		 onUpdate()
	  }
	  .onChange(of: sleepMinutesString) { _, newValue in
		 if let minutes = Int(newValue), minutes > 59 {
			sleepMinutesString = "59"
		 }
		 if newValue.count > 2 {
			sleepMinutesString = String(newValue.prefix(2))
		 }
		 onUpdate()
	  }
   }
}

struct StressPicker: View {
   @Binding var stressLevel: Int?
   @Binding var isStressPickerFocused: Bool
   var onFocus: () -> Void

   var body: some View {
	  HStack {
		 Text("Stress Level")
			.foregroundColor(isStressPickerFocused ? .gpGreen : .gray.opacity(0.8))
			.font(.system(size: 19))
		 Spacer()
		 Picker("", selection: Binding(
			get: {
			   switch stressLevel {
				  case 1: return "Low"
				  case 2: return "Medium"
				  case 3: return "High"
				  default: return ""
			   }
			},
			set: { newValue in
			   switch newValue {
				  case "Low": stressLevel = 1
				  case "Medium": stressLevel = 2
				  case "High": stressLevel = 3
				  default: stressLevel = nil
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
		 onFocus()
	  }
   }
}
