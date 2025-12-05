//
//  PrimaryGoalSelector.swift
//  Run
//
//  Created by Omar Cornejo
//


import SwiftUI

struct PrimaryGoalSelector: View {
    @Binding var selectedPrimaryGoal: PrimaryGoal
    @Binding var personalBestDistance: String
    let unit: DistanceUnit

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goal")
                .font(.headline)

            Picker("Goal", selection: $selectedPrimaryGoal) {
                Text("No specific goal").tag(PrimaryGoal.none)
                Text("General fitness").tag(PrimaryGoal.generalFitness)
                Text("Weight loss").tag(PrimaryGoal.weightLoss)
                Text("Run a 5K").tag(PrimaryGoal.race5k)
                Text("Run a 10K").tag(PrimaryGoal.race10k)
                Text("Half marathon").tag(PrimaryGoal.raceHalfMarathon)
                Text("Marathon").tag(PrimaryGoal.raceMarathon)
                Text("Personal-best distance…").tag(PrimaryGoal.personalBest)
            }
            .pickerStyle(.menu)

            if selectedPrimaryGoal == .personalBest {
                HStack {
                    TextField("Distance", text: $personalBestDistance)
                        .keyboardType(.decimalPad)

                    Text(unit == .kilometers ? "km" : "mi")
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

                Text("Enter the distance where you want to set a new personal best.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Text("RunRight uses this goal to guide training recommendations and track your progress.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
}
