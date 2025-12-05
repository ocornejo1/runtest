//
//  ProfileViewModel.swift
//  Run
//
//  Created by Omar Cornejo
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class ProfileViewModel: ObservableObject {
    @Published var profile: RunnerProfile?
    @Published var pendingSuggestedLevel: ExperienceLevel? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    // MARK: - Load / create profile
    
    func loadProfile() {
            guard let uid = Auth.auth().currentUser?.uid else {
                errorMessage = "Not logged in"
                return
            }
            
            isLoading = true
            errorMessage = nil

            db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = "Couldn't load profile. Check your connection."
                        print("Profile load error: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let data = snapshot?.data() else {
                        self.errorMessage = "Profile not found"
                        return
                    }

                    let levelRaw = data["experienceLevel"] as? String ?? ExperienceLevel.beginner.rawValue
                    let unitRaw  = data["distanceUnit"] as? String ?? DistanceUnit.kilometers.rawValue
                    let goal     = data["goalDescription"] as? String
                    let createdTs = data["createdAt"] as? Timestamp ?? Timestamp(date: Date())

                    let displayName = data["displayName"] as? String ?? "Runner"

                    let primaryGoalRaw = data["primaryGoal"] as? String ?? PrimaryGoal.none.rawValue
                    let runsPerWeek    = data["runsPerWeek"] as? Int ?? 3
                    let longestRunKm   = data["longestRunKm"] as? Double ?? 0.0
                    let typicalWeeklyKm = data["typicalWeeklyKm"] as? Double ?? 0.0
                    let firstRunDate   = (data["firstRunDate"] as? Timestamp)?.dateValue()
                    let firstRunDistanceKm = data["firstRunDistanceKm"] as? Double
                    let customGoalDistanceKm = data["customGoalDistanceKm"] as? Double
                    
                    let level = ExperienceLevel(rawValue: levelRaw) ?? .beginner
                    let unit  = DistanceUnit(rawValue: unitRaw) ?? .kilometers
                    let primaryGoal = PrimaryGoal(rawValue: primaryGoalRaw) ?? .none

                    let profile = RunnerProfile(
                        uid: uid,
                        displayName: displayName,
                        experienceLevel: level,
                        distanceUnit: unit,
                        createdAt: createdTs.dateValue(),
                        primaryGoal: primaryGoal,
                        runsPerWeek: runsPerWeek,
                        longestRunKm: longestRunKm,
                        typicalWeeklyKm: typicalWeeklyKm,
                        goalDescription: goal,
                        firstRunDate: firstRunDate,
                        firstRunDistanceKm: firstRunDistanceKm,
                        customGoalDistanceKm: customGoalDistanceKm
                    )

                    self.profile = profile
                }
            }
        }
        
        func saveProfile(_ profile: RunnerProfile) {
            guard let uid = Auth.auth().currentUser?.uid else { return }

            var docData: [String: Any] = [
                "experienceLevel": profile.experienceLevel.rawValue,
                "distanceUnit": profile.distanceUnit.rawValue,
                "createdAt": Timestamp(date: profile.createdAt)
            ]

            if let goal = profile.goalDescription {
                docData["goalDescription"] = goal
            }
            
            if let customGoal = profile.customGoalDistanceKm {
                docData["customGoalDistanceKm"] = customGoal
            }

            db.collection("users").document(uid).setData(docData, merge: true) { [weak self] error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.errorMessage = "Couldn't save profile. Try again."
                    }
                    print("Profile save error: \(error.localizedDescription)")
                }
            }
        }

        // MARK: - Manual updates from Settings
        
        func updatePrimaryGoal(_ goal: PrimaryGoal) {
            guard var profile = profile else { return }
            profile.primaryGoal = goal
            self.profile = profile
            saveProfile(profile)
        }
        
        func updateExperienceLevel(_ level: ExperienceLevel) {
            guard var profile = profile else { return }
            profile.experienceLevel = level
            self.profile = profile
            saveProfile(profile)
        }

        func updateDistanceUnit(_ unit: DistanceUnit) {
            guard var profile = profile else { return }
            profile.distanceUnit = unit
            self.profile = profile
            saveProfile(profile)
        }

        func updateGoalDescription(_ goal: String?) {
            guard var profile = profile else { return }
            profile.goalDescription = goal?.trimmingCharacters(in: .whitespacesAndNewlines)
            self.profile = profile
            saveProfile(profile)
        }
    
        func updateCustomGoalDistance(_ distanceKm: Double?){
            guard var profile = profile else { return }
            profile.customGoalDistanceKm = distanceKm
            self.profile = profile
            saveProfile(profile)
        }
        // MARK: - Auto-upgrade suggestion (Beginner → Intermediate)

        func checkForAutoUpgrade(with runs: [RunSummary]) {
            guard let profile = profile else { return }

            guard profile.experienceLevel == .beginner else { return }
            guard runs.count >= 5 else { return }

            let sorted = runs.sorted { $0.date < $1.date }
            guard let first = sorted.first, let last = sorted.last else { return }

            let calendar = Calendar.current
            let daysBetween = calendar.dateComponents([.day], from: first.date, to: last.date).day ?? 0

            guard daysBetween >= 60 else { return }

            let firstDistance = first.distanceKm
            let lastDistance = last.distanceKm
            guard firstDistance > 0 else { return }
            guard lastDistance >= firstDistance * 2.5 else { return }

            pendingSuggestedLevel = .intermediate
        }

        func acceptSuggestedLevel() {
            guard let suggested = pendingSuggestedLevel else { return }
            updateExperienceLevel(suggested)
            pendingSuggestedLevel = nil
        }

        func dismissSuggestedLevel() {
            pendingSuggestedLevel = nil
        }
    }
        
