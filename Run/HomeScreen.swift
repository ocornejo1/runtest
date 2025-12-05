//
//  HomeScreen.swift
//  Run
//
//  Created by Omar Cornejo
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct HomeScreen: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    
    @State private var recentRuns: [RunSummary] = []
    @State private var todayCheckIn: TodayCheckIn? = nil

    private let engine = RecommendationEngine()
    
    @State private var isLoadingRuns = false
    @State private var isLoadingCheckInStatus = true
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showDailyCheckIn = false

    var body: some View {
        NavigationStack {
            if profileVM.isLoading || isLoadingRuns || isLoadingCheckInStatus {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading your training data...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        loadAllData()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else {
                mainContent
            }
        }
        .onAppear {
            loadAllData()
        }
        .sheet(isPresented: Binding(
            get: { showDailyCheckIn && !isLoadingCheckInStatus },
            set: { showDailyCheckIn = $0 }
        )) {
            DailyCheckInScreen { checkIn in
                self.todayCheckIn = checkIn

                guard let uid = Auth.auth().currentUser?.uid else { return }
                let db = Firestore.firestore()

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                let todayKey = formatter.string(from: Date())

                db.collection("users").document(uid).setData(
                    ["lastCheckInDate": todayKey],
                    merge: true
                )

                self.showDailyCheckIn = false
            }
        }
        .alert("Level Up?", isPresented: Binding(
            get: { profileVM.pendingSuggestedLevel != nil },
            set: { newValue in
                if !newValue { profileVM.dismissSuggestedLevel() }
            }
        )) {
            Button("Not now", role: .cancel) {
                profileVM.dismissSuggestedLevel()
            }
            Button("Upgrade") {
                profileVM.acceptSuggestedLevel()
            }
        } message: {
            if let suggested = profileVM.pendingSuggestedLevel {
                Text("You've been consistent for a while and your long runs have improved a lot. Do you want to switch to \(suggested.displayName) training?")
            } else {
                Text("")
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 24) {
            HStack {
                VStack(alignment: .leading) {
                    Text("RunRight")
                        .font(.largeTitle)
                        .bold()
                    if let level = profileVM.profile?.experienceLevel {
                        Text("\(level.displayName) runner")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "figure.run")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.blue)
            }
            .padding(.top, 24)

            if let profile = profileVM.profile {
                let rec = engine.nextSession(
                    for: profile,
                    recentRuns: recentRuns,
                    today: todayCheckIn
                )

                RecommendationCard(
                    recommendation: rec,
                    unit: profile.distanceUnit
                )

                WeeklySummaryCard(
                    recentRuns: recentRuns,
                    unit: profile.distanceUnit
                )
            } else {
                Text("Loading your profile…")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let profile = profileVM.profile,
               profile.experienceLevel == .beginner {
                let progress = consistencyProgress(for: recentRuns, weeksRequired: 8)

                LevelProgressCard(
                    progress: progress,
                    goalDescription: profile.goalDescription
                )
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Data Loading
    
    private func loadAllData() {
        errorMessage = nil
        profileVM.loadProfile()
        loadRecentRuns()
        loadDailyCheckInStatus()
    }

    // MARK: - Daily Check-In

    private func loadDailyCheckInStatus() {
        guard let uid = Auth.auth().currentUser?.uid else {
            showDailyCheckIn = false
            isLoadingCheckInStatus = false
            return
        }

        isLoadingCheckInStatus = true

        let db = Firestore.firestore()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayKey = formatter.string(from: Date())

        db.collection("users").document(uid).getDocument { snapshot, error in
            defer {
                DispatchQueue.main.async {
                    self.isLoadingCheckInStatus = false
                }
            }

            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Couldn't load check-in status. Check your connection."
                    self.showError = true
                    self.showDailyCheckIn = true
                }
                print("Check-in load error: \(error.localizedDescription)")
                return
            }
            
            guard let data = snapshot?.data() else {
                DispatchQueue.main.async {
                    self.showDailyCheckIn = true
                }
                return
            }

            let lastCheckInDate = data["lastCheckInDate"] as? String ?? ""
            
            DispatchQueue.main.async {
                self.showDailyCheckIn = (lastCheckInDate != todayKey)
            }
        }
    }

    // MARK: - Load Runs

    private func loadRecentRuns() {
        guard let uid = Auth.auth().currentUser?.uid else {
            errorMessage = "Not logged in"
            return
        }
        
        let db = Firestore.firestore()
        isLoadingRuns = true

        db.collection("runs")
            .whereField("userId", isEqualTo: uid)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    self.isLoadingRuns = false
                    
                    if let error = error {
                        self.errorMessage = "Couldn't load your runs. Check your connection."
                        self.showError = true
                        print("Runs load error: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let docs = snapshot?.documents else {
                        self.recentRuns = []
                        return
                    }

                    let mapped: [RunSummary] = docs.compactMap { doc in
                        let data = doc.data()

                        guard
                            let ts = data["timestamp"] as? Timestamp,
                            let distance = data["distance"] as? Double,
                            let durationString = data["duration"] as? String
                        else {
                            return nil
                        }

                        let difficulty = data["difficultyRating"] as? Int ?? 3
                        let painLevel = data["painLevel"] as? Int ?? 0
                        let painAreas = data["painAreas"] as? [String] ?? []

                        let date = ts.dateValue()
                        let minutes = parseDurationToMinutes(durationString)

                        return RunSummary(
                            date: date,
                            durationMinutes: minutes,
                            distanceKm: distance / 1000.0,
                            difficultyRating: difficulty,
                            painLevel: painLevel,
                            painAreas: painAreas
                        )
                    }

                    self.recentRuns = mapped
                    self.profileVM.checkForAutoUpgrade(with: mapped)
                }
            }
    }
    
    // MARK: - Helpers
    
    private func parseDurationToMinutes(_ s: String) -> Double {
        let parts = s.split(separator: ":").map { String($0) }
        guard parts.count == 2,
              let m = Double(parts[0]),
              let sec = Double(parts[1]) else {
            return 0
        }
        return m + sec / 60.0
    }
    
    private func consistencyProgress(for runs: [RunSummary], weeksRequired: Int) -> LevelProgress {
        guard !runs.isEmpty else {
            return LevelProgress(requiredWeeks: weeksRequired, completedWeeks: 0)
        }

        let calendar = Calendar.current
        let now = Date()
        guard let startWindow = calendar.date(byAdding: .weekOfYear, value: -weeksRequired + 1, to: now) else {
            return LevelProgress(requiredWeeks: weeksRequired, completedWeeks: 0)
        }

        let recent = runs.filter { $0.date >= startWindow && $0.date <= now }

        let weekIds: Set<String> = Set(recent.map { run in
            let comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: run.date)
            return "\(comps.yearForWeekOfYear ?? 0)-W\(comps.weekOfYear ?? 0)"
        })

        let completed = min(weekIds.count, weeksRequired)
        return LevelProgress(requiredWeeks: weeksRequired, completedWeeks: completed)
    }
}

// MARK: - Level Progress

struct LevelProgress {
    let requiredWeeks: Int
    let completedWeeks: Int

    var progressFraction: Double {
        guard requiredWeeks > 0 else { return 0 }
        return min(Double(completedWeeks) / Double(requiredWeeks), 1.0)
    }
}

// MARK: - Level Progress Card

struct LevelProgressCard: View {
    let progress: LevelProgress
    let goalDescription: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Progress toward Intermediate")
                .font(.headline)

            Text("Weeks with at least one run: \(progress.completedWeeks) / \(progress.requiredWeeks)")
                .font(.subheadline)

            ProgressView(value: progress.progressFraction)
                .tint(.blue)

            if let goal = goalDescription, !goal.isEmpty {
                Text("Your goal: \(goal)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Set a goal in Settings to track your progress more clearly.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Dashboard Button

struct DashboardButton: View {
    let label: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
            Text(label)
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .cornerRadius(12)
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: SessionRecommendation
    let unit: DistanceUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: iconForType(recommendation.type))
                    .font(.title2)
                    .foregroundColor(colorForType(recommendation.type))
                
                Text(titleForType(recommendation.type))
                    .font(.headline)
            }

            Text(recommendation.explanation)
                .font(.subheadline)
            
            if let distance = recommendation.distanceKm, distance > 0 {
                HStack {
                    Image(systemName: "figure.run")
                    Text("Target: \(formatDistance(distance))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
            }
            
            if !recommendation.warnings.isEmpty {
                ForEach(recommendation.warnings, id: \.self) { warning in
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(warning)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundForType(recommendation.type))
        .cornerRadius(12)
    }
    
    private func formatDistance(_ km: Double) -> String {
        switch unit {
        case .kilometers:
            return String(format: "%.1f km", km)
        case .miles:
            let miles = km * 0.621371
            return String(format: "%.1f mi", miles)
        }
    }
    
    private func titleForType(_ type: SessionType) -> String {
        switch type {
        case .fullRest:
            return "Rest Day"
        case .easyRun:
            return "Easy Run"
        case .normalRun:
            return "Normal Run"
        case .longRun:
            return "Long Run"
        case .tempoRun:
            return "Tempo Run"
        case .intervals:
            return "Intervals"
        case .strengthAndMobility:
            return "Strength & Mobility"
        case .restWithInjuryAdvice:
            return "Rest - Listen to Your Body"
        case .needsMoreRuns:
            return "Building Your Baseline"
        }
    }
    
    private func iconForType(_ type: SessionType) -> String {
        switch type {
        case .fullRest:
            return "bed.double.fill"
        case .easyRun:
            return "figure.walk"
        case .normalRun:
            return "figure.run"
        case .longRun:
            return "figure.run.circle"
        case .tempoRun:
            return "speedometer"
        case .intervals:
            return "bolt.fill"
        case .strengthAndMobility:
            return "figure.flexibility"
        case .restWithInjuryAdvice:
            return "cross.fill"
        case .needsMoreRuns:
            return "chart.line.uptrend.xyaxis"
        }
    }
    
    private func colorForType(_ type: SessionType) -> Color {
        switch type {
        case .fullRest, .restWithInjuryAdvice:
            return .purple
        case .easyRun:
            return .green
        case .normalRun:
            return .blue
        case .longRun:
            return .orange
        case .tempoRun, .intervals:
            return .red
        case .strengthAndMobility:
            return .teal
        case .needsMoreRuns:
            return .blue
        }
    }
    
    private func backgroundForType(_ type: SessionType) -> Color {
        switch type {
        case .fullRest, .restWithInjuryAdvice:
            return Color.purple.opacity(0.1)
        case .easyRun:
            return Color.green.opacity(0.1)
        case .normalRun:
            return Color.blue.opacity(0.1)
        case .longRun:
            return Color.orange.opacity(0.1)
        case .tempoRun, .intervals:
            return Color.red.opacity(0.1)
        case .strengthAndMobility:
            return Color.teal.opacity(0.1)
        case .needsMoreRuns:
            return Color.blue.opacity(0.1)
        }
    }
}

