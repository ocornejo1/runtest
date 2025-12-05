//
//  RecommendationEngine.swift
//  Run
//
//  Created by Omar Cornejo
//

import Foundation

// MARK: - Enums

enum ExperienceLevel: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .beginner:
            return "Beginner"
        case .intermediate:
            return "Intermediate"
        case .advanced:
            return "Advanced"
        }
    }
}

enum DistanceUnit: String, Codable, CaseIterable, Identifiable {
    case kilometers
    case miles
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .kilometers:
            return "kilometers"
        case .miles:
            return "miles"
        }
    }
    
    func convertMetersToDisplay(_ meters: Double) -> Double {
        switch self {
        case .kilometers:
            return meters / 1000
        case .miles:
            return meters / 1609.34
        }
    }
}

enum PrimaryGoal: String, Codable, CaseIterable {
    case none
    case generalFitness
    case weightLoss
    case race5k
    case race10k
    case raceHalfMarathon
    case raceMarathon
    case personalBest
    
    var id: Self { self }
    
    var displayName: String {
        switch self {
        case .none:
            return "None"
        case .generalFitness:
            return "General Fitness"
        case .weightLoss:
            return "Weight Loss"
        case .race5k:
            return "5k Race"
        case .race10k:
            return "10k Race"
        case .raceHalfMarathon:
            return "Half Marathon"
        case .raceMarathon:
            return "Marathon"
        case .personalBest:
            return "Personal Best"
        }
    }
    
    var targetDistanceKm: Double? {
        switch self {
        case .race5k:
            return 5.0
        case .race10k:
            return 10.0
        case .raceHalfMarathon:
            return 21.1
        case .raceMarathon:
            return 42.2
        case .none, .generalFitness, .weightLoss, .personalBest:
            return nil
        }
    }
    
    func getTargetDistance(customDistance: Double?) -> Double? {
        if let standard = targetDistanceKm {
            return standard
        }
        if self == .personalBest, let custom = customDistance {
            return custom
        }
        return nil
    }
    
    var isRaceOrPR: Bool {
        switch self {
        case .race5k, .race10k, .raceHalfMarathon, .raceMarathon, .personalBest:
            return true
        default:
            return false
        }
    }
}

// MARK: - Input Models

struct RunnerProfile: Codable {
    let uid: String
    var displayName: String
    var experienceLevel: ExperienceLevel
    var distanceUnit: DistanceUnit
    let createdAt: Date
    var primaryGoal: PrimaryGoal
    var runsPerWeek: Int
    var longestRunKm: Double
    var typicalWeeklyKm: Double
    var goalDescription: String?
    var firstRunDate: Date?
    var firstRunDistanceKm: Double?
    var customGoalDistanceKm: Double?
}

struct RunSummary {
    let date: Date
    let durationMinutes: Double
    let distanceKm: Double
    let difficultyRating: Int
    let painLevel: Int
    let painAreas: [String]
}

struct TodayCheckIn {
    let soreness: Int
    let sleepQuality: Int
    let painNowLevel: Int
    let painNowAreas: [String]
}

// MARK: - Output

struct SessionRecommendation {
    let type: SessionType
    let distanceKm: Double?
    let explanation: String
    let warnings: [String]
}

enum SessionType {
    case fullRest
    case easyRun
    case normalRun
    case longRun
    case tempoRun
    case intervals
    case strengthAndMobility
    case restWithInjuryAdvice
    case needsMoreRuns
}

// MARK: - Engine

class RecommendationEngine {
    
    private let requiredRunsForRecommendations = 3
    private let maxWeeklyIncreasePercent = 0.10
    private let safeWeeklyVolumeMultiplier = 1.5
    
    // MARK: - Main Entry
    
    func nextSession(for profile: RunnerProfile,
                     recentRuns: [RunSummary],
                     today: TodayCheckIn?) -> SessionRecommendation {
        
        if recentRuns.count < requiredRunsForRecommendations {
            return buildingBaselineRecommendation(runsCompleted: recentRuns.count)
        }
        
        let sortedRuns = recentRuns.sorted { $0.date > $1.date }
        guard let lastRun = sortedRuns.first else {
            return buildingBaselineRecommendation(runsCompleted: 0)
        }
        
        if let injuryRec = checkForInjuryRisk(lastRun: lastRun, today: today) {
            return injuryRec
        }
        
        let weeklyStats = calculateWeeklyStats(runs: sortedRuns)
        let readiness = computeReadiness(profile: profile, lastRun: lastRun, today: today)
        let daysSinceLastRun = daysBetween(from: lastRun.date, to: Date())
        
        return generateRecommendation(
            profile: profile,
            lastRun: lastRun,
            weeklyStats: weeklyStats,
            readiness: readiness,
            daysSinceLastRun: daysSinceLastRun,
            recentRuns: sortedRuns
        )
    }
    
