import SwiftUI

struct AppConstants {
   static let appName = "BigPlan"

   static func getVersion() -> String {
	  return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
   }
}
