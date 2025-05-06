//   MetricView.swift
//   BigPlan
//
//   Created by: Gp. on 5/5/25 at 8:00 PM
//     Modified: 
//
//  Copyright © 2025 Delicious Studios, LLC. - Grant Perry
//

import SwiftUI

struct MetricView: View {
   let value: String
   let unit: String
   let icon: String
   let color: Color

   var body: some View {
	  HStack(spacing: 4) {
		 Image(systemName: icon)
			.foregroundColor(color)
			.frame(width: 20)

		 VStack(alignment: .leading, spacing: 2) {
			Text(value)
			   .fontWeight(.medium)
			   .lineLimit(1)
			   .minimumScaleFactor(0.5)
			Text(unit)
			   .font(.caption2)
			   .foregroundColor(.secondary)
			   .lineLimit(1)
			   .minimumScaleFactor(0.5)
		 }
		 .frame(minWidth: 50)
	  }
	  .frame(maxWidth: .infinity, alignment: .leading)
   }
}
