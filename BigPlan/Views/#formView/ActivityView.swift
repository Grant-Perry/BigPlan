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
   @Binding var liveSteps: Int
   @State private var liveWeekSteps: Int = 0
   @State private var debounceTimer: Timer?
   @State private var lastFetchedDate: Date?
   
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
			   } else {
				  VStack(alignment: .trailing, spacing: 3) {
					 Text("\(liveSteps.formatted(.number.grouping(.automatic))) steps")
						.font(.system(size: 19))
					 Text("Week Total: \(liveWeekSteps.formatted(.number.grouping(.automatic)))")
						.font(.system(size: 16))
						.foregroundColor(.secondary)
				  }
			   }
			}
			.contentShape(Rectangle())
			.formFieldStyle(icon: "figure.walk", hasFocus: isStepsFocused)
			.onTapGesture {
			   isStepsFocused = true
			   focusedToggle = nil
			}
			.onChange(of: bigPlanViewModel.date) { _, newDate in
			   triggerStepDebouncedFetch(for: newDate)
			}
		 }
	  }
	  .formSectionStyle()
	  .animation(.none, value: focusedToggle)
	  .animation(.none, value: isStepsFocused)
	  .onAppear {
		 triggerStepDebouncedFetch(for: bigPlanViewModel.date)
	  }
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
   
   private func triggerStepDebouncedFetch(for date: Date) {
	  debounceTimer?.invalidate()
	  debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.7, repeats: false) { _ in
		 Task {
			liveSteps = await HealthKitManager.shared.steps(for: date)
			// Roll live week count for ending with this date:
			let calendar = Calendar.current
			var weekTotal = 0
			for offset in 0..<7 {
			   if let d = calendar.date(byAdding: .day, value: -offset, to: date) {
				  weekTotal += await HealthKitManager.shared.steps(for: d)
			   }
			}
			liveWeekSteps = weekTotal
			lastFetchedDate = date
		 }
	  }
   }
}
