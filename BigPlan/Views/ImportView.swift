import SwiftUI
import UniformTypeIdentifiers
import OSLog
import SwiftData

private let logger = Logger(subsystem: "BigPlan", category: "ImportView")

struct ImportView: View {
   @Environment(\.dismiss) var dismiss
   @Environment(\.modelContext) var modelContext
   @Binding var selectedTab: Int
   @State private var isFilePickerPresented = false
   @State private var importStatus: String?
   @State private var isImporting = false
   @State private var isAuthorized = false
   @State private var importedReadings: [(date: Date, glucose: Double?, ketones: Double?)] = []
   @State private var isDoneEnabled = false
   @State private var importProgress = 0
   @State private var showUpdateOptions = false
   
   var body: some View {
	  VStack(spacing: 20) {
		 if isImporting {
			ProgressView("Processing Data...")
		 } else {
			Button(action: {
			   requestAuthorization()
			}) {
			   Label("Import CSV File", systemImage: "doc.badge.plus")
				  .font(.headline)
				  .padding()
				  .background(Color.gpGreen.opacity(0.2))
				  .cornerRadius(10)
			}
			
			if let status = importStatus {
			   Text(status)
				  .foregroundColor(status.contains("Error") ? .red : .green)
				  .font(.subheadline)
			}
			
			if !importedReadings.isEmpty {
			   ScrollView {
				  VStack(alignment: .leading, spacing: 12) {
					 Text("Found \(importedReadings.count) Readings:")
						.font(.headline)
						.padding(.top)
					 
					 ForEach(importedReadings, id: \.date) { reading in
						HStack {
						   Text(reading.date, formatter: dateFormatter)
						   Spacer()
						   if let glucose = reading.glucose {
							  Text(String(format: "%.1f mg/dL", glucose))
								 .foregroundColor(.gpGreen)
						   }
						   if let ketones = reading.ketones {
							  Text(String(format: "%.1f mmol", ketones))
								 .foregroundColor(.orange)
						   }
						}
						.font(.system(.body, design: .monospaced))
					 }
					 
					 if importProgress > 0 {
						Text("Saving: \(importProgress)/\(importedReadings.count)")
						   .font(.subheadline)
						   .foregroundColor(.gray)
						   .padding(.top)
					 }
				  }
				  .padding()
				  .background(Color.black.opacity(0.2))
				  .cornerRadius(10)
			   }
			   
			   // Update options
			   if isDoneEnabled {
				  VStack(spacing: 10) {
					 Button(action: {
						Task {
						   await updateAllRecords(glucoseOnly: true)
						}
					 }) {
						Label("Update All Glucose", systemImage: "drop.fill")
						   .foregroundColor(.gpGreen)
						   .padding()
						   .frame(maxWidth: .infinity)
						   .background(Color.gpGreen.opacity(0.1))
						   .cornerRadius(10)
					 }
					 
					 Button(action: {
						Task {
						   await updateAllRecords(ketonesOnly: true)
						}
					 }) {
						Label("Update All Ketones", systemImage: "flame.fill")
						   .foregroundColor(.orange)
						   .padding()
						   .frame(maxWidth: .infinity)
						   .background(Color.orange.opacity(0.1))
						   .cornerRadius(10)
					 }
				  }
				  .padding(.horizontal)
			   }
			}
			
			Spacer()
			
			Button(isDoneEnabled ? "Done" : "Importing...") {
			   selectedTab = 0
			}
			.font(.headline)
			.foregroundColor(.white)
			.padding()
			.frame(width: 140)
			.background(isDoneEnabled ? Color.green.gradient : Color.gray.gradient)
			.cornerRadius(10)
			.padding(.bottom, 20)
			.disabled(!isDoneEnabled)
		 }
	  }
	  .padding()
	  .navigationTitle("Import Data")
	  .navigationBarTitleDisplayMode(.inline)
	  .navigationBarBackButtonHidden()
	  .toolbar {
		 ToolbarItem(placement: .navigationBarLeading) {
			Button("Done") {
			   dismiss()
			}
		 }
	  }
	  .fileImporter(
		 isPresented: $isFilePickerPresented,
		 allowedContentTypes: [.commaSeparatedText],
		 allowsMultipleSelection: false
	  ) { result in
		 Task {
			await handleFileImport(result)
		 }
	  }
	  .interactiveDismissDisabled()
   }
   
