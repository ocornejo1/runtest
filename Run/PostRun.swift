//
//  PostRun.swift
//  Run
//
//  Created by Omar Cornejo
//

import SwiftUI

struct PostRunScreen: View {
    @ObservedObject var runViewModel: RunViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var difficulty: Int = 3
    @State private var painLevel: Int = 0
    @State private var selectedPainAreas: Set<String> = []
    @State private var notes: String = ""

    private let painOptions = [
        "Shins",
        "Knees",
        "Feet",
        "Ankles",
        "Hips",
        "Lower back",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Summary
                Section(header: Text("Run Summary")) {
                    Text("Time: \(runViewModel.elapsedTimeString)")
                    Text(String(format: "Distance: %.2f meters",
                                runViewModel.totalDistance))
                }

                // MARK: - Difficulty
                Section(header: Text("How did it feel?")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Difficulty (1 = very easy, 5 = all-out)")
                            .font(.subheadline)

                        HStack {
                            ForEach(1...5, id: \.self) { value in
                                Button {
                                    difficulty = value
                                } label: {
                                    Text("\(value)")
                                        .frame(width: 32, height: 32)
                                        .background(
                                            Circle()
                                                .fill(value == difficulty ?
                                                      Color.blue :
                                                      Color.gray.opacity(0.2))
                                        )
                                        .foregroundColor(value == difficulty ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // MARK: - Pain
                Section(header: Text("Any pain or discomfort?")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overall pain (0 = none, 10 = worst)")
                            .font(.subheadline)

                        HStack(spacing: 4) {
                            ForEach(0...10, id: \.self) { value in
                                Button {
                                    painLevel = value
                                } label: {
                                    Text("\(value)")
                                        .font(.caption2)
                                        .frame(width: 24, height: 24)
                                        .background(
                                            Circle()
                                                .fill(value == painLevel ?
                                                      Color.red :
                                                      Color.gray.opacity(0.2))
                                        )
                                        .foregroundColor(value == painLevel ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.bottom, 4)

                    ForEach(painOptions, id: \.self) { option in
                        Button {
                            togglePainSelection(option)
                        } label: {
                            HStack {
                                Text(option)
                                Spacer()
                                if selectedPainAreas.contains(option) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }

                    TextField("Optional notes (e.g., \"right shin felt tight\")",
                              text: $notes,
                              axis: .vertical)
                        .lineLimit(2...4)
                }

                // MARK: - Submit
                Section {
                    Button("Submit") {
                        submit()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("After-Run Check-In")
        }
    }

    // MARK: - Helpers
    private func togglePainSelection(_ option: String) {
        if selectedPainAreas.contains(option) {
            selectedPainAreas.remove(option)
        } else {
            selectedPainAreas.insert(option)
        }
    }

    private func submit() {
        let pains = Array(selectedPainAreas)

        runViewModel.savePostRunFeedback(
            difficulty: difficulty,
            painAreas: pains,
            notes: notes,
            painLevel: painLevel
        )

        dismiss()
    }
}
