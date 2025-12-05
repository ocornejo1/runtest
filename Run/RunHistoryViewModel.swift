//
//  RunHistoryViewModel.swift
//  Run
//
//  Created by Omar Cornejo
//


import Foundation
import FirebaseFirestore
import FirebaseAuth

class RunHistoryViewModel: ObservableObject {
    @Published var runs: [RunRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func loadRuns() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.errorMessage = "No logged-in user."
            self.runs = []
            return
        }

        isLoading = true
        errorMessage = nil

        db.collection("runs")
            .whereField("userId", isEqualTo: uid)
            .order(by: "timestamp", descending: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let docs = snapshot?.documents else {
                    self.runs = []
                    return
                }

                self.runs = docs.compactMap { doc in
                    let data = doc.data()

                    guard
                        let distance = data["distance"] as? Double,
                        let duration = data["duration"] as? String,
                        let timestamp = data["timestamp"] as? Timestamp
                    else {
                        return nil
                    }

                    let restTime = data["restTime"] as? String
                    
                    let difficultyRating = data["difficultyRating"] as? Int
                    let painLevel = data["painLevel"] as? Int
                    let painAreas = data["painAreas"] as? [String]
                    let notes = data["notes"] as? String

                    return RunRecord(
                        id: doc.documentID,
                        date: timestamp.dateValue(),
                        distanceMeters: distance,
                        duration: duration,
                        restTime: restTime,
                        difficultyRating: difficultyRating,
                        painLevel: painLevel,
                        painAreas: painAreas,
                        notes: notes
                    )
                }
            }
    }
}