   private func handleFileImport(_ result: Result<[URL], Error>) async {
	  isImporting = true
	  importedReadings = []
	  isDoneEnabled = false
	  importProgress = 0
	  
	  defer { isImporting = false }
	  
	  do {
		 let urls = try result.get()
		 guard let url = urls.first else {
			importStatus = "Error: No file selected"
			return
		 }
		 
		 guard url.startAccessingSecurityScopedResource() else {
			importStatus = "Error: Cannot access file"
			return
		 }
		 defer { url.stopAccessingSecurityScopedResource() }
		 
		 let data = try Data(contentsOf: url)
		 guard let contents = String(data: data, encoding: .utf8) else {
			importStatus = "Error: Could not read file contents"
			return
		 }
		 
		 var readings: [(Date, Double?, Double?)] = []
		 let rows = contents.components(separatedBy: .newlines)
		 
		 logger.debug("CSV Headers: \(rows[0])")
		 if rows.count > 1 {
			logger.debug("First data row: \(rows[1])")
		 }
		 
		 for row in rows.dropFirst(2) {
			if row.isEmpty || row.hasPrefix("#") { continue }
			
			let columns = row.components(separatedBy: ";")
			   .map { $0.trimmingCharacters(in: .whitespaces) }
			   .map { $0.replacingOccurrences(of: "\"", with: "") }
			
			if columns.count >= 4 {
			   logger.debug("Processing row - type: \(columns[1]), sample: \(columns[2]), value: \(columns[3])")
			}
			
			guard columns.count >= 4,
				  !columns[0].isEmpty else { continue }
			
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
			
			guard let date = dateFormatter.date(from: columns[0]) else { continue }
			
			var glucose: Double? = nil
			var ketones: Double? = nil
			
			// Check for glucose
			if columns[1] == "glucose" && columns[2] == "blood",
			   let glucoseStr = columns[3].isEmpty ? nil : columns[3],
			   let glucoseVal = Double(glucoseStr) {
			   glucose = glucoseVal
			   logger.debug("Found glucose: \(glucoseVal)")
			}
			
			// Check for ketones
			if columns[1] == "ketone" && columns[2] == "blood",
			   let ketonesStr = columns[3].isEmpty ? nil : columns[3],
			   let ketonesVal = Double(ketonesStr) {
			   ketones = ketonesVal
			   logger.debug("Found ketone: \(ketonesVal)")
			}
			
			if glucose != nil || ketones != nil {
			   readings.append((date, glucose, ketones))
			}
		 }
		 
		 importedReadings = readings.map { (date: $0.0, glucose: $0.1, ketones: $0.2) }
		 importStatus = "Found \(readings.count) readings. Starting import..."
		 
		 for (index, reading) in readings.enumerated() {
			do {
			   if let glucose = reading.1 {
				  try await HealthKitManager.shared.saveGlucose(glucose, date: reading.0)
			   }
			   importProgress = index + 1
			} catch {
			   importStatus = "Error on reading \(index + 1): \(error.localizedDescription)"
			   return
			}
		 }
		 
		 importStatus = "Successfully imported \(readings.count) readings"
		 isDoneEnabled = true
		 
	  } catch {
		 importStatus = "Error: \(error.localizedDescription)"
	  }
   }
   
   private func updateAllRecords(glucoseOnly: Bool = false, ketonesOnly: Bool = false) async {
	  importStatus = "Updating existing records..."
	  isImporting = true
	  importProgress = 0
	  
	  do {
		 let descriptor = FetchDescriptor<DailyHealthEntry>()
		 let entries = try modelContext.fetch(descriptor)
		 
		 for (index, entry) in entries.enumerated() {
			if let match = importedReadings.first(where: { Calendar.current.isDate($0.date, inSameDayAs: entry.date) }) {
			   if glucoseOnly, let glucose = match.glucose {
				  entry.glucose = glucose
				  try await HealthKitManager.shared.saveGlucose(glucose, date: entry.date)
				  importStatus = "Updated glucose for \(index + 1) of \(entries.count) entries"
			   }
			   if ketonesOnly, let ketones = match.ketones {
				  entry.ketones = ketones
				  importStatus = "Updated ketones for \(index + 1) of \(entries.count) entries"
			   }
			}
			importProgress = index + 1
		 }
		 
		 try modelContext.save()
		 importStatus = "Successfully updated existing records"
	  } catch {
		 importStatus = "Error updating records: \(error.localizedDescription)"
	  }
	  
	  isImporting = false
   }
   
   private let dateFormatter: DateFormatter = {
	  let formatter = DateFormatter()
	  formatter.dateFormat = "MMM d, yyyy"
	  return formatter
   }()
   
   private func requestAuthorization() {
	  Task {
		 isImporting = true
		 isAuthorized = await HealthKitManager.shared.requestAuthorization()
		 if isAuthorized {
			isFilePickerPresented = true
		 } else {
			importStatus = "Health access is required to import data"
		 }
		 isImporting = false
	  }
   }
}
