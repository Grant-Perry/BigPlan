//
//  EntryFormView.swift
//  BigPlan
//
//  Created by Gp. on 5/5/25.
//

import SwiftUI
import SwiftData
import OSLog
import HealthKit

private let logger = Logger(subsystem: "BigPlan", category: "SaveDebug")

struct DailyFormView: View {
   @Binding var selectedTab: Int
   @Environment(\.modelContext) private var modelContext
   @StateObject var bigPlanViewModel: BigPlanViewModel
   @Environment(\.dismiss) private var dismiss

   var body: some View {
	  NavigationStack {
		 ScrollView {
			VStack(alignment: .leading, spacing: 20) {
			   VStack(alignment: .leading, spacing: 4) {
				  Text(bigPlanViewModel.isEditing ? "Edit Entry" : "New Entry")
					 .font(.title)
					 .fontWeight(.semibold)
				  Text(bigPlanViewModel.date.formatted(date: .abbreviated, time: .omitted))
					 .font(.subheadline)
					 .foregroundColor(.gray)
			   }
			   .padding(.horizontal)

			   VStack(spacing: 24) {
				  DateTimeView(bigPlanViewModel: bigPlanViewModel)
				  ReadingsView(bigPlanViewModel: bigPlanViewModel)
				  SleepStressView(bigPlanViewModel: bigPlanViewModel)
				  ActivityView(bigPlanViewModel: bigPlanViewModel)
				  MealsView(bigPlanViewModel: bigPlanViewModel)
				  NotesView(bigPlanViewModel: bigPlanViewModel)
				  ActionButtonsView(
					 bigPlanViewModel: bigPlanViewModel,
					 selectedTab: $selectedTab
				  )
			   }
			   .padding(.horizontal)

			   Spacer(minLength: 20)
			   VersionFooter()
			}
		 }
		 .scrollDismissesKeyboard(.immediately)
		 .navigationBarTitleDisplayMode(.inline)
		 .toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
			   Button("Done") {
				  if bigPlanViewModel.isEditing {
					 dismiss()
				  } else {
					 selectedTab = 0
				  }
			   }
			}
		 }
	  }
   }
}

// MARK: - Section Views
private struct DateTimeView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel

   var body: some View {
	  VStack(alignment: .leading, spacing: 12) {
		 Text("Date & Time")
			.font(.headline)
			.padding(.top)

		 DatePicker("Date", selection: $bigPlanViewModel.date, displayedComponents: .date)
			.labelsHidden()

		 DatePicker("Wake Time", selection: $bigPlanViewModel.wakeTime, displayedComponents: .hourAndMinute)
			.labelsHidden()
	  }
   }
}

private struct ReadingsView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @State private var systolic: String = ""
   @State private var diastolic: String = ""

   var body: some View {
	  VStack(alignment: .leading, spacing: 20) {
		 Text("READINGS")
			.font(.subheadline)
			.foregroundColor(.gray)

		 VStack(spacing: 16) {
			HStack {
			   Text("Glucose (mg/dL)")
			   Spacer()
			   TextField("", value: $bigPlanViewModel.glucose, format: .number.rounded())
				  .keyboardType(.decimalPad)
				  .multilineTextAlignment(.trailing)
			}
			Divider()

			HStack {
			   Text("Ketones (mmol/L)")
			   Spacer()
			   TextField("", value: $bigPlanViewModel.ketones, format: .number.rounded())
				  .keyboardType(.decimalPad)
				  .multilineTextAlignment(.trailing)
			}
			Divider()

			HStack {
			   Text("Blood Pressure")
			   Spacer()
			   TextField("", text: $systolic)
				  .placeholder(when: systolic.isEmpty) {
					 Text("120").foregroundColor(.gray.opacity(0.5))
				  }
				  .keyboardType(.numberPad)
				  .multilineTextAlignment(.trailing)
				  .frame(width: 50)
			   Text("/")
			   TextField("", text: $diastolic)
				  .placeholder(when: diastolic.isEmpty) {
					 Text("80").foregroundColor(.gray.opacity(0.5))
				  }
				  .keyboardType(.numberPad)
				  .multilineTextAlignment(.trailing)
				  .frame(width: 50)
			}
		 }
		 .padding()
		 .background(Color(.secondarySystemBackground))
		 .cornerRadius(10)
	  }
	  .onChange(of: systolic) { updateBloodPressure() }
	  .onChange(of: diastolic) { updateBloodPressure() }
	  .onAppear { loadBloodPressure() }
   }

   private func loadBloodPressure() {
	  if let bp = bigPlanViewModel.bloodPressure?.split(separator: "/") {
		 systolic = String(bp[0])
		 if bp.count > 1 {
			diastolic = String(bp[1])
		 }
	  }
   }

   private func updateBloodPressure() {
	  if !systolic.isEmpty && !diastolic.isEmpty {
		 bigPlanViewModel.bloodPressure = "\(systolic)/\(diastolic)"
	  } else {
		 bigPlanViewModel.bloodPressure = nil
	  }
   }
}

