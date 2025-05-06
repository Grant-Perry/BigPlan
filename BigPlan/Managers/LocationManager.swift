//
//  LocationManager.swift
//  BigPlan
//
//  Created by Gp. on 5/5/25.
//

import Foundation
import CoreLocation
import OSLog

private let logger = Logger(subsystem: "BigPlan", category: "LocationManager")

@MainActor
class LocationManager: NSObject, ObservableObject {
   static let shared = LocationManager()
   
   private let manager = CLLocationManager()
   
   @Published var location: CLLocation?
   @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
   @Published var lastError: String?
   
   private override init() {
	  super.init()
	  manager.delegate = self
	  manager.desiredAccuracy = kCLLocationAccuracyHundredMeters 
	  manager.distanceFilter = 1000 
	  manager.allowsBackgroundLocationUpdates = false 
   }
   
   func requestAuthorization() {
	  guard authorizationStatus == .notDetermined else {
		 if authorizationStatus == .denied {
			lastError = "Location access is denied. Please enable in Settings."
		 }
		 return
	  }
	  manager.requestWhenInUseAuthorization()
   }
   
   func startUpdatingLocation() {
	  guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
		 lastError = "Location access not authorized"
		 return
	  }
	  manager.startUpdatingLocation()
   }
   
   func stopUpdatingLocation() {
	  manager.stopUpdatingLocation()
   }
   
   var canGetLocation: Bool {
	  switch authorizationStatus {
		 case .authorizedWhenInUse, .authorizedAlways:
			return true
		 default:
			return false
	  }
   }
}

extension LocationManager: CLLocationManagerDelegate {
   nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
	  let status = manager.authorizationStatus
	  Task { @MainActor in
		 self.authorizationStatus = status
		 self.lastError = nil 
		 
		 switch status {
			case .authorizedWhenInUse, .authorizedAlways:
			   self.startUpdatingLocation()
			case .denied:
			   self.lastError = "Location access denied. Please enable in Settings."
			   self.stopUpdatingLocation()
			case .restricted:
			   self.lastError = "Location access restricted"
			   self.stopUpdatingLocation()
			case .notDetermined:
			   logger.info("Location status not determined")
			@unknown default:
			   break
		 }
	  }
   }
   
   nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
	  guard let location = locations.last else { return }
	  
	  guard location.timestamp.timeIntervalSinceNow > -60 && 
			   location.horizontalAccuracy > 0 && 
			   location.horizontalAccuracy < 100 
	  else { return }
	  
	  Task { @MainActor in
		 self.location = location
		 self.lastError = nil
	  }
   }
   
   nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
	  Task { @MainActor in
		 if let error = error as? CLError {
			switch error.code {
			   case .denied:
				  lastError = "Location access denied"
			   case .network:
				  lastError = "Network error getting location"
			   default:
				  lastError = error.localizedDescription
			}
		 } else {
			lastError = error.localizedDescription
		 }
		 logger.error("Location manager failed: \(error.localizedDescription)")
	  }
   }
}