    // MARK: - Building Baseline
    
    private func buildingBaselineRecommendation(runsCompleted: Int) -> SessionRecommendation {
        let remaining = requiredRunsForRecommendations - runsCompleted
        
        let message: String
        switch runsCompleted {
        case 0:
            message = "Welcome! Complete your first 3 runs at an easy pace so we can learn your fitness level and give you personalized recommendations."
        case 1:
            message = "Great first run! Complete \(remaining) more easy runs so we can personalize your training."
        case 2:
            message = "One more run to go! After this, you'll unlock personalized recommendations."
        default:
            message = "Complete \(remaining) more runs to unlock personalized recommendations."
        }
        
        return SessionRecommendation(
            type: .needsMoreRuns,
            distanceKm: nil,
            explanation: message,
            warnings: ["Run at a pace where you can hold a conversation"]
        )
    }
    
    // MARK: - Injury Check
    
    private func checkForInjuryRisk(lastRun: RunSummary, today: TodayCheckIn?) -> SessionRecommendation? {
        if let today = today {
            if today.painNowLevel >= SafetyThresholds.criticalPain {
                return SessionRecommendation(
                    type: .restWithInjuryAdvice,
                    distanceKm: nil,
                    explanation: "You reported significant pain. Rest today and consider seeing a doctor if pain persists.",
                    warnings: ["High pain level - do not run"]
                )
            }
            
            if today.painNowLevel >= SafetyThresholds.moderatePain &&
               today.painNowAreas.contains(where: { CriticalPainAreas.highRisk.contains($0) }) {
                return SessionRecommendation(
                    type: .restWithInjuryAdvice,
                    distanceKm: nil,
                    explanation: "You have pain in a high-risk area. Rest today to prevent injury.",
                    warnings: ["Pain in critical area - rest recommended"]
                )
            }
        }
        
        if lastRun.painLevel >= SafetyThresholds.criticalPain {
            return SessionRecommendation(
                type: .restWithInjuryAdvice,
                distanceKm: nil,
                explanation: "Your last run caused significant pain. Take a rest day and monitor how you feel.",
                warnings: ["Previous run caused pain"]
            )
        }
        
        return nil
    }
    
    // MARK: - Weekly Stats
    
    private struct WeeklyStats {
        let totalDistanceKm: Double
        let runCount: Int
        let avgDistanceKm: Double
        let avgDifficulty: Double
    }
    
    private func calculateWeeklyStats(runs: [RunSummary]) -> WeeklyStats {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let thisWeekRuns = runs.filter { $0.date >= weekAgo }
        
        let totalDistance = thisWeekRuns.reduce(0) { $0 + $1.distanceKm }
        let runCount = thisWeekRuns.count
        let avgDistance = runCount > 0 ? totalDistance / Double(runCount) : 0
        let avgDifficulty = runCount > 0 ? thisWeekRuns.reduce(0) { $0 + Double($1.difficultyRating) } / Double(runCount) : 0
        
        return WeeklyStats(
            totalDistanceKm: totalDistance,
            runCount: runCount,
            avgDistanceKm: avgDistance,
            avgDifficulty: avgDifficulty
        )
    }
    
    // MARK: - Generate Recommendation
    
