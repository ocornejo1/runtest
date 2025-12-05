//
//  UserRelativePaceAnalyzer.swift
//  Run
//
//  Created by Omar Cornejo
//

import Foundation

// MARK: - Relative Pace Category

enum RelativePaceCategory {
    case veryFast
    case fast
    case normal
    case easy
    case recovery
    
    var displayName: String {
        switch self {
        case .veryFast:
            return "Very Fast"
        case .fast:
            return "Fast"
        case .normal:
            return "Normal"
        case .easy:
            return "Easy"
        case .recovery:
            return "Recovery"
        }
    }
    
    var color: String {
        switch self {
        case .veryFast:
            return "purple"
        case .fast:
            return "blue"
        case .normal:
            return "green"
        case .easy:
            return "orange"
        case .recovery:
            return "gray"
        }
    }
    
    var description: String {
        switch self {
        case .veryFast:
            return "This was a hard effort for you"
        case .fast:
            return "This was faster than your usual pace"
        case .normal:
            return "This was your typical training pace"
        case .easy:
            return "This was an easy effort for you"
        case .recovery:
            return "This was a nice recovery pace"
        }
    }
    
    var advice: String {
        switch self {
        case .veryFast:
            return "Great work! Make sure to balance hard efforts with easy days."
        case .fast:
            return "Nice pickup! Remember to recover properly before your next hard run."
        case .normal:
            return "Solid run at your comfortable pace. Perfect for building fitness."
        case .easy:
            return "Perfect! Easy runs build your aerobic base safely."
        case .recovery:
            return "Smart pacing! Recovery runs help you adapt and improve."
        }
    }
}

// MARK: - User Pace Analyzer

class UserRelativePaceAnalyzer {
    
    static func calculateAveragePace(from recentRuns: [RunSummary]) -> Pace? {
        guard recentRuns.count >= 3 else { return nil }
        
        let calendar = Calendar.current
        guard let eightWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -8, to: Date()) else {
            return nil
        }
        
        let relevantRuns = recentRuns.filter { $0.date >= eightWeeksAgo }
        guard !relevantRuns.isEmpty else { return nil }
        
        let totalDistance = relevantRuns.reduce(0.0) { $0 + $1.distanceKm }
        let totalDuration = relevantRuns.reduce(0.0) { $0 + ($1.durationMinutes * 60) }
        
        guard totalDistance > 0 else { return nil }
        
        return Pace(distanceKm: totalDistance, durationSeconds: totalDuration)
    }
    
    static func categorizePace(_ pace: Pace, relativeTo userAveragePace: Pace) -> RelativePaceCategory {
        let percentDifference = pace.percentageDifference(from: userAveragePace)
        
        switch percentDifference {
        case ..<(-15):
            return .veryFast
        case -15..<(-5):
            return .fast
        case -5...5:
            return .normal
        case 5..<15:
            return .easy
        default:
            return .recovery
        }
    }
    
    static func getEncouragementMessage(
        relativeCategory: RelativePaceCategory,
        difficultyRating: Int?,
        painLevel: Int?
    ) -> String {
        
        if let pain = painLevel, pain >= 6 {
            return "Listen to your body. Rest and recovery are part of training!"
        }
        
        if let difficulty = difficultyRating {
            
            if (relativeCategory == .fast || relativeCategory == .veryFast) && difficulty <= 2 {
                return "Amazing! You're getting stronger - this pace felt easier than before!"
            }
            
            if (relativeCategory == .easy || relativeCategory == .recovery) && difficulty >= 4 {
                return "This felt harder than usual. Make sure you're getting enough rest and recovery."
            }
            
            if relativeCategory == .normal && difficulty == 3 {
                return "Perfect balance! This is exactly the kind of sustainable training that builds fitness."
            }
        }
        
        return relativeCategory.advice
    }
    
    static func shouldSuggestLevelUpgrade(recentRuns: [RunSummary]) -> Bool {
        guard recentRuns.count >= 10 else { return false }
        
        let sorted = recentRuns.sorted { $0.date < $1.date }
        
        let firstFive = Array(sorted.prefix(5))
        let lastFive = Array(sorted.suffix(5))
        
        guard let earlyAvg = calculateAveragePace(from: firstFive),
              let recentAvg = calculateAveragePace(from: lastFive) else {
            return false
        }
        
        let improvement = recentAvg.percentageDifference(from: earlyAvg)
        return improvement < -10
    }
}

// MARK: - Extension to RunRecord

extension RunRecord {
    
    func relativePaceCategory(comparedTo userAveragePace: Pace) -> RelativePaceCategory {
        return UserRelativePaceAnalyzer.categorizePace(self.pace, relativeTo: userAveragePace)
    }
    
    func encouragementMessage(comparedTo userAveragePace: Pace) -> String {
        let relativeCategory = relativePaceCategory(comparedTo: userAveragePace)
        return UserRelativePaceAnalyzer.getEncouragementMessage(
            relativeCategory: relativeCategory,
            difficultyRating: difficultyRating,
            painLevel: painLevel
        )
    }
}

