//
//  EntryFormView.swift
//  BigPlan
//
//  Created by Gp. on 5/5/25.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "BigPlan", category: "SaveDebug")

struct DailyFormView: View {
   @Binding var selectedTab: Int
   @Environment(\.modelContext) private var modelContext
   @StateObject var bigPlanViewModel: BigPlanViewModel
   @Environment(\.dismiss) private var dismiss

   var body: some View {
	  NavigationStack {
		 VStack(alignment: .leading, spacing: 4) {
			VStack(alignment: .leading, spacing: 2) {
			   Text(bigPlanViewModel.isEditing ? "Edit Entry" : "New Entry")
				  .font(.title2)
				  .fontWeight(.semibold)
			   Text(bigPlanViewModel.date.formatted(date: .abbreviated, time: .omitted))
				  .font(.subheadline)
				  .foregroundColor(.secondary)
			}
			.padding(.horizontal)
			.padding(.top, 8)

			Form {
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
		 }
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
	  Section {
		 DatePicker("Date", selection: $bigPlanViewModel.date, displayedComponents: .date)
		 DatePicker("Wake Time", selection: $bigPlanViewModel.wakeTime, displayedComponents: .hourAndMinute)
	  } header: {
		 Text("Date & Time")
	  }
   }
}

private struct ReadingsView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @State private var systolic: String = ""
   @State private var diastolic: String = ""

   var body: some View {
	  Section {
		 glucoseField
		 ketonesField
		 bloodPressureField
		 weightField
	  } header: {
		 Text("Readings")
	  }
	  .onAppear {
		 loadBloodPressure()
	  }
   }

   private var glucoseField: some View {
	  LabeledContent("Glucose (mg/dL)") {
		 TextField("Enter glucose", value: $bigPlanViewModel.glucose, format: .number.rounded())
			.keyboardType(.decimalPad)
			.textFieldStyle(.roundedBorder)
			.multilineTextAlignment(.trailing)
	  }
   }

   private var ketonesField: some View {
	  LabeledContent("Ketones (mmol/L)") {
		 TextField("Enter ketones", value: $bigPlanViewModel.ketones, format: .number.rounded())
			.keyboardType(.decimalPad)
			.textFieldStyle(.roundedBorder)
			.multilineTextAlignment(.trailing)
	  }
   }

   private var bloodPressureField: some View {
	  LabeledContent("Blood Pressure") {
		 HStack {
			TextField("Systolic", text: $systolic)
			   .placeholder(when: systolic.isEmpty) {
				  Text("120").foregroundColor(.gray.opacity(0.5))
			   }
			   .keyboardType(.numberPad)
			   .textFieldStyle(.roundedBorder)
			   .frame(maxWidth: 80)
			Text("/")
			TextField("Diastolic", text: $diastolic)
			   .placeholder(when: diastolic.isEmpty) {
				  Text("80").foregroundColor(.gray.opacity(0.5))
			   }
			   .keyboardType(.numberPad)
			   .textFieldStyle(.roundedBorder)
			   .frame(maxWidth: 80)
		 }
	  }
	  .onChange(of: systolic) { _, _ in
		 updateBloodPressure()
	  }
	  .onChange(of: diastolic) { _, _ in
		 updateBloodPressure()
	  }
   }

   private var weightField: some View {
	  LabeledContent("Weight (lbs.)") {
		 TextField("Enter weight lbs.", value: $bigPlanViewModel.weight, format: .number.rounded())
			.keyboardType(.decimalPad)
			.textFieldStyle(.roundedBorder)
			.multilineTextAlignment(.trailing)
			.placeholder(when: bigPlanViewModel.weight == nil) {
			   Text("185.0").foregroundColor(.gray.opacity(0.5))
			}
	  }
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
	  Section("Sleep & Stress") {
		 LabeledContent("Sleep Hours") {
			TextField("Enter hours", value: $bigPlanViewModel.sleepHours, format: .number.rounded())
			   .keyboardType(.decimalPad)
			   .textFieldStyle(.roundedBorder)
			   .multilineTextAlignment(.trailing)
		 }

		 Picker("Stress Level", selection: Binding(
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
	  }
   }
}

private struct ActivityView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel

   var body: some View {
	  Section("Activity") {
		 Toggle("Walked AM", isOn: $bigPlanViewModel.walkedAM)
		 Toggle("Walked PM", isOn: $bigPlanViewModel.walkedPM)
		 Toggle("Went to Gym", isOn: $bigPlanViewModel.wentToGym)
		 Toggle("Red Light Therapy (RLT)", isOn: Binding(
			get: { bigPlanViewModel.rlt != nil && !bigPlanViewModel.rlt!.isEmpty },
			set: { bigPlanViewModel.rlt = $0 ? "yes" : nil }
		 ))
		 LabeledContent("Steps") {
			TextField("Enter steps", value: $bigPlanViewModel.steps, format: .number)
			   .keyboardType(.numberPad)
			   .textFieldStyle(.roundedBorder)
			   .multilineTextAlignment(.trailing)
		 }
	  }
   }
}

private struct MealsView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel

   var body: some View {
	  Section("Meals") {
		 DatePicker("First Meal", selection: Binding(
			get: { bigPlanViewModel.firstMealTime ?? Date() },
			set: { bigPlanViewModel.firstMealTime = $0 }
		 ), displayedComponents: .hourAndMinute)

		 DatePicker("Last Meal", selection: Binding(
			get: { bigPlanViewModel.lastMealTime ?? Date() },
			set: { bigPlanViewModel.lastMealTime = $0 }
		 ), displayedComponents: .hourAndMinute)
	  }
   }
}

private struct NotesView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel

   var body: some View {
	  Section("Notes") {
		 let notesBinding = Binding(
			get: { bigPlanViewModel.notes ?? "" },
			set: { bigPlanViewModel.notes = $0.isEmpty ? nil : $0 }
		 )
		 TextEditor(text: notesBinding)
			.frame(minHeight: 100)
			.padding(8)
			.background(RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemBackground)))
			.overlay(
			   Group {
				  if notesBinding.wrappedValue.isEmpty {
					 Text("Enter any additional notes here...")
						.foregroundColor(.gray.opacity(0.5))
						.padding(.top, 16)
						.padding(.leading, 12)
				  }
			   },
			   alignment: .topLeading
			)
	  }
   }
}

private struct ActionButtonsView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @Binding var selectedTab: Int
   @Environment(\.dismiss) private var dismiss
   @State private var showDeleteConfirmation = false

   var body: some View {
	  Section {
		 VStack(spacing: 12) {
			Button("Save Entry") {
			   bigPlanViewModel.saveEntry()
			   if bigPlanViewModel.isEditing {
				  dismiss()  // Dismiss if editing existing entry
			   } else {
				  selectedTab = 0  // Go to list if new entry
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
