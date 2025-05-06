//   UndoToastView.swift
//   BigPlan
//
//   Created by: Gp. on 5/5/25 at 8:00 PM
//     Modified:
//
//  Copyright Delicious Studios, LLC. - Grant Perry
//

import SwiftUI
import SwiftData

struct UndoToastView: View {
   @Binding var showToast: Bool
   @Binding var recentlyDeletedEntry: DailyHealthEntry?
   @Environment(\.modelContext) private var modelContext

   var body: some View {
	  VStack {
		 Spacer()
		 HStack {
			Text("Entry deleted")
			   .foregroundColor(.white)
			Spacer()
			Button("Undo") {
			   if let entry = recentlyDeletedEntry {
				  modelContext.insert(entry)
				  recentlyDeletedEntry = nil
			   }
			   showToast = false
			}
			.foregroundColor(.white)
			.fontWeight(.medium)
		 }
		 .padding()
		 .background(Color.black.opacity(0.8))
		 .cornerRadius(12)
		 .padding()
	  }
	  .transition(.move(edge: .bottom).combined(with: .opacity))
	  .animation(.easeInOut, value: showToast)
   }
}