    private func generateRecommendation(
        profile: RunnerProfile,
        lastRun: RunSummary,
        weeklyStats: WeeklyStats,
        readiness: Double,
        daysSinceLastRun: Int,
        recentRuns: [RunSummary]
    ) -> SessionRecommendation {
        
        var warnings: [String] = []
        let isBeginner = profile.experienceLevel == .beginner
        
        let avgRecentDistance = recentRuns.prefix(5).reduce(0) { $0 + $1.distanceKm } / Double(min(5, recentRuns.count))
        
        let safeWeeklyMax = max(profile.typicalWeeklyKm * safeWeeklyVolumeMultiplier, avgRecentDistance * Double(profile.runsPerWeek) * 1.1)
        let remainingWeeklyBudget = max(0, safeWeeklyMax - weeklyStats.totalDistanceKm)
        
        let runsRemainingThisWeek = max(0, profile.runsPerWeek - weeklyStats.runCount)
        
        if weeklyStats.totalDistanceKm > safeWeeklyMax {
            warnings.append("You've exceeded your safe weekly volume")
        }
        
        if readiness < ReadinessThresholds.fullRest {
            return SessionRecommendation(
                type: .fullRest,
                distanceKm: nil,
                explanation: "Your body needs rest today. Recovery is when you get stronger!",
                warnings: warnings
            )
        }
        
        if readiness < ReadinessThresholds.lightActivity {
            if isBeginner {
                return SessionRecommendation(
                    type: .strengthAndMobility,
                    distanceKm: nil,
                    explanation: "Take it easy today. Light stretching or mobility work is ideal.",
                    warnings: warnings
                )
            } else {
                let dist = min(avgRecentDistance * 0.5, remainingWeeklyBudget, 4.0)
                return SessionRecommendation(
                    type: .easyRun,
                    distanceKm: max(DistanceProgression.minRunDistance, dist),
                    explanation: "A short recovery run if you feel up to it, otherwise rest.",
                    warnings: warnings
                )
            }
        }
        
        if daysSinceLastRun == 0 {
            return SessionRecommendation(
                type: .fullRest,
                distanceKm: nil,
                explanation: "You already ran today. Rest and recover for tomorrow!",
                warnings: warnings
            )
        }
        
        if runsRemainingThisWeek <= 0 && weeklyStats.runCount >= profile.runsPerWeek {
            return SessionRecommendation(
                type: .fullRest,
                distanceKm: nil,
                explanation: "You've hit your weekly run target. Take a rest day!",
                warnings: warnings
            )
        }
        
        let targetDistance = calculateTargetDistance(
            profile: profile,
            avgRecentDistance: avgRecentDistance,
            remainingWeeklyBudget: remainingWeeklyBudget,
            readiness: readiness,
            weeklyStats: weeklyStats
        )
        
        let sessionType = determineSessionType(
            profile: profile,
            readiness: readiness,
            targetDistance: targetDistance,
            avgRecentDistance: avgRecentDistance,
            weeklyStats: weeklyStats
        )
        
        let explanation = buildExplanation(
            sessionType: sessionType,
            profile: profile,
            targetDistance: targetDistance,
            readiness: readiness,
            weeklyStats: weeklyStats
        )
        
        return SessionRecommendation(
            type: sessionType,
            distanceKm: targetDistance,
            explanation: explanation,
            warnings: warnings
        )
    }
    
    // MARK: - Target Distance
    
    private func calculateTargetDistance(
        profile: RunnerProfile,
        avgRecentDistance: Double,
        remainingWeeklyBudget: Double,
        readiness: Double,
        weeklyStats: WeeklyStats
    ) -> Double {
        
        let isBeginner = profile.experienceLevel == .beginner
        
        var baseDistance = avgRecentDistance
        
        let goalDistance = profile.primaryGoal.getTargetDistance(customDistance: profile.customGoalDistanceKm)
        
        if let goalDistance = goalDistance {
            let progressTowardGoal = avgRecentDistance / goalDistance
            
            if progressTowardGoal < 0.5 {
                let increment = isBeginner ? 0.3 : 0.5
                baseDistance = min(avgRecentDistance + increment, goalDistance * 0.6)
            } else if progressTowardGoal < 0.8 {
                let increment = isBeginner ? 0.5 : 0.8
                baseDistance = min(avgRecentDistance + increment, goalDistance * 0.9)
            } else {
                baseDistance = min(avgRecentDistance * 1.05, goalDistance)
            }
        } else {
            if readiness >= ReadinessThresholds.easyRun {
                let increment = isBeginner ? DistanceProgression.beginnerIncrement : DistanceProgression.normalIncrement
                baseDistance = avgRecentDistance + increment
            }
        }
        
        let readinessMultiplier: Double
        if readiness >= 80 {
            readinessMultiplier = 1.1
        } else if readiness >= ReadinessThresholds.easyRun {
            readinessMultiplier = 1.0
        } else if readiness >= ReadinessThresholds.lightActivity {
            readinessMultiplier = 0.7
        } else {
            readinessMultiplier = 0.5
        }
        
        var targetDistance = baseDistance * readinessMultiplier
        
        targetDistance = min(targetDistance, remainingWeeklyBudget)
        
        let maxSafeIncrease = avgRecentDistance * (1 + maxWeeklyIncreasePercent * 2)
        targetDistance = min(targetDistance, maxSafeIncrease)
        
        if isBeginner {
            targetDistance = min(targetDistance, max(profile.longestRunKm * 1.1, 5.0))
        }
        
        targetDistance = max(DistanceProgression.minRunDistance, targetDistance)
        
        return round(targetDistance * 10) / 10
    }
    
    // MARK: - Session Type
    
