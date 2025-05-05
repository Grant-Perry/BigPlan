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

   // Explicitly set the sort descriptor
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
				  modelContext.delete(entry)
				  recentlyDeletedEntry = entry
				  showUndoToast = true
			   }
			}
			Button("Cancel", role: .cancel) { }
		 }
		 .overlay(alignment: .bottom) {
			if showUndoToast {
			   UndoToastView(
				  showToast: $showUndoToast,
				  recentlyDeletedEntry: $recentlyDeletedEntry,
				  modelContext: modelContext
			   )
			}
		 }

		 AppConstants.VersionFooter()
	  }
   }

   private func verifyDataStore() {
	  do {
		 let descriptor = FetchDescriptor<DailyHealthEntry>()
		 let fetchedEntries = try modelContext.fetch(descriptor)
		 logger.info("📋 DailyListView verification - Found \(fetchedEntries.count) entries")

		 fetchedEntries.forEach { entry in
			logger.info("🔍 Entry found - ID: \(entry.id) Date: \(entry.date) Glucose: \(entry.glucose ?? 0)")
		 }

		 // Also log our @Query results
		 logger.info("🔄 @Query entries count: \(entries.count)")
	  } catch {
		 logger.error("❌ Failed to verify data store: \(error.localizedDescription)")
	  }
   }
}

// MARK: - Entry Row View
private struct EntryRowView: View {
   let entry: DailyHealthEntry

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
			   .font(.headline)
			   .lineLimit(1)
			   .minimumScaleFactor(0.75)
			Spacer()
			HStack(spacing: 8) {
			   if entry.wentToGym {
				  Image(systemName: "dumbbell.fill")
					 .foregroundColor(.blue)
			   }
			   if entry.walkedAM || entry.walkedPM {
				  Image(systemName: "figure.walk")
					 .foregroundColor(.green)
			   }
			}
		 }

		 HStack(spacing: 12) {
			Group {
			   if let glucose = entry.glucose {
				  MetricView(
					 value: numberFormatter.string(from: NSNumber(value: glucose)) ?? "0",
					 unit: "mg/dL",
					 icon: "drop.fill",
					 color: .red
				  )
			   }

			   if let ketones = entry.ketones {
				  MetricView(
					 value: numberFormatter.string(from: NSNumber(value: ketones)) ?? "0",
					 unit: "mmol",
					 icon: "chart.line.uptrend.xyaxis",
					 color: .purple
				  )
			   }

			   if let bp = entry.bloodPressure {
				  MetricView(
					 value: bp,
					 unit: "BP",
					 icon: "heart.fill",
					 color: .orange
				  )
			   }
			}
			.frame(maxWidth: .infinity)

			Group {
			   if let steps = entry.steps {
				  MetricView(
					 value: numberFormatter.string(from: NSNumber(value: steps)) ?? "0",
					 unit: "steps",
					 icon: "shoe.fill",
					 color: .green
				  )
			   }

			   if let weight = entry.weight {
				  MetricView(
					 value: numberFormatter.string(from: NSNumber(value: weight)) ?? "0",
					 unit: "lbs",
					 icon: "scalemass.fill",
					 color: .blue
				  )
			   }
			}
			.frame(maxWidth: .infinity)
		 }
		 .font(.subheadline)
	  }
	  .padding(.vertical, 8)
   }
}

// MARK: - Metric View
private struct MetricView: View {
   let value: String
   let unit: String
   let icon: String
   let color: Color

   var body: some View {
	  HStack(spacing: 4) {
		 Image(systemName: icon)
			.foregroundColor(color)
			.frame(width: 20)

		 VStack(alignment: .leading, spacing: 2) {
			Text(value)
			   .fontWeight(.medium)
			   .lineLimit(1)
			   .minimumScaleFactor(0.5)
			Text(unit)
			   .font(.caption2)
			   .foregroundColor(.secondary)
			   .lineLimit(1)
			   .minimumScaleFactor(0.5)
		 }
		 .frame(minWidth: 50)
	  }
	  .frame(maxWidth: .infinity, alignment: .leading)
   }
}

// MARK: - Undo Toast View
private struct UndoToastView: View {
   @Binding var showToast: Bool
   @Binding var recentlyDeletedEntry: DailyHealthEntry?
   let modelContext: ModelContext

   var body: some View {
	  VStack {
		 Spacer()
		 HStack {
			Text("Entry deleted")
			   .foregroundColor(.white)
			Spacer()
			Button("Undo") {
			   if let entry = recentlyDeletedEntry {
				  modelContext.insert(entry)
				  recentlyDeletedEntry = nil
			   }
			   showToast = false
			}
			.foregroundColor(.white)
			.fontWeight(.medium)
		 }
		 .padding()
		 .background(Color.black.opacity(0.8))
		 .cornerRadius(12)
		 .padding()
	  }
	  .transition(.move(edge: .bottom).combined(with: .opacity))
	  .animation(.easeInOut, value: showToast)
   }
}

//#Preview {
//   let container = try! ModelContainer(for: DailyHealthEntry.self)
//   let context = ModelContext(container)
//
//   // Add some sample data
//   let entry1 = DailyHealthEntry(
//	  glucose: 120,
//	  ketones: 1.5,
//	  bloodPressure: "120/80",
//	  steps: 10000,
//	  wentToGym: true,
//	  walkedAM: true
//   )
//   context.insert(entry1)
//
//   return DailyListView(selectedTab: .constant(0))
//	  .modelContainer(container)
//}
