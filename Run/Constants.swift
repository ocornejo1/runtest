//
//  Constants.swift
//  Run
//  Created by Omar Cornejo
//

import Foundation

// MARK: - Recommendation Engine Constants

enum ReadinessThresholds {
    // Below this value: complete rest day
    static let fullRest: Double = 20
    
    // Below this: light activity only (or easy run for non-beginners)
    static let lightActivity: Double = 40
    
    // Below this: easy run
    static let easyRun: Double = 60
    
    // Above this: normal run or workout
    static let normalRun: Double = 60
}

enum ReadinessWeights {
    // Points gained per rest day
    static let restDayBonus: Double = 10.0
    
    // Negative impact of soreness (per point on 0-10 scale)
    static let sorenessImpact: Double = 2.0
    
    // Positive impact of sleep quality (per point on 1-5 scale)
    static let sleepQualityBonus: Double = 3.0
    
    // Negative impact of current pain (per point on 0-10 scale)
    static let painImpact: Double = 3.0
    
    // Factor applied to session load (difficulty × duration)
    static let sessionLoadFactor: Double = 0.3
    
    // Factor applied to pain penalty
    static let painPenaltyFactor: Double = 0.5
}

enum ExperienceFactors {
    // Recovery multiplier for beginners (slower recovery)
    static let beginner: Double = 0.7
    
    // Recovery multiplier for intermediate runners (baseline)
    static let intermediate: Double = 1.0
    
    // Recovery multiplier for advanced runners (faster recovery)
    static let advanced: Double = 1.3
}

// MARK: - Training Progression Constants

enum ProgressionRules {
    // Minimum number of runs needed before recommending progression
    static let minRunsForProgression = 3
    
    // Days of history required for auto-upgrade consideration
    static let autoUpgradeMinDays = 60
    
    // Distance multiplier required for auto-upgrade (last run vs first run)
    static let autoUpgradeDistanceMultiplier = 2.5
    
    // Number of weeks required to progress from beginner to intermediate
    static let weeksToIntermediate = 8
}

enum DistanceProgression {
    // Distance increment for beginners (km)
    static let beginnerIncrement = 0.5
    
    // Distance increment for intermediate/advanced (km)
    static let normalIncrement = 1.0
    
    // Maximum safe distance for a first run (km)
    static let maxFirstRun = 6.0
    
    // Minimum safe distance for any run (km)
    static let minRunDistance = 2.0
}

// MARK: - Safety Thresholds

enum SafetyThresholds {
    // Pain level that triggers complete rest
    static let criticalPain = 8
    
    // Pain level that triggers caution in certain body areas
    static let moderatePain = 6
    
    // Difficulty rating considered "very hard"
    static let veryHardDifficulty = 4
    
    // Pain level after run that triggers caution
    static let postRunPainConcern = 6
    
    // Maximum reasonable distance in km (for validation)
    static let maxReasonableDistanceKm = 500.0
    
    // Maximum reasonable weekly volume in km (for validation)
    static let maxReasonableWeeklyKm = 300.0
}

enum CriticalPainAreas {
    // Body parts that are particularly injury-prone
    static let highRisk = ["Knees", "Shins", "Achilles"]
}

// MARK: - Load Management

enum LoadManagement {
    // Acute to chronic load ratio threshold (injury risk increases above this)
    static let acrRiskThreshold = 1.5
    
    // Penalty to readiness when ACR is too high
    static let highACRPenalty = -20.0
    
    //Number of weeks for chronic load calculation
    static let chronicLoadWeeks = 4
}

// MARK: - Database Constants

enum FirestoreCollections {
    static let users = "users"
    static let runs = "runs"
    static let dailyCheckins = "dailyCheckins"
}

enum FirestoreFields {
    static let uid = "uid"
    static let email = "email"
    static let displayName = "displayName"
    static let experienceLevel = "experienceLevel"
    static let completedOnboarding = "completedOnboarding"
    static let lastCheckInDate = "lastCheckInDate"
    static let userId = "userId"
    static let distance = "distance"
    static let duration = "duration"
    static let timestamp = "timestamp"
    static let difficultyRating = "difficultyRating"
    static let painLevel = "painLevel"
    static let painAreas = "painAreas"
}

// MARK: - Date Formats

enum DateFormats {
    static let dailyKey = "yyyy-MM-dd"
}

// MARK: - UI Constants

enum UIConstants {
    static let cardCornerRadius: CGFloat = 12
    
    static let cardPadding: CGFloat = 16
    
    static let sectionSpacing: CGFloat = 24
}


