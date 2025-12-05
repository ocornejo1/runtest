//
//  ValidationUtilities.swift
//  Run
//
//  Created by Omar Cornejo
//

import Foundation

enum ValidationUtilities {
    
    // MARK: - Distance Validation
    
    static func validateDistance(_ text: String, unit: DistanceUnit = .kilometers) -> Double? {
        let cleaned = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        
        guard !cleaned.isEmpty else { return nil }
        guard let value = Double(cleaned) else { return nil }
        
        let valueInKm = unit == .miles ? value / 0.621371 : value
        
        guard valueInKm >= 0 && valueInKm <= SafetyThresholds.maxReasonableDistanceKm else {
            return nil
        }
        
        return valueInKm
    }
    
    // MARK: - Weekly Volume Validation
    
    static func validateWeeklyVolume(_ text: String, unit: DistanceUnit = .kilometers) -> Double? {
        guard let distance = validateDistance(text, unit: unit) else { return nil }
        
        guard distance <= SafetyThresholds.maxReasonableWeeklyKm else {
            return nil
        }
        
        return distance
    }
    
    // MARK: - Name Validation
    
    static func validateDisplayName(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty && trimmed.count <= 50 else {
            return nil
        }
        
        return trimmed
    }
    
    // MARK: - Duration Validation
    
    static func validateDuration(_ text: String) -> Bool {
        let parts = text.split(separator: ":").map { String($0) }
        
        guard parts.count == 2 else { return false }
        guard let minutes = Int(parts[0]), let seconds = Int(parts[1]) else { return false }
        
        return minutes >= 0 && minutes < 1000 && seconds >= 0 && seconds < 60
    }
    
    static func durationToSeconds(_ text: String) -> TimeInterval? {
        let parts = text.split(separator: ":").map { String($0) }
        
        guard parts.count == 2,
              let minutes = Double(parts[0]),
              let seconds = Double(parts[1]) else {
            return nil
        }
        
        return minutes * 60 + seconds
    }
    
    static func secondsToDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    // MARK: - Rating Validation
    
    static func validateRating(_ value: Int, range: ClosedRange<Int>) -> Bool {
        return range.contains(value)
    }
    
    // MARK: - Email Validation
    
    static func validateEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: trimmed)
    }
    
    // MARK: - Password Validation
    
    static func validatePassword(_ password: String) -> (isValid: Bool, message: String?) {
        guard password.count >= 8 else {
            return (false, "Password must be at least 8 characters")
        }
        
        guard password.count <= 128 else {
            return (false, "Password is too long")
        }
        
        
        return (true, nil)
    }
}

// MARK: - Validation Error Types

enum ValidationError: LocalizedError {
    case invalidDistance(String)
    case invalidDuration(String)
    case invalidName(String)
    case invalidEmail(String)
    case invalidPassword(String)
    case invalidRating(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidDistance(let message):
            return message
        case .invalidDuration(let message):
            return message
        case .invalidName(let message):
            return message
        case .invalidEmail(let message):
            return message
        case .invalidPassword(let message):
            return message
        case .invalidRating(let message):
            return message
        }
    }
}
