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
   @Attribute(.unique) var id: UUID
   var date: Date
   var wakeTime: Date
   var glucose: Double?
   var ketones: Double?
   var bloodPressure: String?
   var weight: Double?
   var sleepHours: Double?
   var stressLevel: Int?
   var walkedAM: Bool
   var walkedPM: Bool
   var firstMealTime: Date?
   var lastMealTime: Date?
   var steps: Int?
   var wentToGym: Bool
   var rlt: String?
   var notes: String?

   init(
	  id: UUID = UUID(),
	  date: Date = Date(),
	  wakeTime: Date = Date(),
	  glucose: Double? = nil,
	  ketones: Double? = nil,
	  bloodPressure: String? = nil,
	  weight: Double? = nil,
	  sleepHours: Double? = nil,
	  stressLevel: Int? = nil,
	  walkedAM: Bool = false,
	  walkedPM: Bool = false,
	  firstMealTime: Date? = nil,
	  lastMealTime: Date? = nil,
	  steps: Int? = nil,
	  wentToGym: Bool = false,
	  rlt: String? = nil,
	  notes: String? = nil
   ) {
	  self.id = id
	  self.date = date
	  self.wakeTime = wakeTime
	  self.glucose = glucose
	  self.ketones = ketones
	  self.bloodPressure = bloodPressure
	  self.weight = weight
	  self.sleepHours = sleepHours
	  self.stressLevel = stressLevel
	  self.walkedAM = walkedAM
	  self.walkedPM = walkedPM
	  self.firstMealTime = firstMealTime
	  self.lastMealTime = lastMealTime
	  self.steps = steps
	  self.wentToGym = wentToGym
	  self.rlt = rlt
	  self.notes = notes
   }
}
