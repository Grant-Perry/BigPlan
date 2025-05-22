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

struct WeekSection: View {
   let entries: [DailyHealthEntry]
   let isCurrentWeek: Bool
   @Binding var expandedWeekId: String?
   let weekId: String
   @Binding var selectedEntry: DailyHealthEntry?
   @Binding var showDeleteConfirmation: Bool
   @Binding var entryToDelete: DailyHealthEntry?
   
   var weekDateRange: (start: Date?, end: Date?) {
	  let sortedDates = entries.map { $0.date }.sorted()
	  return (sortedDates.first, sortedDates.last)
   }
   
   var weekTitle: String {
	  guard let firstDate = weekDateRange.start,
			let lastDate = weekDateRange.end else { return "" }
	  
	  let dateFormatter = DateFormatter()
	  dateFormatter.dateFormat = "MMM d"
	  return "\(dateFormatter.string(from: firstDate)) - \(dateFormatter.string(from: lastDate))"
   }
   
   func getDayName(_ date: Date) -> String {
	  let formatter = DateFormatter()
	  formatter.dateFormat = "EEE"
	  return formatter.string(from: date)
   }
   
   func getHeaderDays(_ firstDate: Date, _ lastDate: Date) -> String {
	  let firstDay = getDayName(firstDate)
	  let lastDay = getDayName(lastDate)
	  return "\(firstDay)\(String(repeating: " ", count: 12))\(lastDay)"
   }
   
   var headerView: some View {
	  HStack {
		 VStack(alignment: .leading, spacing: 2) {
			if let firstDate = weekDateRange.start,
			   let lastDate = weekDateRange.end {
			   Text(getHeaderDays(firstDate, lastDate))
				  .font(.caption)
				  .foregroundColor(.gpRed)
			}
			Text(weekTitle)
			   .font(.headline)
		 }
		 Spacer()
	  }
	  .padding(.vertical, 8)
	  .background(
		 LinearGradient(
			gradient: Gradient(colors: [.gpLtBlue.opacity(0.3), .clear]),
			startPoint: .top,
			endPoint: .bottom
		 )
	  )
   }
   
   var sortedEntries: [DailyHealthEntry] {
	  entries.sorted { $0.date < $1.date }
   }
   
   var body: some View {
	  DisclosureGroup(
		 isExpanded: Binding(
			get: { expandedWeekId == weekId },
			set: { if $0 { expandedWeekId = weekId } else { expandedWeekId = nil } }
		 )
	  ) {
		 ForEach(sortedEntries) { entry in
			EntryRowView(entry: entry)
			   .onTapGesture {
				  selectedEntry = entry
			   }
			   .swipeActions(edge: .trailing) {
				  Button(role: .destructive) {
					 entryToDelete = entry
					 showDeleteConfirmation = true
				  } label: {
					 Label("Delete", systemImage: "trash")
				  }
			   }
		 }
	  } label: {
		 headerView
	  }
	  .accentColor(.primary)
	  .onAppear {
		 if isCurrentWeek {
			expandedWeekId = weekId
		 }
	  }
   }
}

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
   @State private var expandedWeekId: String?
   
   var entriesByWeek: [[DailyHealthEntry]] {
	  let calendar = Calendar.current
	  var cal = Calendar(identifier: .gregorian)
	  cal.firstWeekday = 1  // 1 means Sunday
	  
	  let grouped = Dictionary(grouping: entries) { entry in
		 cal.dateComponents([.weekOfYear, .year], from: entry.date)
	  }
	  return grouped.values.sorted { first, second in
		 guard let date1 = first.first?.date, let date2 = second.first?.date else { return false }
		 return date1 > date2
	  }
   }
   
   func isCurrentWeek(_ entries: [DailyHealthEntry]) -> Bool {
	  guard let firstDate = entries.first?.date else { return false }
	  return Calendar.current.isDate(firstDate, equalTo: Date(), toGranularity: .weekOfYear)
   }
   
   func weekId(_ entries: [DailyHealthEntry]) -> String {
	  guard let firstDate = entries.first?.date else { return UUID().uuidString }
	  let calendar = Calendar.current
	  let components = calendar.dateComponents([.year, .weekOfYear], from: firstDate)
	  return "\(components.year ?? 0)-\(components.weekOfYear ?? 0)"
   }
   
   var body: some View {
	  Group {
		 if entries.isEmpty {
			ContentUnavailableView(
			   "No Health Entries",
			   systemImage: "heart.text.square",
			   description: Text("Tap the + tab to add your first entry")
			)
		 } else {
			List {
			   ForEach(entriesByWeek, id: \.self) { weekEntries in
				  WeekSection(
					 entries: weekEntries,
					 isCurrentWeek: isCurrentWeek(weekEntries),
					 expandedWeekId: $expandedWeekId,
					 weekId: weekId(weekEntries),
					 selectedEntry: $selectedEntry,
					 showDeleteConfirmation: $showDeleteConfirmation,
					 entryToDelete: $entryToDelete
				  )
			   }
			}
			.listStyle(.insetGrouped)
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