    private func determineSessionType(
        profile: RunnerProfile,
        readiness: Double,
        targetDistance: Double,
        avgRecentDistance: Double,
        weeklyStats: WeeklyStats
    ) -> SessionType {
        
        let isBeginner = profile.experienceLevel == .beginner
        
        if readiness < ReadinessThresholds.easyRun {
            return .easyRun
        }
        
        let isLongRun = targetDistance > avgRecentDistance * 1.2
        
        if isLongRun {
            return .longRun
        }
        
        if profile.primaryGoal.isRaceOrPR && readiness >= 75 && !isBeginner {
            if weeklyStats.runCount >= 2 && weeklyStats.avgDifficulty < 3.5 {
                return .tempoRun
            }
        }
        
        if readiness >= 70 {
            return .normalRun
        }
        
        return .easyRun
    }
    
    // MARK: - Explanation Builder
    
    private func buildExplanation(
        sessionType: SessionType,
        profile: RunnerProfile,
        targetDistance: Double,
        readiness: Double,
        weeklyStats: WeeklyStats
    ) -> String {
        
        let distanceStr = String(format: "%.1f", targetDistance)
        let unitStr = profile.distanceUnit == .kilometers ? "km" : "mi"
        let displayDistance = profile.distanceUnit == .miles ? targetDistance * 0.621371 : targetDistance
        let displayStr = String(format: "%.1f %@", displayDistance, unitStr)
        
        switch sessionType {
        case .easyRun:
            if let goalDistance = profile.primaryGoal.getTargetDistance(customDistance: profile.customGoalDistanceKm) {
                let progress = min(100, Int((targetDistance / goalDistance) * 100))
                return "Easy run of \(displayStr). You're \(progress)% of the way to your \(profile.primaryGoal.displayName) goal distance. Keep it conversational!"
            }
            return "Easy run of \(displayStr). Focus on keeping a comfortable pace where you can hold a conversation."
            
        case .normalRun:
            return "Normal run of \(displayStr). You're feeling good today - enjoy a solid effort at your comfortable pace."
            
        case .longRun:
            return "Long run of \(displayStr). This builds your endurance! Start slow and stay relaxed."
            
        case .tempoRun:
            return "Tempo run of \(displayStr). Push yourself to a comfortably hard pace - challenging but sustainable."
            
        case .intervals:
            return "Interval workout. Warm up, then alternate between hard efforts and recovery."
            
        case .fullRest:
            return "Rest day. Your body builds fitness during recovery!"
            
        case .strengthAndMobility:
            return "Light stretching and mobility work today. Give your legs a break."
            
        case .restWithInjuryAdvice:
            return "Rest and monitor your pain. If it persists, consider seeing a professional."
            
        case .needsMoreRuns:
            return "Complete a few more runs so we can personalize your training."
        }
    }
    
    // MARK: - Readiness Computation
    
    private func computeReadiness(
        profile: RunnerProfile,
        lastRun: RunSummary,
        today: TodayCheckIn?
    ) -> Double {
        
        let daysSinceLastRun = daysBetween(from: lastRun.date, to: Date())
        
        let difficulty = lastRun.difficultyRating
        let duration = lastRun.durationMinutes
        let pain = lastRun.painLevel

        let sessionLoad = Double(difficulty) * duration
        let painPenalty = Double(pain) * 5.0

        let restScore = Double(daysSinceLastRun) * ReadinessWeights.restDayBonus

        let expFactor: Double
        switch profile.experienceLevel {
        case .beginner:
            expFactor = ExperienceFactors.beginner
        case .intermediate:
            expFactor = ExperienceFactors.intermediate
        case .advanced:
            expFactor = ExperienceFactors.advanced
        }

        var todayModifier: Double = 0.0
        if let today = today {
            todayModifier -= Double(today.soreness) * ReadinessWeights.sorenessImpact
            todayModifier += Double(today.sleepQuality) * ReadinessWeights.sleepQualityBonus
            todayModifier -= Double(today.painNowLevel) * ReadinessWeights.painImpact
        }

        let base = 50.0

        var readiness = base
        readiness += restScore * expFactor
        readiness += todayModifier
        readiness -= sessionLoad * ReadinessWeights.sessionLoadFactor
        readiness -= painPenalty * ReadinessWeights.painPenaltyFactor

        return max(0, min(100, readiness))
    }

    // MARK: - Helpers

    private func daysBetween(from: Date, to: Date) -> Int {
        let calendar = Calendar.current
        let startOfFrom = calendar.startOfDay(for: from)
        let startOfTo = calendar.startOfDay(for: to)
        let comps = calendar.dateComponents([.day], from: startOfFrom, to: startOfTo)
        return comps.day ?? 0
    }
}
