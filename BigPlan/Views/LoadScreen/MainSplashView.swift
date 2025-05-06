import SwiftUI

/// A floating blurred circle for background bokeh effect.


struct MainSplashView: View {

   @State private var bounce = false

   private var currentYear: Int {
	  Calendar.current.component(.year, from: Date())
   }

   var body: some View {
	  GeometryReader { geo in
		 ZStack {
			// Background gradient
			LinearGradient(
			   gradient: Gradient(colors: [.gpPink, .gpYellow, .gpGreen]),
			   startPoint: .topLeading,
			   endPoint: .bottomTrailing
			)
			.ignoresSafeArea()

			// Bokeh layers
			Group {
			   BokehCircleView(color: .white, size: 180, blur: 25, xOffset: 60, yOffset: -90, animationSpeed: 4)
			   BokehCircleView(color: .yellow, size: 140, blur: 30, xOffset: -80, yOffset: 70, animationSpeed: 5)
			   BokehCircleView(color: .green, size: 200, blur: 40, xOffset: 90, yOffset: 120, animationSpeed: 5)
			   BokehCircleView(color: .pink, size: 160, blur: 35, xOffset: -60, yOffset: -100, animationSpeed: 4)
			   BokehCircleView(color: .white, size: 100, blur: 20, xOffset: 100, yOffset: 150, animationSpeed: 6)
			   BokehCircleView(color: .yellow, size: 120, blur: 30, xOffset: -120, yOffset: -80, animationSpeed: 6)
			}

			// Content
			VStack {
			   Spacer()

			   // Title
			   Text("BigPlan")
				  .font(.custom("LondrinaShadow-Regular", size: 100))
				  .foregroundColor(.white)
				  .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 5)
				  .scaleEffect(bounce ? 1.0 : 0.5)
				  .onAppear {
					 withAnimation(.interpolatingSpring(stiffness: 120, damping: 10).delay(0.01)) {
						bounce = true
					 }
				  }

			   Spacer()

			   // Footer
			   VStack(spacing: 10) {
				  AppConstants.VersionFooter()
					 .font(.system(size: 14, weight: .medium, design: .rounded))
					 .shadow(color: Color.gpBlue.opacity(0.8), radius: 10, x: 0, y: 5)
					 .offset(y: 14)

				  Text("Gp. Delicious Studios - © \(String(currentYear))")
					 .font(.system(size: 12, weight: .medium, design: .rounded))
					 .foregroundColor(.gpWhite)
					 .shadow(color: .pink.opacity(0.8), radius: 10, x: 0, y: 5)
			   }
			   .padding(.bottom, 10)
			}
		 }
	  }
	  .frame(maxWidth: .infinity, maxHeight: .infinity)
	  .background(.black)
   }
}

/// #Preview
#Preview {
   MainSplashView()
}
