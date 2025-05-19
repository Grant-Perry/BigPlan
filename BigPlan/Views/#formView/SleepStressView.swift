import SwiftUI

struct SleepStressView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @State private var sleepHoursString: String = ""
   @State private var sleepMinutesString: String = ""
   @FocusState private var focusedField: Field?
   @State private var isStressPickerFocused: Bool = false
   @State private var localHKUpdated: Bool = false

   public enum Field: Hashable {
	  case hours, minutes
   }

   var body: some View {
	  VStack(alignment: .leading, spacing: 18) {
		 Text("SLEEP & STRESS")
			.font(.system(size: 20, weight: .semibold))
			.foregroundColor(.white.opacity(0.9))
			.textCase(.uppercase)

		 VStack(spacing: 18) {
			SleepTimeInput(
			   sleepHoursString: $sleepHoursString,
			   sleepMinutesString: $sleepMinutesString,
			   focusedField: focusedField,
			   setFocus: { self.focusedField = $0 },
			   hkUpdatedSleep: localHKUpdated,
			   hasSleepValue: bigPlanViewModel.sleepTime != nil,
			   onUpdate: updateViewModelSleepTime
			)
			.onChange(of: bigPlanViewModel.sleepTime) { _, _ in
			   updateLocalSleepStrings()
			}
			.onChange(of: bigPlanViewModel.isSyncingFromHK) { _, syncing in
			   if !syncing {
				  updateLocalSleepStrings()
			   }
			}
			.onReceive(bigPlanViewModel.objectWillChange) {
			   localHKUpdated = bigPlanViewModel.hkUpdatedSleepTime
			   if bigPlanViewModel.hkUpdatedSleepTime {
				  updateLocalSleepStrings()
			   }
			}

			StressPicker(
			   stressLevel: $bigPlanViewModel.stressLevel,
			   isStressPickerFocused: $isStressPickerFocused,
			   onFocus: { focusedField = nil }
			)
		 }
	  }
	  .formSectionStyle()
	  .animation(.none, value: focusedField)
	  .animation(.none, value: isStressPickerFocused)
	  .onAppear {
		 localHKUpdated = bigPlanViewModel.hkUpdatedSleepTime
		 updateLocalSleepStrings()
	  }
   }

   private func updateViewModelSleepTime() {
	  if sleepHoursString.isEmpty && sleepMinutesString.isEmpty {
		 bigPlanViewModel.sleepTime = nil
		 if !bigPlanViewModel.isSyncingFromHK {
			bigPlanViewModel.hkUpdatedSleepTime = false
		 }
		 return
	  }

	  let hours = Int(sleepHoursString) ?? 0
	  let minutes = Int(sleepMinutesString) ?? 0

	  guard hours >= 0, hours <= 24, minutes >= 0, minutes <= 59 else {
		 return
	  }

	  let formattedTime = "\(hours)h \(minutes)m"
	  if bigPlanViewModel.sleepTime != formattedTime {
		 bigPlanViewModel.sleepTime = formattedTime
		 if !bigPlanViewModel.isSyncingFromHK {
			bigPlanViewModel.hkUpdatedSleepTime = false
		 }
	  }
   }

   private func updateLocalSleepStrings() {
	  let currentLocalFormattedTime: String?
	  if sleepHoursString.isEmpty && sleepMinutesString.isEmpty {
		 currentLocalFormattedTime = nil
	  } else {
		 let h = Int(sleepHoursString) ?? 0
		 let m = Int(sleepMinutesString) ?? 0
		 currentLocalFormattedTime = "\(h):\(String(format: "%02d", m))"
	  }

	  if bigPlanViewModel.sleepTime == currentLocalFormattedTime {
		 return
	  }

	  guard let timeString = bigPlanViewModel.sleepTime else {
		 sleepHoursString = ""
		 sleepMinutesString = ""
		 return
	  }

	  if timeString.contains("h") {
		 let components = timeString.lowercased().split(separator: "h")
		 if let hours = components.first?.trimmingCharacters(in: .whitespaces),
			let minutes = components.last?.replacingOccurrences(of: "m", with: "").trimmingCharacters(in: .whitespaces) {
			sleepHoursString = hours
			sleepMinutesString = String(format: "%02d", Int(minutes) ?? 0)
		 }
	  } else {
		 let components = timeString.split(separator: ":").map(String.init)
		 if components.count == 2 {
			sleepHoursString = components[0]
			if let minInt = Int(components[1]) {
			   sleepMinutesString = String(format: "%02d", minInt)
			} else {
			   sleepMinutesString = components[1]
			}
		 }
	  }
   }
}
