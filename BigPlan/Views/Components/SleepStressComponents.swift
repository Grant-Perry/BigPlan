import SwiftUI

struct SleepTimeInput: View {
   @Binding var sleepHoursString: String
   @Binding var sleepMinutesString: String
   var focusedField: SleepStressView.Field?
   var setFocus: (SleepStressView.Field?) -> Void
   var hkUpdatedSleep: Bool
   var hasSleepValue: Bool
   var onUpdate: () -> Void
   
   var body: some View {
	  HStack {
		 Text("Sleep Time")
			.foregroundColor(focusedField != nil ? .gpGreen : .gray.opacity(0.8))
			.font(.system(size: 19))
		 Spacer()
		 
		 // Simple HStack with consistent styling
		 HStack(spacing: 4) {
			// Hours
			TextField("", text: $sleepHoursString)
			   .keyboardType(.numberPad)
			   .multilineTextAlignment(.trailing)
			   .font(.system(size: 19))
			   .frame(width: 30)
			   .onChange(of: sleepHoursString) { _, newValue in
				  let filtered = newValue.filter { $0.isNumber }
				  if filtered != newValue {
					 sleepHoursString = filtered
					 return
				  }
				  if let hours = Int(filtered) {
					 if hours > 24 {
						sleepHoursString = "24"
					 } else if filtered.count > 2 {
						sleepHoursString = String(filtered.prefix(2))
					 }
				  }
				  onUpdate()
			   }
			   .onTapGesture { setFocus(.hours) }
			
			Text("h")
			   .foregroundColor(.gray.opacity(0.5))
			   .font(.system(size: 16))
			
			// Minutes
			TextField("", text: $sleepMinutesString)
			   .keyboardType(.numberPad)
			   .multilineTextAlignment(.trailing)
			   .font(.system(size: 19))
			   .frame(width: 30)
			   .onChange(of: sleepMinutesString) { _, newValue in
				  let filtered = newValue.filter { $0.isNumber }
				  if filtered != newValue {
					 sleepMinutesString = filtered
					 return
				  }
				  if let minutes = Int(filtered) {
					 if minutes > 59 {
						sleepMinutesString = "59"
					 } else if filtered.count > 2 {
						sleepMinutesString = String(filtered.prefix(2))
					 }
				  }
				  onUpdate()
			   }
			   .onTapGesture { setFocus(.minutes) }
			
			Text("m")
			   .foregroundColor(.gray.opacity(0.5))
			   .font(.system(size: 16))
		 }
		 
		 HKBadgeView(show: hkUpdatedSleep, hasValue: hasSleepValue)
	  }
	  .formFieldStyle(icon: "moon.zzz.fill", hasFocus: focusedField != nil)
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
