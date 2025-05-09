import SwiftUI
import SwiftData

struct AppSettingsView: View {
   @Environment(\.modelContext) private var modelContext
   @Query private var settings: [Settings]
   @State private var weightTarget: Double

   init() {
	  // Start with default value if no settings exist
	  _weightTarget = State(initialValue: 100.0)
   }

   var body: some View {
	  NavigationStack {
		 VStack(alignment: .leading, spacing: 18) {
			Text("SETTINGS")
			   .font(.system(size: 20, weight: .semibold))
			   .foregroundColor(.white.opacity(0.9))
			   .textCase(.uppercase)

			// Weight Target Field
			HStack {
			   Text("Weight Target")
				  .foregroundColor(.gray.opacity(0.8))
				  .font(.system(size: 19))
			   Spacer()
			   TextField("", value: $weightTarget, format: .number.rounded())
				  .keyboardType(.decimalPad)
				  .multilineTextAlignment(.trailing)
				  .font(.system(size: 19))
			}
			.formFieldStyle(icon: "scalemass.fill", hasFocus: false)

			Spacer()
			AppConstants.VersionFooter()
		 }
		 .formSectionStyle()
		 .navigationTitle("Settings")
		 .onAppear {
			if let existingSettings = settings.first {
			   // Use the stored value or default to 100.0
			   weightTarget = existingSettings.weightTarget ?? 100.0
			} else {
			   let newSettings = Settings(weightTarget: 100.0)
			   modelContext.insert(newSettings)
			   try? modelContext.save()
			}
		 }
		 .onChange(of: weightTarget) {
			if let existingSettings = settings.first {
			   existingSettings.weightTarget = weightTarget
			   try? modelContext.save()
			}
		 }
	  }
   }
}
