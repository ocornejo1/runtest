//
//  SettingsScreen.swift
//  Run
//
//  Created by Omar Cornejo
//

import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var authVM: AuthViewModel

    @State private var selectedLevel: ExperienceLevel = .beginner
    @State private var selectedUnit: DistanceUnit = .kilometers
    @State private var goalText: String = ""
    @State private var selectedPrimaryGoal: PrimaryGoal = .none

    var body: some View {
        Form {
            Section(header: Text("Account")) {
                if let user = authVM.user {
                    Text("Logged in as: \(user.email ?? "")")
                        .font(.subheadline)
                }
                Button(role: .destructive) {
                    authVM.signOut()
                } label: {
                    Text("Sign Out")
                }
            }

            Section(header: Text("Experience Level")) {
                Picker("Level", selection: $selectedLevel) {
                    ForEach(ExperienceLevel.allCases) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)

                Text("Your level controls how aggressive training recommendations are.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Distance Units")) {
                Picker("Unit", selection: $selectedUnit) {
                    ForEach(DistanceUnit.allCases) { unit in
                        Text(unit.displayName).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(header: Text("Goal")) {
                TextField("e.g. Run a 5k, 3 runs per week", text: $goalText)
                Text("RunRight can use this to guide recommendations and show progress against your goal.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Button("Save Preferences") {
                    profileVM.updateExperienceLevel(selectedLevel)
                    profileVM.updateDistanceUnit(selectedUnit)
                    profileVM.updatePrimaryGoal(selectedPrimaryGoal)
                    profileVM.updateGoalDescription(goalText)
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            if let profile = profileVM.profile {
                selectedLevel = profile.experienceLevel
                selectedUnit = profile.distanceUnit
                selectedPrimaryGoal = profile.primaryGoal
                goalText = profile.goalDescription ?? ""
            }
        }
    }
}
