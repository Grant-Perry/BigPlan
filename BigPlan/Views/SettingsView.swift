import SwiftUI
import SwiftData

enum SettingsField {
   case initialWeight, weightTarget
}

struct SettingsView: View {
   @Environment(\.dismiss) private var dismiss
   @Environment(\.modelContext) private var modelContext
   @Query private var settings: [Settings]
   @Query(sort: [SortDescriptor(\DailyHealthEntry.date)]) private var entries: [DailyHealthEntry]

   @State private var initialWeight: Double = 0.0
   @State private var weightTarget: Double = 100.0
   @FocusState private var focusedField: SettingsField?
   @State private var isSaving = false

   private let hintSize: CGFloat = 21

   var body: some View {
	  NavigationStack {
		 VStack(alignment: .leading, spacing: 18) {
			Text("SETTINGS")
			   .font(.system(size: 20, weight: .semibold))
			   .foregroundColor(.white.opacity(0.9))
			   .textCase(.uppercase)

			VStack(spacing: 18) {
			   // Initial Weight Field
			   HStack {
				  Text("Initial Weight")
					 .foregroundColor(focusedField == .initialWeight ? .gpGreen : .gray.opacity(0.8))
					 .font(.system(size: 19))
				  Spacer()
				  TextField("", value: $initialWeight, format: .number.rounded())
					 .keyboardType(.decimalPad)
					 .multilineTextAlignment(.trailing)
					 .focused($focusedField, equals: .initialWeight)
					 .font(.system(size: 19))
					 .placeholder(when: initialWeight == 0) {
						Text("lbs")
						   .foregroundColor(focusedField == .initialWeight ? .gpGreen : .gray.opacity(0.3))
						   .font(.system(size: hintSize))
					 }
			   }
			   .formFieldStyle(icon: "scalemass.fill", hasFocus: focusedField == .initialWeight)
			   .contentShape(Rectangle())
			   .onTapGesture {
				  focusedField = .initialWeight
			   }

			   // Weight Target Field
			   HStack {
				  Text("Weight Target")
					 .foregroundColor(focusedField == .weightTarget ? .gpGreen : .gray.opacity(0.8))
					 .font(.system(size: 19))
				  Spacer()
				  TextField("", value: $weightTarget, format: .number.rounded())
					 .keyboardType(.decimalPad)
					 .multilineTextAlignment(.trailing)
					 .focused($focusedField, equals: .weightTarget)
					 .font(.system(size: 19))
					 .placeholder(when: weightTarget == 0) {
						Text("lbs")
						   .foregroundColor(focusedField == .weightTarget ? .gpGreen : .gray.opacity(0.3))
						   .font(.system(size: hintSize))
					 }
			   }
			   .formFieldStyle(icon: "scalemass.fill", hasFocus: focusedField == .weightTarget)
			   .contentShape(Rectangle())
			   .onTapGesture {
				  focusedField = .weightTarget
			   }
			}

			Spacer()

			// Save Button
			Button {
			   isSaving = true
			   if let settings = settings.first {
				  settings.weightTarget = weightTarget
				  settings.initialWeight = initialWeight
				  try? modelContext.save()
			   }
			   DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
				  dismiss()
			   }
			} label: {
			   HStack {
				  Image(systemName: "checkmark.circle.fill")
					 .font(.system(size: 23, weight: .light))
				  Text("Save Settings")
					 .font(.system(size: 19))
			   }
			   .foregroundColor(.gpGreen)
			   .frame(maxWidth: .infinity)
			   .padding(.vertical, 18)
			}
			.formFieldStyle(backgroundColor: Color.black.opacity(0.3), hasFocus: isSaving)
		 }
		 .formSectionStyle()
		 .padding()
		 .toolbar {
			ToolbarItem(placement: .navigationBarLeading) {
			   Button("< Back") {
				  dismiss()
			   }
			}
		 }
	  }
	  .onAppear {
		 if let existingSettings = settings.first {
			weightTarget = existingSettings.weightTarget ?? 100.0

			// If initialWeight is nil, try to get it from first entry
			if existingSettings.initialWeight == nil,
			   let firstEntry = entries.first,
			   let firstWeight = firstEntry.weight {
			   initialWeight = firstWeight
			   existingSettings.initialWeight = firstWeight
			   try? modelContext.save()
			} else {
			   initialWeight = existingSettings.initialWeight ?? 0.0
			}
		 } else {
			let newSettings = Settings()
			modelContext.insert(newSettings)

			// Try to get initial weight from first entry
			if let firstEntry = entries.first,
			   let firstWeight = firstEntry.weight {
			   newSettings.initialWeight = firstWeight
			   initialWeight = firstWeight
			}

			try? modelContext.save()
			weightTarget = newSettings.weightTarget ?? 100.0
			initialWeight = newSettings.initialWeight ?? 0.0
		 }
	  }
   }
}
