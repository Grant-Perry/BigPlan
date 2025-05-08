//   DateTimeView.swift
//   BigPlan
//
//   Created by: Gp. on 5/5/25 at 7:58 PM
//     Modified: 
//
//  Copyright Delicious Studios, LLC. - Grant Perry
//

import SwiftUI

struct DateTimeView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   
   var body: some View {
	  VStack(alignment: .leading, spacing: 16) { 
		 HStack { 
			Text("Wake Time")
			   .font(.body) 
			Spacer()
			DatePicker("Wake Time", selection: $bigPlanViewModel.wakeTime, displayedComponents: .hourAndMinute)
			   .labelsHidden() 
		 }
	  }
	  .padding()
	  .background(Color(.secondarySystemBackground))
	  .cornerRadius(10)
   }
}
