//   DateTimeView.swift
//   BigPlan
//
//   Created by: Gp. on 5/5/25 at 7:58 PM
//     Modified: 
//
//  Copyright © 2025 Delicious Studios, LLC. - Grant Perry
//

import SwiftUI

struct DateTimeView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel

   var body: some View {
	  VStack(alignment: .leading, spacing: 12) {
		 Text("Date & Time")
			.font(.headline)
			.padding(.top)

		 DatePicker("Date", selection: $bigPlanViewModel.date, displayedComponents: .date)
			.labelsHidden()

		 DatePicker("Wake Time", selection: $bigPlanViewModel.wakeTime, displayedComponents: .hourAndMinute)
			.labelsHidden()
	  }
   }
}
