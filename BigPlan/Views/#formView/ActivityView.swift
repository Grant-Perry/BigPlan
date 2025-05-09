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
   @FocusState private var isStepsFocused: Bool
   @State private var focusedToggle: String?

   private var isToday: Bool {
	  Calendar.current.isDateInToday(bigPlanViewModel.date)
   }

   var body: some View {
	  VStack(alignment: .leading, spacing: 18) {
		 Text("ACTIVITY")
			.font(.system(size: 20, weight: .semibold))
			.foregroundColor(.white.opacity(0.9))
			.textCase(.uppercase)

		 VStack(spacing: 18) {
			// Walked AM Toggle
			HStack {
			   Text("Walked AM")
				  .foregroundColor(focusedToggle == "walkedAM" ? .gpGreen : .gray.opacity(0.8))
				  .font(.system(size: 19))
			   Spacer()
			   Toggle("", isOn: $bigPlanViewModel.walkedAM)
				  .labelsHidden()
				  .scaleEffect(1.2)
			}
			.contentShape(Rectangle())
			.formFieldStyle(icon: "figure.walk", hasFocus: focusedToggle == "walkedAM")
			.onTapGesture {
			   focusedToggle = "walkedAM"
			   isStepsFocused = false
			}

			// Walked PM Toggle
			HStack {
			   Text("Walked PM")
				  .foregroundColor(focusedToggle == "walkedPM" ? .gpGreen : .gray.opacity(0.8))
				  .font(.system(size: 19))
			   Spacer()
			   Toggle("", isOn: $bigPlanViewModel.walkedPM)
				  .labelsHidden()
				  .scaleEffect(1.2)
			}
			.contentShape(Rectangle())
			.formFieldStyle(icon: "figure.walk", hasFocus: focusedToggle == "walkedPM")
			.onTapGesture {
			   focusedToggle = "walkedPM"
			   isStepsFocused = false
			}

			// Gym Toggle
			HStack {
			   Text("Went to Gym")
				  .foregroundColor(focusedToggle == "wentToGym" ? .gpGreen : .gray.opacity(0.8))
				  .font(.system(size: 19))
			   Spacer()
			   Toggle("", isOn: $bigPlanViewModel.wentToGym)
				  .labelsHidden()
				  .scaleEffect(1.2)
			}
			.contentShape(Rectangle())
			.formFieldStyle(icon: "dumbbell.fill", hasFocus: focusedToggle == "wentToGym")
			.onTapGesture {
			   focusedToggle = "wentToGym"
			   isStepsFocused = false
			}

			// Red Light Therapy Toggle
			HStack {
			   Text("Red Light Therapy")
				  .foregroundColor(focusedToggle == "rlt" ? .gpGreen : .gray.opacity(0.8))
				  .font(.system(size: 19))
			   Spacer()
			   Toggle("", isOn: Binding(
				  get: { bigPlanViewModel.rlt != nil && !bigPlanViewModel.rlt!.isEmpty },
				  set: { bigPlanViewModel.rlt = $0 ? "yes" : nil }
			   ))
			   .labelsHidden()
			   .scaleEffect(1.2)
			}
			.contentShape(Rectangle())
			.formFieldStyle(icon: "lightbulb.fill", hasFocus: focusedToggle == "rlt")
			.onTapGesture {
			   focusedToggle = "rlt"
			   isStepsFocused = false
			}

			// Steps Field
			HStack {
			   Text("Steps")
				  .foregroundColor(isStepsFocused ? .gpGreen : .gray.opacity(0.8))
				  .font(.system(size: 19))
			   Spacer()
			   if isFetchingSteps {
				  ProgressView()
					 .scaleEffect(1.2)
			   } else if bigPlanViewModel.healthKitAuthorized {
				  HStack(spacing: 12) {
					 TextField("", value: $bigPlanViewModel.steps, format: .number)
						.keyboardType(.numberPad)
						.multilineTextAlignment(.trailing)
						.frame(width: 120)
						.focused($isStepsFocused)
						.font(.system(size: 19))
						.placeholder(when: bigPlanViewModel.steps == nil) {
						   Text("steps")
							  .foregroundColor(isStepsFocused ? .gpGreen : .gray.opacity(0.3))
							  .font(.system(size: 19))
						}

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
							  .font(.system(size: 19))
						}
					 }
				  }
			   } else {
				  Button("Sync") {
					 showHealthKitAuth = true
				  }
				  .buttonStyle(.bordered)
				  .font(.system(size: 19))
			   }
			}
			.contentShape(Rectangle())
			.formFieldStyle(icon: "figure.walk", hasFocus: isStepsFocused)
			.onTapGesture {
			   isStepsFocused = true
			   focusedToggle = nil
			}
		 }
	  }
	  .formSectionStyle()
	  .animation(.none, value: focusedToggle)
	  .animation(.none, value: isStepsFocused)
	  .alert("Health Access", isPresented: $showHealthKitAuth) {
		 Button("Allow Access") {
			Task {
			   isFetchingSteps = true
			   await bigPlanViewModel.requestHealthKitAuthorization()
			   isFetchingSteps = false
			}
		 }
		 Button("Cancel", role: .cancel) { }
	  } message: {
		 Text("Allow BigPlan to access your step count data from Health?")
			.font(.system(size: 19))
	  }
   }
}
