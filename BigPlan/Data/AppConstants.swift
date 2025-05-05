import SwiftUI

struct AppConstants {
   static let appName = "BigPlan"

   static func getVersion() -> String {
	  return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
   }

   // Add a reusable version footer view
   struct VersionFooter: View {
	  var body: some View {
		 Text("Version: \(AppConstants.getVersion())")
			.font(.footnote)
			.foregroundColor(.secondary)
			.frame(maxWidth: .infinity)
			.padding(.bottom, 8)
	  }
   }
}
