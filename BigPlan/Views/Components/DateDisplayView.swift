import SwiftUI

struct DateDisplayView: View {
   let date: Date
   @Binding var selectedDate: Date

   private func formattedDate(_ date: Date) -> (month: String, day: String, year: String) {
	  let monthFormatter = DateFormatter()
	  monthFormatter.dateFormat = "MMM"
	  let month = monthFormatter.string(from: date).uppercased()

	  let dayFormatter = DateFormatter()
	  dayFormatter.dateFormat = "dd"
	  let day = dayFormatter.string(from: date)

	  let yearFormatter = DateFormatter()
	  yearFormatter.dateFormat = "yyyy"
	  let year = yearFormatter.string(from: date)

	  return (month, day, year)
   }

   var body: some View {
	  let dateComponents = formattedDate(date)
	  VStack(alignment: .trailing, spacing: 0) {
		 Text(dateComponents.month)
			.font(.system(size: 52, weight: .heavy))
			.foregroundColor(.gpWhite)
			.kerning(-2)

		 Text(dateComponents.day)
			.font(.system(size: 48, weight: .bold))
			.foregroundColor(.gpRed)
			.kerning(-1)
			.offset(y: -15)

		 Text(dateComponents.year)
			.font(.system(size: 16, weight: .bold))
			.foregroundColor(.gpWhite)
			.opacity(0.4)
			.offset(y: -25)
	  }
	  .padding(.vertical, 8)
	  .padding(.horizontal, 12)
//	  .background(
//		 RoundedRectangle(cornerRadius: 18)
//			.fill(Color.white.opacity(0.4))
//	  )
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
