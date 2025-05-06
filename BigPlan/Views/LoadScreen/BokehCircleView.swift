

import SwiftUI

struct BokehCircleView: View {
   @State private var animate = false
   let color: Color
   let size: CGFloat
   let blur: CGFloat
   let xOffset: CGFloat
   let yOffset: CGFloat
   let animationSpeed: Double

   var body: some View {
	  Circle()
		 .fill(color)
		 .frame(width: size, height: size)
		 .blur(radius: blur)
		 .offset(x: animate ? xOffset : -xOffset, y: animate ? yOffset : -yOffset)
		 .opacity(0.65)
		 .onAppear {
			withAnimation(Animation.easeInOut(duration: animationSpeed).repeatForever(autoreverses: true)) {
			   animate.toggle()
			}
		 }
   }
}
