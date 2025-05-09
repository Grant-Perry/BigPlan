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
   
   @Query(
	  sort: [SortDescriptor(\DailyHealthEntry.date, order: .reverse)]
   ) private var entries: [DailyHealthEntry]
   
   @State private var selectedEntry: DailyHealthEntry?
   @State private var showDeleteConfirmation = false
   @State private var entryToDelete: DailyHealthEntry?
   @State private var showUndoToast = false
   @State private var recentlyDeletedEntry: DailyHealthEntry?
   
   var body: some View {
	  NavigationStack {
		 Group {
			if entries.isEmpty {
			   ContentUnavailableView(
				  "No Health Entries",
				  systemImage: "heart.text.square",
				  description: Text("Tap the + tab to add your first entry")
			   )
			} else {
			   entryList
			}
		 }
		 .navigationTitle("Health History")
		 .navigationDestination(item: $selectedEntry) { entry in
			DailyFormView(
			   selectedTab: $selectedTab,
			   bigPlanViewModel: BigPlanViewModel(context: modelContext, existingEntry: entry)
			)
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
   
   @ViewBuilder
   private var entryList: some View {
	  List {
		 ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
			EntryRowView(entry: entry)
			   .listRowBackground(
				  index % 2 == 0 ?
				  Color(.systemBackground) :
					 Color(.secondarySystemBackground)
			   )
			   .contentShape(Rectangle())
			   .onTapGesture {
				  selectedEntry = entry
			   }
		 }
		 .onDelete { indexSet in
			if let index = indexSet.first {
			   entryToDelete = entries[index]
			   showDeleteConfirmation = true
			}
		 }
	  }
	  .listStyle(.plain)
   }
}

// MARK: - Entry Row View
private struct EntryRowView: View {
   @Environment(\.modelContext) private var modelContext
   let entry: DailyHealthEntry
   
   private let metricFontSize: CGFloat = 19
   private let smallMetricFontSize: CGFloat = 14
   private let metricIconSize: CGFloat = 17
   private let dateFontSize: CGFloat = 25
   
   private let numberFormatter: NumberFormatter = {
	  let formatter = NumberFormatter()
	  formatter.numberStyle = .decimal
	  formatter.maximumFractionDigits = 1
	  return formatter
   }()
   
   var body: some View {
	  VStack(alignment: .leading, spacing: 8) {
		 HStack {
			Text(entry.date.formatted(date: .abbreviated, time: .omitted))
			   .font(.system(size: dateFontSize))
			   .lineLimit(1)
			   .minimumScaleFactor(0.75)
			Spacer()
			HStack(spacing: 8) {
			   if entry.wentToGym {
				  Image(systemName: "figure.strengthtraining.traditional")
					 .foregroundColor(.blue)
					 .font(.system(size: metricIconSize))
			   }
			   if entry.walkedAM || entry.walkedPM {
				  Image(systemName: "figure.walk")
					 .foregroundColor(.green)
					 .font(.system(size: metricIconSize))
			   }
			}
		 }
		 
		 HStack(spacing: 12) {
			if let glucose = entry.glucose {
			   HStack(spacing: 4) {
				  Image(systemName: "drop.fill")
					 .foregroundColor(.red)
					 .font(.system(size: metricIconSize))
				  Text("\(numberFormatter.string(from: NSNumber(value: glucose)) ?? "0") mg/dL")
					 .font(.system(size: metricFontSize))
					 .lineLimit(1)
					 .minimumScaleFactor(0.5)
					 .foregroundColor(.red)
			   }
			   .frame(maxWidth: .infinity)
			}
			
			if let ketones = entry.ketones {
			   HStack(spacing: 4) {
				  Image(systemName: "flame.fill")
					 .foregroundColor(.purple)
					 .font(.system(size: metricIconSize))
				  Text("\(numberFormatter.string(from: NSNumber(value: ketones)) ?? "0") mmol")
					 .font(.system(size: metricFontSize))
					 .lineLimit(1)
					 .minimumScaleFactor(0.5)
					 .foregroundColor(.purple)
			   }
			   .frame(maxWidth: .infinity)
			}
			
			if let bp = entry.bloodPressure {
			   HStack(spacing: 4) {
				  Image(systemName: "heart.fill")
					 .foregroundColor(.orange)
					 .font(.system(size: metricIconSize))
				  Text(bp)
					 .font(.system(size: metricFontSize))
					 .lineLimit(1)
					 .minimumScaleFactor(0.5)
					 .foregroundColor(.orange)
			   }
			   .frame(maxWidth: .infinity)
			}
		 }
		 
		 HStack(spacing: 12) {
			if let steps = entry.steps {
			   HStack(spacing: 4) {
				  Image(systemName: "figure.walk")
					 .foregroundColor(.green)
					 .font(.system(size: metricIconSize))
				  Text("\(numberFormatter.string(from: NSNumber(value: steps)) ?? "0") steps")
					 .font(.system(size: metricFontSize))
					 .lineLimit(1)
					 .minimumScaleFactor(0.5)
					 .foregroundColor(.green)
			   }
			   .frame(maxWidth: .infinity)
			}
			
			if let weight = entry.weight {
			   WeightMetricView(
				  weight: weight,
				  entry: entry,
				  modelContext: modelContext,
				  formatter: numberFormatter,
				  metricFontSize: metricFontSize,
				  smallMetricFontSize: smallMetricFontSize,
				  metricIconSize: metricIconSize
			   )
			   .frame(maxWidth: .infinity)
			}
			
			if let sleepTime = entry.sleepTime {
			   HStack(spacing: 4) {
				  Image(systemName: "moon.zzz.fill")
					 .foregroundColor(.indigo)
					 .font(.system(size: metricIconSize))
				  Text(sleepTime)
					 .font(.system(size: metricFontSize))
					 .lineLimit(1)
					 .minimumScaleFactor(0.5)
					 .foregroundColor(.indigo)
			   }
			   .frame(maxWidth: .infinity)
			}
		 }
	  }
	  .padding(.vertical, 8)
   }
}

// MARK: - Weight Metric View
private struct WeightMetricView: View {
   let weight: Double
   let entry: DailyHealthEntry
   let modelContext: ModelContext
   let formatter: NumberFormatter
   let metricFontSize: CGFloat
   let smallMetricFontSize: CGFloat
   let metricIconSize: CGFloat
   
   var lastEntry: DailyHealthEntry? {
	  let descriptor = FetchDescriptor<DailyHealthEntry>(
		 sortBy: [SortDescriptor(\DailyHealthEntry.date, order: .reverse)]
	  )
	  let entries = try? modelContext.fetch(descriptor)
	  return entries?.first { $0.date < entry.date }
   }
   
   var weightDiffFromLast: (diff: Double, isUp: Bool)? {
	  guard let lastWeight = lastEntry?.weight else { return nil }
	  let diff = weight - lastWeight
	  return (abs(diff), diff > 0)
   }
   
   var body: some View {
	  VStack(alignment: .leading, spacing: 2) {
		 HStack(spacing: 4) {
			Image(systemName: "scalemass.fill")
			   .foregroundColor(.blue)
			   .font(.system(size: metricIconSize))
			Text("\(formatter.string(from: NSNumber(value: weight)) ?? "0") lbs")
			   .font(.system(size: metricFontSize))
			   .lineLimit(1)
			   .minimumScaleFactor(0.5)
			   .foregroundColor(.blue)
		 }
		 
		 if let (diff, isUp) = weightDiffFromLast {
			HStack(spacing: 2) {
			   Text("Last:")
				  .foregroundStyle(.gray)
				  .font(.system(size: smallMetricFontSize))
			   Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
				  .foregroundStyle(isUp ? .red : .green)
				  .font(.system(size: smallMetricFontSize))
			   Text("\(formatter.string(from: NSNumber(value: diff)) ?? "0")")
				  .foregroundStyle(isUp ? .red : .green)
				  .font(.system(size: smallMetricFontSize))
			}
		 }
	  }
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
