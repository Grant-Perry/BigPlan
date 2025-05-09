import SwiftData
import Foundation

@Model
class Settings {
   var weightTarget: Double?
   var initialWeight: Double?

   init(weightTarget: Double? = 100.0, initialWeight: Double? = nil) {
	  self.weightTarget = weightTarget
	  self.initialWeight = initialWeight
   }
}
