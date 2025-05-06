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

   var body: some View {
	  VStack(alignment: .leading, spacing: 20) {
		 Text("SLEEP & STRESS")
			.font(.subheadline)
			.foregroundColor(.gray)

		 VStack(spacing: 16) {
			HStack {
			   Text("Sleep Time")
			   Spacer()
			   TextField("H", text: $sleepHoursString)
				  .keyboardType(.numberPad)
				  .multilineTextAlignment(.trailing)
				  .frame(width: 40)
				  .onChange(of: sleepHoursString) { _, newValue in
					 if let hours = Int(newValue), hours > 24 {
						sleepHoursString = "24"
					 }
					 if newValue.count > 2 {
						sleepHoursString = String(newValue.prefix(2))
					 }
				  }
			   Text(":")
			   TextField("M", text: $sleepMinutesString)
				  .keyboardType(.numberPad)
				  .multilineTextAlignment(.trailing)
				  .frame(width: 40)
				  .onChange(of: sleepMinutesString) { _, newValue in
					 if let minutes = Int(newValue), minutes > 59 {
						sleepMinutesString = "59"
					 }
					 if newValue.count > 2 {
						sleepMinutesString = String(newValue.prefix(2))
					 }
				  }
			}
			Divider()

			HStack {
			   Text("Stress Level")
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
				  }
			   )) {
				  Text("").tag("")
				  Text("Low").tag("Low")
				  Text("Medium").tag("Medium")
				  Text("High").tag("High")
			   }
			   .labelsHidden()
			}
		 }
		 .padding()
		 .background(Color(.secondarySystemBackground))
		 .cornerRadius(10)
	  }
	  .onChange(of: sleepHoursString) { _, _ in updateViewModelSleepTime() }
	  .onChange(of: sleepMinutesString) { _, _ in updateViewModelSleepTime() }
	  .onAppear {
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
	  guard hours <= 24, minutes <= 59 else { return }

	  // Format the time string
	  let formattedTime = "\(hours):\(String(format: "%02d", minutes))"
	  bigPlanViewModel.sleepTime = formattedTime
   }

   private func updateLocalSleepStrings() {
	  guard let timeString = bigPlanViewModel.sleepTime else {
		 sleepHoursString = ""
		 sleepMinutesString = ""
		 return
	  }

	  let components = timeString.split(separator: ":")
	  if components.count == 2 {
		 sleepHoursString = String(components[0])
		 sleepMinutesString = String(components[1])
	  }
   }
}
