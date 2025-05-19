import SwiftUI
import SwiftData

struct EntryListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        sort: [SortDescriptor(\DailyHealthEntry.date, order: .reverse)]
    ) private var entries: [DailyHealthEntry]
    @Binding var selectedEntry: DailyHealthEntry?
    @Binding var showDeleteConfirmation: Bool
    @Binding var entryToDelete: DailyHealthEntry?

    var body: some View {
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