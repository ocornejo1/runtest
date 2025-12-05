//
//  PaceUtilities.swift
//  Run
//
//  Created by Omar Cornejo
//

import Foundation

// MARK: - Pace Model

struct Pace: Comparable {
    let secondsPerKilometer: TimeInterval
    
    // MARK: - Comparable Conformance
    
    static func < (lhs: Pace, rhs: Pace) -> Bool {
        return lhs.secondsPerKilometer < rhs.secondsPerKilometer
    }
    
    static func == (lhs: Pace, rhs: Pace) -> Bool {
        return lhs.secondsPerKilometer == rhs.secondsPerKilometer
    }
    
    // MARK: - Initializers
    
    init(secondsPerKilometer: TimeInterval) {
        self.secondsPerKilometer = max(0, secondsPerKilometer)
    }
    
    init(distanceMeters: Double, durationSeconds: TimeInterval) {
        guard distanceMeters > 0 else {
            self.secondsPerKilometer = 0
            return
        }
        
        let distanceKm = distanceMeters / 1000.0
        self.secondsPerKilometer = durationSeconds / distanceKm
    }
    
    init(distanceKm: Double, durationSeconds: TimeInterval) {
        guard distanceKm > 0 else {
            self.secondsPerKilometer = 0
            return
        }
        
        self.secondsPerKilometer = durationSeconds / distanceKm
    }
    
    // MARK: - Computed Properties
    
    var secondsPerMile: TimeInterval {
        secondsPerKilometer * 1.60934
    }
    
    var minutesPerKilometer: Double {
        secondsPerKilometer / 60.0
    }
    
    var minutesPerMile: Double {
        secondsPerMile / 60.0
    }
    

    var isValid: Bool {
        secondsPerKilometer > 0 &&
        secondsPerKilometer >= 120 &&
        secondsPerKilometer <= 1500
    }
    
    // MARK: - Formatting
    
    func formatted(for unit: DistanceUnit) -> String {
        let seconds = unit == .kilometers ? secondsPerKilometer : secondsPerMile
        let unitLabel = unit == .kilometers ? "/km" : "/mi"
        
        guard isValid else {
            return "--:--\(unitLabel)"
        }
        
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        
        return String(format: "%d:%02d%@", minutes, secs, unitLabel)
    }
    
    func formattedWithoutUnit(for unit: DistanceUnit) -> String {
        let seconds = unit == .kilometers ? secondsPerKilometer : secondsPerMile
        
        guard isValid else {
            return "--:--"
        }
        
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        
        return String(format: "%d:%02d", minutes, secs)
    }
}


// MARK: - Pace Calculator Extensions

extension Pace {
    
    func projectedTime(for distanceKm: Double) -> TimeInterval {
        return secondsPerKilometer * distanceKm
    }
    
    func projectedDistance(for seconds: TimeInterval) -> Double {
        guard secondsPerKilometer > 0 else { return 0 }
        return seconds / secondsPerKilometer
    }
    
    func isFasterThan(_ other: Pace) -> Bool {
        return self.secondsPerKilometer < other.secondsPerKilometer
    }
    
    func percentageDifference(from other: Pace) -> Double {
        guard other.secondsPerKilometer > 0 else { return 0 }
        return ((self.secondsPerKilometer - other.secondsPerKilometer) / other.secondsPerKilometer) * 100
    }
}

// MARK: - Pace Zone Calculator

struct PaceZoneCalculator {
    let recentAveragePace: Pace
    
    var easyPace: ClosedRange<Pace> {
        let slow = Pace(secondsPerKilometer: recentAveragePace.secondsPerKilometer * 1.15)
        let fast = Pace(secondsPerKilometer: recentAveragePace.secondsPerKilometer * 1.05)
        return fast...slow
    }
    
    var tempoPace: ClosedRange<Pace> {
        let slow = Pace(secondsPerKilometer: recentAveragePace.secondsPerKilometer * 1.05)
        let fast = Pace(secondsPerKilometer: recentAveragePace.secondsPerKilometer * 0.95)
        return fast...slow
    }
    
    var thresholdPace: ClosedRange<Pace> {
        let slow = Pace(secondsPerKilometer: recentAveragePace.secondsPerKilometer * 0.95)
        let fast = Pace(secondsPerKilometer: recentAveragePace.secondsPerKilometer * 0.90)
        return fast...slow
    }
    
    var intervalPace: ClosedRange<Pace> {
        let slow = Pace(secondsPerKilometer: recentAveragePace.secondsPerKilometer * 0.90)
        let fast = Pace(secondsPerKilometer: recentAveragePace.secondsPerKilometer * 0.85)
        return fast...slow
    }
    
    func formatRange(_ range: ClosedRange<Pace>, unit: DistanceUnit) -> String {
        return "\(range.lowerBound.formattedWithoutUnit(for: unit)) - \(range.upperBound.formattedWithoutUnit(for: unit))"
    }
}

// MARK: - Helper Extensions

extension TimeInterval {

    var asMMSS: String {
        let totalSeconds = Int(self)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var asHHMMSS: String {
        let totalSeconds = Int(self)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}