private struct SleepStressView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel

   var body: some View {
	  VStack(alignment: .leading, spacing: 20) {
		 Text("SLEEP & STRESS")
			.font(.subheadline)
			.foregroundColor(.gray)

		 VStack(spacing: 16) {
			HStack {
			   Text("Sleep Hours")
			   Spacer()
			   TextField("", value: $bigPlanViewModel.sleepHours, format: .number.rounded())
				  .keyboardType(.decimalPad)
				  .multilineTextAlignment(.trailing)
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
   }
}

private struct ActivityView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @State private var showHealthKitAuth = false
   @State private var isFetchingSteps = false

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

					 if !bigPlanViewModel.isEditing {
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

private struct MealsView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel

   var body: some View {
	  VStack(alignment: .leading, spacing: 20) {
		 Text("MEALS")
			.font(.subheadline)
			.foregroundColor(.gray)

		 VStack(spacing: 16) {
			HStack {
			   Text("First Meal")
			   Spacer()
			   DatePicker("", selection: Binding(
				  get: { bigPlanViewModel.firstMealTime ?? Date() },
				  set: { bigPlanViewModel.firstMealTime = $0 }
			   ), displayedComponents: .hourAndMinute)
			   .labelsHidden()
			}
			Divider()

			HStack {
			   Text("Last Meal")
			   Spacer()
			   DatePicker("", selection: Binding(
				  get: { bigPlanViewModel.lastMealTime ?? Date() },
				  set: { bigPlanViewModel.lastMealTime = $0 }
			   ), displayedComponents: .hourAndMinute)
			   .labelsHidden()
			}
		 }
		 .padding()
		 .background(Color(.secondarySystemBackground))
		 .cornerRadius(10)
	  }
   }
}

private struct NotesView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel

   var body: some View {
	  VStack(alignment: .leading, spacing: 12) {
		 Text("Notes")
			.font(.headline)
			.padding(.top)

		 TextEditor(text: Binding(
			get: { bigPlanViewModel.notes ?? "" },
			set: { bigPlanViewModel.notes = $0.isEmpty ? nil : $0 }
		 ))
		 .frame(minHeight: 100)
		 .overlay(
			Group {
			   if (bigPlanViewModel.notes ?? "").isEmpty {
				  Text("Enter any additional notes here...")
					 .foregroundColor(.gray.opacity(0.5))
					 .padding(.top, 16)
					 .padding(.leading, 12)
			   }
			},
			alignment: .topLeading
		 )
		 .textFieldStyle(.roundedBorder)
	  }
   }
}

private struct ActionButtonsView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @Binding var selectedTab: Int
   @Environment(\.dismiss) private var dismiss
   @State private var showDeleteConfirmation = false

   var body: some View {
	  VStack(alignment: .leading, spacing: 12) {
		 Text("Actions")
			.font(.headline)
			.padding(.top)

		 VStack(spacing: 12) {
			Button("Save Entry") {
			   bigPlanViewModel.saveEntry()
			   if bigPlanViewModel.isEditing {
				  dismiss()
			   } else {
				  selectedTab = 0
			   }
			}
			.frame(maxWidth: .infinity)
			.buttonStyle(.borderedProminent)

			if bigPlanViewModel.isEditing {
			   Button(role: .destructive) {
				  showDeleteConfirmation = true
			   } label: {
				  Text("Delete Entry")
			   }
			   .alert("Are you sure?", isPresented: $showDeleteConfirmation) {
				  Button("Delete", role: .destructive) {
					 bigPlanViewModel.deleteThisEntry()
					 dismiss()
				  }
				  Button("Cancel", role: .cancel) { }
			   }
			   .frame(maxWidth: .infinity)
			}
		 }
	  }
   }
}

// MARK: - View Extensions
extension View {
   func placeholder<Content: View>(
	  when shouldShow: Bool,
	  alignment: Alignment = .leading,
	  @ViewBuilder placeholder: () -> Content
   ) -> some View {
	  ZStack(alignment: alignment) {
		 placeholder().opacity(shouldShow ? 1 : 0)
		 self
	  }
   }
}

struct DailyFormView_Previews: PreviewProvider {
   static var previews: some View {
	  let container = try! ModelContainer(for: DailyHealthEntry.self)
	  let context = ModelContext(container)
	  return DailyFormView(
		 selectedTab: .constant(0),
		 bigPlanViewModel: BigPlanViewModel(context: context)
	  )
	  .modelContainer(container)
   }
}

struct VersionFooter: View {
   var body: some View {
	  Text("Version 1.0")
		 .font(.footnote)
		 .foregroundColor(.secondary)
		 .padding(.bottom, 16)
   }
}
