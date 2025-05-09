import SwiftUI

struct FormFieldStyle: ViewModifier {
   let icon: String?
   let backgroundColor: Color
   let hasFocus: Bool

   init(icon: String? = nil,
		backgroundColor: Color = Color.black.opacity(0.3),
		hasFocus: Bool = false) {
	  self.icon = icon
	  self.backgroundColor = backgroundColor
	  self.hasFocus = hasFocus
   }

   func body(content: Content) -> some View {
	  HStack(spacing: 20) {
		 if let icon = icon {
			Image(systemName: icon)
			   .foregroundColor(hasFocus ? .gpGreen : .gray.opacity(0.7))
			   .frame(width: 30)
			   .font(.system(size: 23, weight: .light))
		 }
		 content
			.foregroundColor(.white)
			.font(.system(size: 23))
	  }
	  .padding(.vertical, 18)
	  .padding(.horizontal, 20)
	  .background(backgroundColor)
	  .cornerRadius(14)
	  .overlay(
		 RoundedRectangle(cornerRadius: 14)
			.stroke(hasFocus ? Color.blue.opacity(0.5) : Color.white.opacity(0.05), lineWidth: hasFocus ? 2 : 0.5)
	  )
	  .shadow(color: hasFocus ? Color.blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 0)
	  .animation(.easeInOut(duration: 0.2), value: hasFocus)
   }
}

struct FormSectionStyle: ViewModifier {
   func body(content: Content) -> some View {
	  VStack(alignment: .leading, spacing: 18) {
		 content
	  }
	  .padding(20)
	  .background(Color(UIColor.systemGray5).opacity(0.7))
	  .cornerRadius(16)
   }
}

extension View {
   func formFieldStyle(icon: String? = nil,
					   backgroundColor: Color = Color.black.opacity(0.3),
					   hasFocus: Bool = false) -> some View {
	  modifier(FormFieldStyle(icon: icon,
							  backgroundColor: backgroundColor,
							  hasFocus: hasFocus))
   }

   func formSectionStyle() -> some View {
	  modifier(FormSectionStyle())
   }
}
