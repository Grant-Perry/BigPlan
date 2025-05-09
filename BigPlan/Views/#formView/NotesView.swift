import SwiftUI

struct NotesView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @State private var isInitialWeatherLoaded = false
   @FocusState private var isNotesFocused: Bool
   @State private var isWeatherFocused: Bool = false

   private var isToday: Bool {
	  Calendar.current.isDateInToday(bigPlanViewModel.date)
   }

   var body: some View {
	  VStack(alignment: .leading, spacing: 18) {
		 // Notes Section
		 VStack(alignment: .leading, spacing: 12) {
			Text("NOTES")
			   .font(.system(size: 20, weight: .semibold))
			   .foregroundColor(.white.opacity(0.9))
			   .textCase(.uppercase)

			TextEditor(text: Binding(
			   get: { bigPlanViewModel.notes ?? "" },
			   set: {
				  bigPlanViewModel.notes = $0.isEmpty ? nil : $0
				  isNotesFocused = true // Keep focus when typing
			   }
			))
			.focused($isNotesFocused)
			.frame(minHeight: 250)
			.font(.system(size: 19))
			.padding(14)
			.background(Color.black.opacity(0.3))
			.cornerRadius(10)
			.overlay(
			   RoundedRectangle(cornerRadius: 10)
				  .stroke(isNotesFocused ? Color.blue.opacity(0.5) : Color.white.opacity(0.05),
						  lineWidth: isNotesFocused ? 2 : 0.5)
			)
			.shadow(color: isNotesFocused ? Color.blue.opacity(0.3) : .clear, radius: 8)
			.overlay(
			   Group {
				  if (bigPlanViewModel.notes ?? "").isEmpty {
					 Text("Enter any additional notes here...")
						.foregroundColor(isNotesFocused ? .gpGreen : .gray.opacity(0.3))
						.font(.system(size: 19))
						.padding(.top, 22)
						.padding(.leading, 20)
				  }
			   },
			   alignment: .topLeading
			)
			.contentShape(Rectangle())
			.onTapGesture {
			   isNotesFocused = true
			   isWeatherFocused = false
			}
		 }
		 .formSectionStyle()

		 // Weather Section
		 if let weatherData = bigPlanViewModel.weatherData {
			VStack(alignment: .leading, spacing: 12) {
			   HStack {
				  Text("WEATHER")
					 .font(.system(size: 20, weight: .semibold))
					 .foregroundColor(.white.opacity(0.9))
					 .textCase(.uppercase)

				  Spacer()

				  if !bigPlanViewModel.isEditing || isToday {
					 Button {
						Task {
						   await bigPlanViewModel.fetchAndAppendWeather()
						}
					 } label: {
						Image(systemName: "arrow.clockwise")
						   .foregroundColor(.accentColor)
						   .font(.system(size: 19))
					 }
					 .disabled(bigPlanViewModel.isLoadingWeather)
				  }
			   }

			   let lines = weatherData.components(separatedBy: "\n")
			   VStack(alignment: .leading, spacing: 8) {
				  if lines.count >= 1 {
					 Text(lines[0])  // City, State
						.font(.system(size: 19))
						.foregroundColor(isWeatherFocused ? .gpGreen : .white)
				  }
				  ForEach(1..<lines.count, id: \.self) { index in
					 Text(lines[index])
						.font(.system(size: 19))
						.foregroundColor(.gray)
				  }
			   }
			   .padding(14)
			   .frame(maxWidth: .infinity, alignment: .leading)
			   .background(Color.black.opacity(0.3))
			   .cornerRadius(10)
			   .overlay(
				  RoundedRectangle(cornerRadius: 10)
					 .stroke(isWeatherFocused ? Color.blue.opacity(0.5) : Color.white.opacity(0.05),
							 lineWidth: isWeatherFocused ? 2 : 0.5)
			   )
			   .shadow(color: isWeatherFocused ? Color.blue.opacity(0.3) : .clear, radius: 8)
			   .contentShape(Rectangle())
			   .onTapGesture {
				  isWeatherFocused = true
				  isNotesFocused = false
			   }
			}
			.formSectionStyle()
		 }

		 // Version at bottom
		 Text("Version: \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown")")
			.font(.system(size: 17))
			.foregroundColor(.gray)
			.frame(maxWidth: .infinity, alignment: .center)
			.padding(.top, 8)
	  }
	  .task {
		 if !isInitialWeatherLoaded && (!bigPlanViewModel.isEditing || isToday) {
			isInitialWeatherLoaded = true
			await bigPlanViewModel.fetchAndAppendWeather()
		 }
	  }
	  .animation(.none, value: isNotesFocused)
	  .animation(.none, value: isWeatherFocused)
   }
}
