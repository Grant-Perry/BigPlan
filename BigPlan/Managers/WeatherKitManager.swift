//
//  WeatherKitManager.swift
//  BigPlan
//
//  Created by Gp. on 5/5/25.
//

import Foundation
import WeatherKit
import CoreLocation
import OSLog

private let logger = Logger(subsystem: "BigPlan", category: "WeatherKitManager")

@MainActor
class WeatherKitManager: ObservableObject {
   static let shared = WeatherKitManager()
   
   private let weatherService = WeatherService()
   
   @Published var currentWeather: Weather?
   @Published var city: String?
   @Published var state: String?
   @Published var weatherData: String?
   
   private init() {}
   
   func fetchWeather(for location: CLLocation) async {
	  do {
		 // Clear existing weather data first
		 self.weatherData = nil
		 
		 let weather = try await weatherService.weather(for: location)
		 self.currentWeather = weather
		 
		 // Get city and state
		 let geocoder = CLGeocoder()
		 if let placemarks = try? await geocoder.reverseGeocodeLocation(location),
			let placemark = placemarks.first {
			self.city = placemark.locality
			self.state = placemark.administrativeArea
			
			// Format and set weather data
			if let weatherString = formatWeatherString(weather: weather) {
			   self.weatherData = weatherString
			}
		 }
		 
	  } catch {
		 logger.error("Failed to fetch weather: \(error.localizedDescription)")
	  }
   }
   
   private func formatWeatherString(weather: Weather) -> String? {
	  guard let city = city, let state = state else { return nil }
	  
	  let current = weather.currentWeather
	  let daily = weather.dailyForecast[0]
	  
	  // Convert temperatures to Fahrenheit
	  let currentTemp = current.temperature.converted(to: .fahrenheit).value
	  let lowTemp = daily.lowTemperature.converted(to: .fahrenheit).value
	  let highTemp = daily.highTemperature.converted(to: .fahrenheit).value
	  
	  let weatherString = """
		\(city), \(state)
		Current: \(Int(currentTemp))°  L: \(Int(lowTemp))° H: \(Int(highTemp))°
		\(current.condition.description)
		\(daily.condition.description)
		"""
	  
	  return weatherString
   }
}
//  Copyright 2025 Delicious Studios, LLC. - Grant Perry
