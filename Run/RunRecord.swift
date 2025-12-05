//
//  RunRecord.swift
//  Run
//
//  Created by Omar Cornejo
//


import Foundation

struct RunRecord: Identifiable {
    let id: String
    let date: Date
    let distanceMeters: Double
    let duration: String
    let restTime: String?
    let difficultyRating: Int?
    let painLevel: Int?
    let painAreas: [String]?
    let notes: String?

    // MARK: - Distance Helpers
    
    var distanceKm: Double {
        distanceMeters / 1000.0
    }

    var distanceMiles: Double {
        distanceMeters / 1609.34
    }
    
    // MARK: - Duration Helpers
    
    var durationSeconds: TimeInterval {
        let parts = duration.split(separator: ":").map { String($0) }
        guard parts.count == 2,
              let minutes = Double(parts[0]),
              let seconds = Double(parts[1]) else {
            return 0
        }
        return (minutes * 60) + seconds
    }
    
    var durationFormatted: String {
        let seconds = Int(durationSeconds)
        let hours = seconds / 3600
        let mins = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, mins, secs)
        } else {
            return String(format: "%02d:%02d", mins, secs)
        }
    }
    
    // MARK: - Pace Calculations
    
    var pace: Pace {
        Pace(distanceMeters: distanceMeters, durationSeconds: durationSeconds)
    }
    
    var pacePerKm: Pace {
        pace
    }
    
    var pacePerMile: Pace {
        Pace(secondsPerKilometer: pace.secondsPerMile)
    }
    
    func formattedPace(unit: DistanceUnit) -> String {
        pace.formatted(for: unit)
    }
    
    // MARK: - Display Helpers
    
    func formattedDistance(unit: DistanceUnit) -> String {
        switch unit {
        case .kilometers:
            return String(format: "%.2f km", distanceKm)
        case .miles:
            return String(format: "%.2f mi", distanceMiles)
        }
    }
}

// MARK: - Comparable for sorting by pace

extension RunRecord: Comparable {
    static func < (lhs: RunRecord, rhs: RunRecord) -> Bool {
        return lhs.pace.secondsPerKilometer < rhs.pace.secondsPerKilometer
    }
}
