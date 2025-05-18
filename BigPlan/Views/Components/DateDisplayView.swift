import SwiftUI

struct DateDisplayView: View {
   var date: Date
   @Binding var selectedDate: Date

   var body: some View {
	  HStack(alignment: .top, spacing: 0) {
		 // MARK: Weekday 3 letter rotated
		 Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
			.font(.system(size: 18, weight: .medium))
			.foregroundColor(.gpGreen.opacity(0.5))
			.rotationEffect(.degrees(-90))
			.fixedSize()
			.frame(height: 55)
			.padding(.trailing, 3)
			.offset(x: 8, y: 0)

		 //MARK: Month
		 VStack(alignment: .trailing, spacing: -3) {
			Text(date.formatted(.dateTime.month(.wide)).uppercased())
			   .font(.system(size: 63, weight: .bold))
			   .foregroundColor(.white)
			   .lineLimit(1)

			//MARK: Day Number
			Text(date.formatted(.dateTime.day()))
			   .font(.system(size: 70, weight: .bold))
			   .foregroundColor(.gpRed)
			   .minimumScaleFactor(0.7)
			   .offset(y: -25)

			//MARK: Year
			Text(date.formatted(.dateTime.year()))
			   .font(.system(size: 19, weight: .medium))
			   .foregroundColor(.gray)
			   .offset(x: -8, y: -36)

		 }
	  }
	  .frame(maxWidth: .infinity, alignment: .trailing)
	  .padding(.trailing, 8)
	  .padding(.bottom, 14)
	  .overlay {
		 DatePicker(
			"Entry Date",
			selection: $selectedDate,
			displayedComponents: .date
		 )
		 .labelsHidden()
		 .opacity(0)
	  }
   }
}
