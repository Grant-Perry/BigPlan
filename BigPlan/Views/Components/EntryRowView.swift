import SwiftUI
import SwiftData

struct EntryRowView: View {
   @Environment(\.modelContext) private var modelContext
   let entry: DailyHealthEntry
   
   private let metricFontSize: CGFloat = 19
   private let smallMetricFontSize: CGFloat = 14
   private let headerIconSize: CGFloat = 14
   private let metricIconSize: CGFloat = 17
   private let daySize: CGFloat = 17
   private let dateFontSize: CGFloat = 23
   
   private let numberFormatter: NumberFormatter = {
	  let formatter = NumberFormatter()
	  formatter.numberStyle = .decimal
	  formatter.maximumFractionDigits = 1
	  return formatter
   }()
   
   var body: some View {
	  VStack(alignment: .leading, spacing: 8) {
		 HStack {
			VStack(alignment: .leading, spacing: 1) {
			   // MARK: Day of the week
			   Text(entry.date.formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "en_US_POSIX"))).uppercased())
				  .font(.system(size: daySize))
				  .foregroundColor(.gpRed)
				  .tracking(2.5)
			   // MARK: Actual date
			   Text(entry.date.formatted(date: .abbreviated, time: .omitted))
				  .font(.system(size: dateFontSize))
				  .lineLimit(1)
				  .minimumScaleFactor(0.75)
			}
			Spacer()
			HStack(spacing: 6) {
			   if entry.glucose != nil {
				  Image(systemName: "drop.fill")
					 .foregroundColor(entry.hkUpdatedGlucose ? .red : .red.opacity(0.6))
					 .font(.system(size: headerIconSize))
					 .animation(.easeInOut, value: entry.hkUpdatedGlucose)
			   }
			   if entry.ketones != nil {
				  Image(systemName: "flame.fill")
					 .foregroundColor(entry.hkUpdatedKetones ? .purple : .purple.opacity(0.6))
					 .font(.system(size: headerIconSize))
					 .animation(.easeInOut, value: entry.hkUpdatedKetones)
			   }
			   if entry.bloodPressure != nil {
				  Image(systemName: "heart.fill")
					 .foregroundColor(entry.hkUpdatedBloodPressure ? .orange : .orange.opacity(0.6))
					 .font(.system(size: headerIconSize))
					 .animation(.easeInOut, value: entry.hkUpdatedBloodPressure)
			   }
			   if entry.steps != nil {
				  Image(systemName: "figure.walk")
					 .foregroundColor(entry.hkUpdatedSteps ? .green : .green.opacity(0.6))
					 .font(.system(size: headerIconSize))
					 .animation(.easeInOut, value: entry.hkUpdatedSteps)
			   }
			   if entry.sleepTime != nil {
				  Image(systemName: "moon.zzz.fill")
					 .foregroundColor(entry.hkUpdatedSleepTime ? .indigo : .indigo.opacity(0.6))
					 .font(.system(size: headerIconSize))
					 .animation(.easeInOut, value: entry.hkUpdatedSleepTime)
			   }
			   if entry.weight != nil {
				  Image(systemName: "scalemass.fill")
					 .foregroundColor(entry.hkUpdatedWeight ? .blue : .blue.opacity(0.6))
					 .font(.system(size: headerIconSize))
					 .animation(.easeInOut, value: entry.hkUpdatedWeight)
			   }
			   if entry.minHeartRate != nil || entry.maxHeartRate != nil || entry.avgHeartRate != nil {
				  Image(systemName: "heart.circle.fill")
					 .foregroundColor(entry.hkUpdatedHeartRate ? .pink : .pink.opacity(0.6))
					 .font(.system(size: headerIconSize))
					 .animation(.easeInOut, value: entry.hkUpdatedHeartRate)
			   }
			}
			.padding(.horizontal, 8)
			.padding(.vertical, 4)
			.background(Color.black.opacity(0.3))
			.cornerRadius(12)
			.padding(.trailing, 2)
		 }
		 
		 HStack(spacing: 12) {
			if let glucose = entry.glucose {
			   HStack(spacing: 4) {
				  Image(systemName: "drop.fill")
					 .foregroundColor(.red)
					 .font(.system(size: metricIconSize))
				  Text("\(numberFormatter.string(from: NSNumber(value: glucose)) ?? "0") mg/dL")
					 .font(.system(size: metricFontSize))
					 .lineLimit(1)
					 .minimumScaleFactor(0.5)
					 .foregroundColor(.red)
			   }
			   .frame(maxWidth: .infinity)
			}
			
			if let ketones = entry.ketones {
			   HStack(spacing: 4) {
				  Image(systemName: "flame.fill")
					 .foregroundColor(.purple)
					 .font(.system(size: metricIconSize))
				  Text("\(numberFormatter.string(from: NSNumber(value: ketones)) ?? "0") mmol")
					 .font(.system(size: metricFontSize))
					 .lineLimit(1)
					 .minimumScaleFactor(0.5)
					 .foregroundColor(.purple)
			   }
			   .frame(maxWidth: .infinity)
			}
			
			if let bp = entry.bloodPressure {
			   HStack(spacing: 4) {
				  Image(systemName: "heart.fill")
					 .foregroundColor(.orange)
					 .font(.system(size: metricIconSize))
				  Text(bp)
					 .font(.system(size: metricFontSize))
					 .lineLimit(1)
					 .minimumScaleFactor(0.5)
					 .foregroundColor(.orange)
			   }
			   .frame(maxWidth: .infinity)
			}
		 }
		 
		 HStack(spacing: 12) {
			if let steps = entry.steps {
			   HStack(spacing: 4) {
				  Image(systemName: "figure.walk")
					 .foregroundColor(.green)
					 .font(.system(size: metricIconSize))
				  Text("\(numberFormatter.string(from: NSNumber(value: steps)) ?? "0") steps")
					 .font(.system(size: metricFontSize))
					 .lineLimit(1)
					 .minimumScaleFactor(0.5)
					 .foregroundColor(.green)
			   }
			   .frame(maxWidth: .infinity)
			}
			
			if let weight = entry.weight {
			   WeightMetricView(
				  weight: weight,
				  entry: entry,
				  modelContext: modelContext,
				  formatter: numberFormatter,
				  metricFontSize: metricFontSize,
				  smallMetricFontSize: smallMetricFontSize,
				  metricIconSize: metricIconSize
			   )
			   .frame(maxWidth: .infinity)
			}
			
			if let sleepTime = entry.sleepTime {
			   HStack(spacing: 4) {
				  Image(systemName: "moon.zzz.fill")
					 .foregroundColor(.indigo)
					 .font(.system(size: metricIconSize))
				  Text(sleepTime)
					 .font(.system(size: metricFontSize))
					 .lineLimit(1)
					 .minimumScaleFactor(0.5)
					 .foregroundColor(.indigo)
			   }
			   .frame(maxWidth: .infinity)
			}
		 }
		 if entry.minHeartRate != nil || entry.maxHeartRate != nil {
			HStack(spacing: 12) {
			   HStack(spacing: 4) {
				  Image(systemName: "heart.circle.fill")
					 .foregroundColor(.pink)
					 .font(.system(size: metricIconSize))
				  Text("\(Int(entry.minHeartRate ?? 0))-\(Int(entry.maxHeartRate ?? 0)) bpm")
					 .font(.system(size: metricFontSize))
					 .lineLimit(1)
					 .minimumScaleFactor(0.5)
					 .foregroundColor(.pink)
			   }
			   .frame(maxWidth: .infinity)
			}
		 }
	  }
	  .padding(.vertical, 8)
   }
}
