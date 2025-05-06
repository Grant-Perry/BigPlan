//
//  DailyHealthEntry.swift
//  BigPlan
//
//  Created by Grant Perry on 2025-05-05.
//
import SwiftUI
import Foundation
import SwiftData

/// A single day's health metrics, stored locally via SwiftData and synced with CloudKit.
@Model
final class DailyHealthEntry {
   var id: UUID = UUID()

   var date: Date = Date()
   var wakeTime: Date = Date()

   var glucose: Double?
   var ketones: Double?
   var bloodPressure: String?
   var weight: Double?
   var sleepTime: String?
   var stressLevel: Int?
   var walkedAM: Bool = false
   var walkedPM: Bool = false

   var firstMealTime: Date?
   var lastMealTime: Date?

   var steps: Int?
   var wentToGym: Bool = false
   var rlt: String?

   var weatherData: String?

   @Attribute(.externalStorage) var notes: String?

   init(
	  id: UUID = UUID(),
	  date: Date = Date(),
	  wakeTime: Date = Date(),
	  glucose: Double? = nil,
	  ketones: Double? = nil,
	  bloodPressure: String? = nil,
	  weight: Double? = nil,
	  sleepTime: String? = nil,
	  stressLevel: Int? = nil,
	  walkedAM: Bool = false,
	  walkedPM: Bool = false,
	  firstMealTime: Date? = nil,
	  lastMealTime: Date? = nil,
	  steps: Int? = nil,
	  wentToGym: Bool = false,
	  rlt: String? = nil,
	  weatherData: String? = nil,
	  notes: String? = nil
   ) {
	  self.id = id
	  self.date = date
	  self.wakeTime = wakeTime
	  self.glucose = glucose
	  self.ketones = ketones
	  self.bloodPressure = bloodPressure
	  self.weight = weight
	  self.sleepTime = sleepTime
	  self.stressLevel = stressLevel
	  self.walkedAM = walkedAM
	  self.walkedPM = walkedPM
	  self.firstMealTime = firstMealTime
	  self.lastMealTime = lastMealTime
	  self.steps = steps
	  self.wentToGym = wentToGym
	  self.rlt = rlt
	  self.weatherData = weatherData
	  self.notes = notes
   }
}
