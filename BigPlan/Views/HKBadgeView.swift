import SwiftUI

struct HKBadgeView: View {
   var show: Bool
   var hasValue: Bool

   var body: some View {
	  if show && hasValue {
		 Image(systemName: "applelogo")
			.resizable()
			.frame(width: 10, height: 10)
			.foregroundColor(.gpGreen)
			.offset(x: -3, y: -5)
			.padding(.leading, 2)
	  }
   }
}
