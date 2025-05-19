import SwiftUI

struct HKBadgeView: View {
   let show: Bool
   let hasValue: Bool
   
   var body: some View {
	  if show {
		 Image(systemName: "heart.fill")
			.foregroundStyle(hasValue ? .green : .gray.opacity(0.3))
			.font(.system(size: 15))
	  }
   }
}
