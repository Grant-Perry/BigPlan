import SwiftUI
import UniformTypeIdentifiers
import OSLog

private let logger = Logger(subsystem: "BigPlan", category: "ImportView")

struct ImportView: View {
   @Environment(\.dismiss) var dismiss
   @State private var isFilePickerPresented = false
   @State private var importStatus: String?
   @State private var isImporting = false
   @State private var isAuthorized = false
   @State private var importedReadings: [(date: Date, value: Double)] = []
   
   var body: some View {
	  NavigationStack {
		 VStack(spacing: 20) {
			if isImporting {
			   ProgressView("Importing data...")
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
						Text("Imported Readings:")
						   .font(.headline)
						   .padding(.top)
						
						ForEach(importedReadings, id: \.date) { reading in
						   HStack {
							  Text(reading.date, formatter: dateFormatter)
							  Spacer()
							  Text(String(format: "%.1f", reading.value))
								 .foregroundColor(.gpGreen)
						   }
						   .font(.system(.body, design: .monospaced))
						}
					 }
					 .padding()
					 .background(Color.black.opacity(0.2))
					 .cornerRadius(10)
				  }
			   }
			   
			   Spacer()
			   
			   Button("Done") {
				  dismiss()
			   }
			   .font(.headline)
			   .foregroundColor(.white)
			   .padding()
			   .frame(width: 120)
			   .background(Color.green.gradient)
			   .cornerRadius(10)
			   .padding(.bottom, 20)
			}
		 }
		 .padding()
		 .navigationTitle("Import Data")
		 .navigationBarTitleDisplayMode(.inline)
		 .toolbar {
			ToolbarItem(placement: .navigationBarLeading) {
			   Button("Cancel") {
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
	  }
	  .interactiveDismissDisabled()
   }
   
   private let dateFormatter: DateFormatter = {
	  let formatter = DateFormatter()
	  formatter.dateFormat = "MMM d, yyyy"
	  return formatter
   }()
   
   private func checkAuthorization() {
	  Task {
		 isAuthorized = await HealthKitManager.shared.requestAuthorization()
	  }
   }
   
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
   
   private func handleFileImport(_ result: Result<[URL], Error>) async {
	  isImporting = true
	  defer { isImporting = false }
	  
	  guard isAuthorized else {
		 importStatus = "Health access is required to import data"
		 return
	  }
	  
	  do {
		 let urls = try result.get()
		 guard let url = urls.first else {
			importStatus = "Error: No file selected"
			return
		 }
		 
		 logger.debug("Selected file: \(url.lastPathComponent)")
		 
		 // Start accessing the file
		 guard url.startAccessingSecurityScopedResource() else {
			importStatus = "Error: Cannot access file"
			return
		 }
		 defer { url.stopAccessingSecurityScopedResource() }
		 
		 // Read file data using async API
		 let data = try Data(contentsOf: url)
		 guard let contents = String(data: data, encoding: .utf8) else {
			importStatus = "Error: Could not read file contents"
			return
		 }
		 
		 let rows = contents.components(separatedBy: .newlines)
		 
		 // Debug first few rows
		 for (index, row) in rows.prefix(3).enumerated() {
			logger.debug("Row \(index): \(row)")
		 }
		 
		 var imported = 0
		 importedReadings = []  // Clear previous readings
		 for row in rows.dropFirst(2) { // Skip version and header rows
										// Skip empty rows or comment rows
			if row.isEmpty || row.hasPrefix("#") { continue }
			
			let columns = row.components(separatedBy: ";")
			   .map { $0.trimmingCharacters(in: .whitespaces) }
			   .map { $0.replacingOccurrences(of: "\"", with: "") }
			
			// Debug column count and content
			logger.debug("Found \(columns.count) columns in row")
			if columns.count >= 4 {
			   logger.debug("Column 1 (type): \(columns[1])")
			   logger.debug("Column 2 (sample): \(columns[2])")
			   logger.debug("Column 3 (value): \(columns[3])")
			}
			
			// Check for glucose readings only
			guard columns.count >= 4,
				  columns[1] == "glucose",  // reading_type
				  columns[2] == "blood",    // reading_sample_type
				  let glucoseStr = columns[3].isEmpty ? nil : columns[3], // reading_value
				  let glucose = Double(glucoseStr),
				  !columns[0].isEmpty  // reading_timestamp
			else { 
			   logger.debug("Skipping row - doesn't match criteria")
			   continue 
			}
			
			let dateStr = columns[0]
			
			// Parse the date which is in format: "2025-05-21T07:37:00.000-04:00"
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
			
			guard let date = dateFormatter.date(from: dateStr) else {
			   logger.error("Failed to parse date: \(dateStr)")
			   continue 
			}
			
			// Write to HealthKit with error handling
			do {
			   logger.debug("Attempting to save glucose \(glucose) for date \(date)")
			   try await HealthKitManager.shared.saveGlucose(glucose, date: date)
			   imported += 1
			   importedReadings.append((date: date, value: glucose))
			   logger.info("Successfully imported glucose: \(glucose) at \(date)")
			} catch let error as HealthKitManager.ImportError {
			   logger.error("HealthKit import error: \(error.localizedDescription)")
			   importStatus = error.localizedDescription
			   return
			} catch {
			   logger.error("Failed to save glucose: \(error.localizedDescription)")
			   continue
			}
		 }
		 
		 importStatus = "Successfully imported \(imported) glucose readings"
		 logger.info("Import completed: \(imported) readings")
		 
	  } catch {
		 importStatus = "Error: \(error.localizedDescription)"
		 logger.error("Import failed: \(error.localizedDescription)")
	  }
   }
}
