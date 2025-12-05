//
//  OnboardingSurveyScreen.swift
//  Run
//
//  Created by Omar Cornejo
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct OnboardingSurveyScreen: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @AppStorage("useMiles") private var useMiles = true

    @State private var displayName = ""
    @State private var selectedLevel: ExperienceLevel = .beginner
    @State private var selectedPrimaryGoal: PrimaryGoal = .none
    @State private var personalBestDistance = ""
    @State private var runsPerWeek: Double = 3
    @State private var longestDistanceText = ""
    @State private var weeklyDistanceText = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var nameError: String?
    @State private var distanceError: String?

    private var currentUnit: DistanceUnit {
        useMiles ? .miles : .kilometers
    }

    private var unitLabel: String {
        currentUnit == .kilometers ? "km" : "mi"
    }

    private var isFormValid: Bool {
        guard ValidationUtilities.validateDisplayName(displayName) != nil else {
            return false
        }

        if !longestDistanceText.isEmpty {
            guard ValidationUtilities.validateDistance(longestDistanceText, unit: currentUnit) != nil else {
                return false
            }
        }

        if !weeklyDistanceText.isEmpty {
            guard ValidationUtilities.validateWeeklyVolume(weeklyDistanceText, unit: currentUnit) != nil else {
                return false
            }
        }

        if selectedPrimaryGoal == .personalBest {
            guard !personalBestDistance.isEmpty,
                  ValidationUtilities.validateDistance(personalBestDistance, unit: currentUnit) != nil else {
                return false
            }
        }

        return true
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Basic Info
                
                Section(header: Text("Basic Info")) {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Display name", text: $displayName)
                            .autocapitalization(.words)
                            .onChange(of: displayName) { _, newValue in
                                validateName(newValue)
                            }

                        if let error = nameError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Running experience")
                        Picker("", selection: $selectedLevel) {
                            Text("Beginner").tag(ExperienceLevel.beginner)
                            Text("Intermediate").tag(ExperienceLevel.intermediate)
                            Text("Advanced").tag(ExperienceLevel.advanced)
                        }
                        .pickerStyle(.segmented)

                        Text(helpTextForLevel(selectedLevel))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: - Goals
                
                Section(header: Text("Your Goals")) {
                    PrimaryGoalSelector(
                        selectedPrimaryGoal: $selectedPrimaryGoal,
                        personalBestDistance: $personalBestDistance,
                        unit: currentUnit
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("How many days per week would you like to run?")
                        Slider(value: $runsPerWeek, in: 1...7, step: 1) {
                            Text("Runs per week")
                        } minimumValueLabel: {
                            Text("1")
                        } maximumValueLabel: {
                            Text("7")
                        }
                        Text("\(Int(runsPerWeek)) days per week")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // MARK: - Distance History
                
                Section(header: Text("Recent Running")) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Longest recent run")
                            Spacer()
                            TextField("0", text: $longestDistanceText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                                .onChange(of: longestDistanceText) { _, _ in
                                    validateDistances()
                                }
                            Text(unitLabel)
                                .foregroundColor(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Typical weekly distance")
                            Spacer()
                            TextField("0", text: $weeklyDistanceText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                                .onChange(of: weeklyDistanceText) { _, _ in
                                    validateDistances()
                                }
                            Text(unitLabel)
                                .foregroundColor(.secondary)
                        }

                        if let error = distanceError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    Text("If you're brand new, you can leave these as 0. They help RunRight scale your early recommendations.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                // MARK: - Preferences
                
                Section(header: Text("Units")) {
                    Picker("Preferred units", selection: $useMiles) {
                        Text("Kilometers").tag(false)
                        Text("Miles").tag(true)
                    }
                    .pickerStyle(.segmented)

                    Text("This unit is used for your goals, distances, and history.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                // MARK: - Errors
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                // MARK: - Submit
                
                Section {
                    Button {
                        submitSurvey()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save Profile and Continue")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSaving || !isFormValid)
                }
            }
            .navigationTitle("Tell Us About You")
        }
    }

    // MARK: - Validation
    
    private func validateName(_ name: String) {
        if name.isEmpty {
            nameError = nil
            return
        }

        if ValidationUtilities.validateDisplayName(name) == nil {
            nameError = "Name must be 1-50 characters"
        } else {
            nameError = nil
        }
    }

    private func validateDistances() {
        var errors: [String] = []

        if !longestDistanceText.isEmpty {
            if ValidationUtilities.validateDistance(longestDistanceText, unit: currentUnit) == nil {
                errors.append("Longest run must be a valid distance")
            }
        }

        if !weeklyDistanceText.isEmpty {
            if ValidationUtilities.validateWeeklyVolume(weeklyDistanceText, unit: currentUnit) == nil {
                errors.append("Weekly distance must be reasonable (max \(Int(SafetyThresholds.maxReasonableWeeklyKm)) km)")
            }
        }

        if !longestDistanceText.isEmpty && !weeklyDistanceText.isEmpty {
            if let longest = ValidationUtilities.validateDistance(longestDistanceText, unit: currentUnit),
               let weekly = ValidationUtilities.validateDistance(weeklyDistanceText, unit: currentUnit) {
                if weekly < longest {
                    errors.append("Weekly distance should be at least your longest run")
                }
            }
        }

        distanceError = errors.isEmpty ? nil : errors.joined(separator: ". ")
    }

    // MARK: - Save
    
    private func submitSurvey() {
        guard let user = authViewModel.user else { return }

        guard let validName = ValidationUtilities.validateDisplayName(displayName) else {
            errorMessage = "Please enter a valid display name"
            return
        }

        isSaving = true
        errorMessage = nil

        let db = Firestore.firestore()
        let uid = user.uid
        let docRef = db.collection("users").document(uid)

        let longestRunKm: Double
        if longestDistanceText.isEmpty {
            longestRunKm = 0
        } else if let validated = ValidationUtilities.validateDistance(longestDistanceText, unit: currentUnit) {
            longestRunKm = validated
        } else {
            errorMessage = "Invalid longest run distance"
            isSaving = false
            return
        }

        let typicalWeeklyKm: Double
        if weeklyDistanceText.isEmpty {
            typicalWeeklyKm = 0
        } else if let validated = ValidationUtilities.validateWeeklyVolume(weeklyDistanceText, unit: currentUnit) {
            typicalWeeklyKm = validated
        } else {
            errorMessage = "Invalid weekly distance"
            isSaving = false
            return
        }

        let customGoalDistanceKm: Double?
        if selectedPrimaryGoal == .personalBest {
            if let validated = ValidationUtilities.validateDistance(personalBestDistance, unit: currentUnit) {
                customGoalDistanceKm = validated
            } else {
                errorMessage = "Invalid goal distance"
                isSaving = false
                return
            }
        } else {
            customGoalDistanceKm = nil
        }

        let runsPerWeekInt = Int(runsPerWeek.rounded())

        let goalDescription = makeGoalDescription(
            primaryGoal: selectedPrimaryGoal,
            distanceText: personalBestDistance,
            unit: currentUnit
        )

        var data: [String: Any] = [
            "uid": uid,
            "email": user.email ?? "",
            "displayName": validName,
            "experienceLevel": selectedLevel.rawValue,
            "distanceUnit": currentUnit.rawValue,
            "primaryGoal": selectedPrimaryGoal.rawValue,
            "goalDescription": goalDescription,
            "runsPerWeek": runsPerWeekInt,
            "completedOnboarding": true,
            "createdAt": FieldValue.serverTimestamp()
        ]

        if longestRunKm > 0 {
            data["longestRunKm"] = longestRunKm
        }
        if typicalWeeklyKm > 0 {
            data["typicalWeeklyKm"] = typicalWeeklyKm
        }
        if let customGoal = customGoalDistanceKm {
            data["customGoalDistanceKm"] = customGoal
        }

        docRef.setData(data, merge: true) { error in
            DispatchQueue.main.async {
                self.isSaving = false

                if let error = error {
                    self.errorMessage = self.userFriendlyError(from: error)
                } else {
                    self.authViewModel.markProfileCompleted()
                }
            }
        }
    }

    // MARK: - Helpers
    
    private func helpTextForLevel(_ level: ExperienceLevel) -> String {
        switch level {
        case .beginner:
            return "You're new to running or coming back after a long break."
        case .intermediate:
            return "You run semi-regularly and are comfortable with easy runs."
        case .advanced:
            return "You train consistently and may follow structured plans."
        }
    }

    private func makeGoalDescription(
        primaryGoal: PrimaryGoal,
        distanceText: String,
        unit: DistanceUnit
    ) -> String {
        switch primaryGoal {
        case .none:
            return "No specific goal"
        case .generalFitness:
            return "Improve general fitness"
        case .weightLoss:
            return "Weight loss through consistent running"
        case .race5k:
            return "Prepare to run a 5K"
        case .race10k:
            return "Prepare to run a 10K"
        case .raceHalfMarathon:
            return "Prepare for a half marathon"
        case .raceMarathon:
            return "Prepare for a marathon"
        case .personalBest:
            if let value = ValidationUtilities.validateDistance(distanceText, unit: unit) {
                let displayValue = unit == .kilometers ? value : value * 0.621371
                let unitLabel = unit == .kilometers ? "km" : "mi"
                return String(format: "Set a new personal best over %.1f %@", displayValue, unitLabel)
            } else {
                return "Set a new personal-best distance"
            }
        }
    }

    private func userFriendlyError(from error: Error) -> String {
        let nsError = error as NSError
        switch nsError.code {
        case 7:
            return "Permission denied. Please sign in again."
        case 14:
            return "Request timed out. Check your connection."
        default:
            return "Couldn't save your profile. Please try again."
        }
    }
}
