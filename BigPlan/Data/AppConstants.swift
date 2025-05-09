import SwiftUI

struct AppConstants {
   static let appName = "BigPlan"
   static let hintSize: CGFloat = 21 

   static func getVersion() -> String {
	  return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
   }

   // Add a reusable version footer view
   struct VersionFooter: View {
	  var foreGround: Color = .secondary
	  var fontSize: Font = .footnote
	  var bottomPadding: CGFloat = 8.0

	  var body: some View {
		 Text("Version: \(AppConstants.getVersion())")
			.font(fontSize)
			.foregroundColor(foreGround)
			.padding(.bottom, bottomPadding)
	  }
   }
}
