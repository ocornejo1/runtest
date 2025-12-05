//
//  DailyCheckInScreen.swift
//  Run
//
//  Created by Omar Cornejo
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct DailyCheckInScreen: View {
    let onCompleted: (TodayCheckIn) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var soreness: Double = 3
    @State private var sleepQuality: Int = 3
    @State private var painNowLevel: Double = 0
    @State private var selectedPainAreas: Set<String> = []

    @State private var isSaving = false
    @State private var errorMessage: String?

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
                Section(header: Text("How do you feel today?")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overall soreness (0 = none, 10 = very sore)")
                        Slider(value: $soreness, in: 0...10, step: 1)
                        Text("\(Int(soreness)) / 10")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sleep quality last night (1–5)")
                        HStack {
                            ForEach(1...5, id: \.self) { value in
                                Button {
                                    sleepQuality = value
                                } label: {
                                    Text("\(value)")
                                        .frame(width: 32, height: 32)
                                        .background(
                                            Circle()
                                                .fill(value == sleepQuality ?
                                                      Color.blue :
                                                      Color.gray.opacity(0.2))
                                        )
                                        .foregroundColor(value == sleepQuality ? .white : .primary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Text("1 = terrible, 5 = excellent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("Pain right now")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overall pain (0 = none, 10 = worst)")
                        Slider(value: $painNowLevel, in: 0...10, step: 1)
                        Text("\(Int(painNowLevel)) / 10")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

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
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button {
                        submit()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save Today’s Check-In")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSaving)
                }
            }
            .navigationTitle("Daily Check-In")
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
        guard let uid = Auth.auth().currentUser?.uid else { return }

        isSaving = true
        errorMessage = nil

        let todayCheckIn = TodayCheckIn(
            soreness: Int(soreness),
            sleepQuality: sleepQuality,
            painNowLevel: Int(painNowLevel),
            painNowAreas: Array(selectedPainAreas)
        )

        let db = Firestore.firestore()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dayKey = formatter.string(from: Date())

        let docId = "\(uid)_\(dayKey)"
        let data: [String: Any] = [
            "uid": uid,
            "dateKey": dayKey,
            "soreness": todayCheckIn.soreness,
            "sleepQuality": todayCheckIn.sleepQuality,
            "painNowLevel": todayCheckIn.painNowLevel,
            "painNowAreas": todayCheckIn.painNowAreas,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("dailyCheckins").document(docId).setData(data, merge: true) { error in
            DispatchQueue.main.async {
                self.isSaving = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                } else {
                    self.onCompleted(todayCheckIn)
                    self.dismiss()
                }
            }
        }
    }
}
