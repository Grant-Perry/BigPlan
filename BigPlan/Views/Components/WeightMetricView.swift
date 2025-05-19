import SwiftUI
import SwiftData

struct WeightMetricView: View {
   let weight: Double
   let entry: DailyHealthEntry
   let modelContext: ModelContext
   let formatter: NumberFormatter
   let metricFontSize: CGFloat
   let smallMetricFontSize: CGFloat
   let metricIconSize: CGFloat
   
   var lastEntry: DailyHealthEntry? {
      let descriptor = FetchDescriptor<DailyHealthEntry>(
         sortBy: [SortDescriptor(\DailyHealthEntry.date, order: .reverse)]
      )
      let entries = try? modelContext.fetch(descriptor)
      return entries?.first { $0.date < entry.date }
   }
   
   var weightDiffFromLast: (diff: Double, isUp: Bool)? {
      guard let lastWeight = lastEntry?.weight else { return nil }
      let diff = weight - lastWeight
      return (abs(diff), diff > 0)
   }
   
   var body: some View {
      VStack(alignment: .leading, spacing: 2) {
         HStack(spacing: 4) {
            Image(systemName: "scalemass.fill")
               .foregroundColor(.blue)
               .font(.system(size: metricIconSize))
            Text("\(formatter.string(from: NSNumber(value: weight)) ?? "0") lbs")
               .font(.system(size: metricFontSize))
               .lineLimit(1)
               .minimumScaleFactor(0.5)
               .foregroundColor(.blue)
         }
         
         if let (diff, isUp) = weightDiffFromLast {
            HStack(spacing: 2) {
               Text("Last:")
                  .foregroundStyle(.gray)
                  .font(.system(size: smallMetricFontSize))
               Image(systemName: isUp ? "arrow.up" : "arrow.down")
                  .foregroundStyle(isUp ? .green : .green)
                  .font(.system(size: smallMetricFontSize))
               Text("\(formatter.string(from: NSNumber(value: diff)) ?? "0")")
                  .foregroundStyle(isUp ? .green : .green)
                  .font(.system(size: smallMetricFontSize))
            }
         }
      }
   }
}