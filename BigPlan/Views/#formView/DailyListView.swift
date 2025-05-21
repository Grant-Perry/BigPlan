//
//  DailyListView.swift
//  BigPlan
//
//  Created by: Gp. on 5/5/25 at 10:54 AM
//

import OSLog
private let logger = Logger(subsystem: "BigPlan", category: "DailyListView")

import SwiftUI
import SwiftData

struct DailyListView: View {
   @Binding var selectedTab: Int
   @Environment(\.modelContext) private var modelContext
   @State private var showSettings = false
   
   @Query(
	  sort: [SortDescriptor(\DailyHealthEntry.date, order: .reverse)]
   ) private var entries: [DailyHealthEntry]
   
   @State private var selectedEntry: DailyHealthEntry?
   @State private var showDeleteConfirmation = false
   @State private var entryToDelete: DailyHealthEntry?
   @State private var showUndoToast = false
   @State private var recentlyDeletedEntry: DailyHealthEntry?
   
   var body: some View {
	  Group {
		 if entries.isEmpty {
			ContentUnavailableView(
			   "No Health Entries",
			   systemImage: "heart.text.square",
			   description: Text("Tap the + tab to add your first entry")
			)
		 } else {
			EntryListView(
			   selectedEntry: $selectedEntry,
			   showDeleteConfirmation: $showDeleteConfirmation,
			   entryToDelete: $entryToDelete
			)
		 }
	  }
	  .navigationTitle("Health History")
	  .navigationDestination(item: $selectedEntry) { entry in
		 DailyFormView(
			selectedTab: $selectedTab,
			bigPlanViewModel: BigPlanViewModel(context: modelContext, existingEntry: entry)
		 )
	  }
	  .sheet(isPresented: $showSettings) {
		 SettingsView(modelContext: modelContext)
	  }
	  .toolbar {
		 ToolbarItem(placement: .navigationBarTrailing) {
			Button {
			   showSettings = true
			} label: {
			   Image(systemName: "gearshape.fill")
				  .font(.system(size: 19))
			}
		 }
	  }
	  .alert("Delete this entry?", isPresented: $showDeleteConfirmation) {
		 Button("Delete", role: .destructive) {
			if let entry = entryToDelete {
			   withAnimation {
				  modelContext.delete(entry)
				  try? modelContext.save()
				  entryToDelete = nil
			   }
			}
		 }
		 Button("Cancel", role: .cancel) { }
	  }
	  .overlay(alignment: .bottom) {
		 if showUndoToast {
			UndoToastView(
			   showToast: $showUndoToast,
			   recentlyDeletedEntry: $recentlyDeletedEntry
			)
		 }
	  }
	  AppConstants.VersionFooter()
   }
}

#Preview {
   let config = ModelConfiguration(isStoredInMemoryOnly: true)
   let container = try! ModelContainer(for: DailyHealthEntry.self, configurations: config)
   
   let context = ModelContext(container)
   let sampleEntry1 = DailyHealthEntry(
	  date: .now,
	  wakeTime: .now,
	  glucose: 95.0,
	  ketones: 1.2,
	  bloodPressure: "120/80",
	  weight: 185.5,
	  sleepTime: "8h",
	  stressLevel: 2,
	  walkedAM: true,
	  walkedPM: false,
	  firstMealTime: .now,
	  lastMealTime: .now.addingTimeInterval(36000),
	  steps: 8500,
	  wentToGym: true,
	  rlt: "15min",
	  weatherData: "Sunny, 72°F",
	  notes: "Great day!"
   )
   context.insert(sampleEntry1)
   
   let sampleEntry2 = DailyHealthEntry(
	  date: Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
	  wakeTime: .now,
	  glucose: 98.0,
	  ketones: 0.8,
	  bloodPressure: "118/78",
	  weight: 186.0,
	  sleepTime: "7.5h",
	  stressLevel: 3,
	  walkedAM: true,
	  walkedPM: true,
	  firstMealTime: .now,
	  lastMealTime: .now.addingTimeInterval(32400),
	  steps: 10200,
	  wentToGym: false,
	  rlt: "20min",
	  weatherData: "Cloudy, 68°F",
	  notes: "Decent day"
   )
   context.insert(sampleEntry2)
   
   return DailyListView(selectedTab: .constant(0))
	  .modelContainer(container)
}
