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
			   // Use the extracted computed property here
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
				  recentlyDeletedEntry: $recentlyDeletedEntry
			   )
			}
		 }

		 AppConstants.VersionFooter()
	  }
   }

   // ADD: Computed property for the List view
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
   let entry: DailyHealthEntry

   private let numberFormatter: NumberFormatter = {
	  let formatter = NumberFormatter()
	  formatter.numberStyle = .decimal
	  formatter.maximumFractionDigits = 1
	  return formatter
   }()

   var body: some View {
	  VStack(alignment: .leading, spacing: 8) {
		 // Date and Activity Icons
		 HStack {
			Text(entry.date.formatted(date: .abbreviated, time: .omitted))
			   .font(.title3)
			   .lineLimit(1)
			   .minimumScaleFactor(0.75)
			Spacer()
			HStack(spacing: 8) {
			   if entry.wentToGym {
				  Image(systemName: "figure.strengthtraining.traditional")
					 .foregroundColor(.blue)
					 .imageScale(.small)
			   }
			   if entry.walkedAM || entry.walkedPM {
				  Image(systemName: "figure.walk")
					 .foregroundColor(.green)
					 .imageScale(.small)
			   }
			}
		 }

		 // First Row of Metrics
		 HStack(spacing: 12) {
			if let glucose = entry.glucose {
			   HStack(spacing: 4) {
				  Image(systemName: "drop.fill")
					 .foregroundColor(.red)
					 .imageScale(.small)
				  Text("\(numberFormatter.string(from: NSNumber(value: glucose)) ?? "0") mg/dL")
					 .font(.title3)
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
					 .imageScale(.small)
				  Text("\(numberFormatter.string(from: NSNumber(value: ketones)) ?? "0") mmol")
					 .font(.title3)
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
					 .imageScale(.small)
				  Text(bp)
					 .font(.title3)
					 .lineLimit(1)
					 .minimumScaleFactor(0.5)
					 .foregroundColor(.orange)
			   }
			   .frame(maxWidth: .infinity)
			}
		 }

		 // Second Row of Metrics
		 HStack(spacing: 12) {
			if let steps = entry.steps {
			   HStack(spacing: 4) {
				  Image(systemName: "figure.walk")
					 .foregroundColor(.green)
					 .imageScale(.small)
				  Text("\(numberFormatter.string(from: NSNumber(value: steps)) ?? "0") steps")
					 .font(.title3)
					 .lineLimit(1)
					 .minimumScaleFactor(0.5)
					 .foregroundColor(.green)
			   }
			   .frame(maxWidth: .infinity)
			}

			if let weight = entry.weight {
			   HStack(spacing: 4) {
				  Image(systemName: "scalemass.fill")
					 .foregroundColor(.blue)
					 .imageScale(.small)
				  Text("\(numberFormatter.string(from: NSNumber(value: weight)) ?? "0") lbs")
					 .font(.title3)
					 .lineLimit(1)
					 .minimumScaleFactor(0.5)
					 .foregroundColor(.blue)
			   }
			   .frame(maxWidth: .infinity)
			}

			if let sleepTime = entry.sleepTime {
			   HStack(spacing: 4) {
				  Image(systemName: "moon.zzz.fill")
					 .foregroundColor(.indigo)
					 .imageScale(.small)
				  Text(sleepTime)
					 .font(.title3)
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
