import SwiftUI
import SwiftData

enum SettingsField {
   case initialWeight, weightTarget
}

struct SettingsView: View {
   let modelContext: ModelContext
   @Environment(\.dismiss) private var dismiss
   @StateObject private var viewModel: SettingsViewModel
   @FocusState private var focusedField: SettingsField?

   init(modelContext: ModelContext) {
          self.modelContext = modelContext
          _viewModel = StateObject(wrappedValue: SettingsViewModel(context: modelContext))
   }

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
                                  TextField("", value: $viewModel.initialWeight, format: .number.rounded())
					 .keyboardType(.decimalPad)
					 .multilineTextAlignment(.trailing)
					 .focused($focusedField, equals: .initialWeight)
					 .font(.system(size: 19))
                                         .placeholder(when: viewModel.initialWeight == 0) {
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
                                  TextField("", value: $viewModel.weightTarget, format: .number.rounded())
					 .keyboardType(.decimalPad)
					 .multilineTextAlignment(.trailing)
					 .focused($focusedField, equals: .weightTarget)
					 .font(.system(size: 19))
                                         .placeholder(when: viewModel.weightTarget == 0) {
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
                           viewModel.isSaving = true
                           viewModel.save()
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
                        .formFieldStyle(backgroundColor: Color.black.opacity(0.3), hasFocus: viewModel.isSaving)
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
                 viewModel.load()
          }
   }
}
