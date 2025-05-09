
import SwiftUI

struct LoadingView: View {
   var body: some View {
	  VStack(spacing: 16) {
		 ProgressView()
			.scaleEffect(1.5)
		 Text("Loading...")
			.font(.system(size: 23))
			.foregroundColor(.gray)
	  }
	  .frame(maxWidth: .infinity, maxHeight: .infinity)
	  .background(Color.black.opacity(0.3))
   }
}
