//   NotesView.swift
//   BigPlan
//
//   Created by: Gp. on 5/5/25 at 7:40 PM
//     Modified: 
//
//  Copyright Delicious Studios, LLC. - Grant Perry 

import SwiftUI

struct NotesView: View {
   @ObservedObject var bigPlanViewModel: BigPlanViewModel
   @State private var isInitialWeatherLoaded = false
   
   private var isToday: Bool {
	  Calendar.current.isDateInToday(bigPlanViewModel.date)
   }
   
   var body: some View {
	  VStack(alignment: .leading, spacing: 20) {
		 // Weather Section
		 VStack(alignment: .leading, spacing: 8) {
			HStack {
			   Text("WEATHER")
				  .font(.subheadline)
				  .foregroundColor(.gray)
			   Spacer()
			   if !bigPlanViewModel.isEditing || isToday {
				  Button {
					 Task {
						await bigPlanViewModel.fetchAndAppendWeather()
					 }
				  } label: {
					 Image(systemName: "arrow.clockwise")
						.foregroundColor(.accentColor)
				  }
				  .disabled(bigPlanViewModel.isLoadingWeather)
			   }
			}
			
			if let weatherData = bigPlanViewModel.weatherData {
			   VStack(alignment: .leading, spacing: 4) {
				  let lines = weatherData.components(separatedBy: "\n")
				  if lines.count >= 1 {
					 Text(lines[0])  // City, State
						.font(.callout)
				  }
				  ForEach(1..<lines.count, id: \.self) { index in
					 Text(lines[index])
						.font(.caption2)
				  }
			   }
			   .frame(maxWidth: .infinity, alignment: .leading)
			   .padding()
			   .background(Color(.secondarySystemBackground))
			   .cornerRadius(10)
			}
		 }
		 
		 // Notes Section
		 VStack(alignment: .leading, spacing: 8) {
			Text("NOTES")
			   .font(.subheadline)
			   .foregroundColor(.gray)
			
			TextEditor(text: Binding(
			   get: { bigPlanViewModel.notes ?? "" },
			   set: { bigPlanViewModel.notes = $0.isEmpty ? nil : $0 }
			))
			.frame(minHeight: 100)
			.padding()
			.background(Color(.secondarySystemBackground))
			.cornerRadius(10)
			.overlay(
			   Group {
				  if (bigPlanViewModel.notes ?? "").isEmpty {
					 Text("Enter any additional notes here...")
						.foregroundColor(.gray.opacity(0.5))
						.padding(.top, 16)
						.padding(.leading, 12)
				  }
			   },
			   alignment: .topLeading
			)
		 }
	  }
	  .task {
		 // Only fetch weather once when view appears
		 if !isInitialWeatherLoaded && (!bigPlanViewModel.isEditing || isToday) {
			isInitialWeatherLoaded = true
			await bigPlanViewModel.fetchAndAppendWeather()
		 }
	  }
   }
}
