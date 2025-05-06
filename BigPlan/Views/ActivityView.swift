//   ActivityView.swift
//   BigPlan
//
//   Created by: Gp. on 5/5/25 at 7:39 PM
//     Modified:
//
//  Copyright Delicious Studios, LLC. - Grant Perry

import SwiftUI

struct ActivityView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @State private var showHealthKitAuth = false
   @State private var isFetchingSteps = false

   private var isToday: Bool {
	  Calendar.current.isDateInToday(bigPlanViewModel.date)
   }

   var body: some View {
	  VStack(alignment: .leading, spacing: 20) {
		 Text("ACTIVITY")
			.font(.subheadline)
			.foregroundColor(.gray)

		 VStack(spacing: 16) {
			HStack {
			   Text("Walked AM")
			   Spacer()
			   Toggle("", isOn: $bigPlanViewModel.walkedAM)
				  .labelsHidden()
			}
			Divider()

			HStack {
			   Text("Walked PM")
			   Spacer()
			   Toggle("", isOn: $bigPlanViewModel.walkedPM)
				  .labelsHidden()
			}
			Divider()

			HStack {
			   Text("Went to Gym")
			   Spacer()
			   Toggle("", isOn: $bigPlanViewModel.wentToGym)
				  .labelsHidden()
			}
			Divider()

			HStack {
			   Text("Red Light Therapy")
			   Spacer()
			   Toggle("", isOn: Binding(
				  get: { bigPlanViewModel.rlt != nil && !bigPlanViewModel.rlt!.isEmpty },
				  set: { bigPlanViewModel.rlt = $0 ? "yes" : nil }
			   ))
			   .labelsHidden()
			}
			Divider()

			HStack {
			   Text("Steps")
			   Spacer()
			   if isFetchingSteps {
				  ProgressView()
					 .frame(width: 44)
			   } else if bigPlanViewModel.healthKitAuthorized {
				  HStack(spacing: 8) {
					 TextField("", value: $bigPlanViewModel.steps, format: .number)
						.keyboardType(.numberPad)
						.multilineTextAlignment(.trailing)
						.frame(width: 80)

					 if !bigPlanViewModel.isEditing || isToday {
						Button {
						   Task {
							  isFetchingSteps = true
							  await bigPlanViewModel.fetchTodaySteps()
							  isFetchingSteps = false
						   }
						} label: {
						   Image(systemName: "arrow.clockwise")
							  .foregroundColor(.accentColor)
						}
					 }
				  }
			   } else {
				  Button("Sync") {
					 showHealthKitAuth = true
				  }
				  .buttonStyle(.bordered)
			   }
			}
		 }
		 .padding()
		 .background(Color(.secondarySystemBackground))
		 .cornerRadius(10)
	  }
	  .alert("Health Access", isPresented: $showHealthKitAuth) {
		 Button("Allow Access") {
			Task {
			   isFetchingSteps = true
			   await bigPlanViewModel.requestHealthKitAuthorization()
			   isFetchingSteps = false
			}
		 }
		 Button("Cancel", role: .cancel) {}
	  } message: {
		 Text("Allow BigPlan to access your step count data from Health?")
	  }
   }
}
