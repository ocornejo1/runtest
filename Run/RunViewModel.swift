//
//  RunViewModel.swift
//  Run
//
//  Created by Omar Cornejo on
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

@MainActor
class RunViewModel: NSObject, ObservableObject {
    // MARK: - Location Manager
    private let locationManager = CLLocationManager()

    @Published var lastLocation: CLLocation?
    @Published var totalDistance: Double = 0.0
    @Published var elapsedTimeString: String = "00:00"
    @Published var isRunning = false
    @Published var isPaused = false
    @Published var restTimeString: String = "00:00"
    @Published var lastRunDocumentId: String? = nil
    @Published var showDiscardConfirmation = false
    @Published var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @Published var currentPace: Pace?
    
    var locationAuthStatus: CLAuthorizationStatus {
        locationManager.authorizationStatus
    }
    
    @Published var showLocationPermissionAlert = false
    @Published var errorMessage: String?
    @Published var showError = false

    private var timer: Timer?
    private var restTimer: Timer?
    private var startTime: Date?
    private var restStartTime: Date?

    // MARK: - Init

    override init() {
        super.init()

        // Prevent crash in previews
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            setupLocationManager()
        }
    }

    // MARK: - Location manager setup

    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        
        // 🔹 FIXED: Added 'if' keyword
        if locationAuthStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    // MARK: - Public controls called by views

    func toggleRun() {
        if isRunning {
            stopRun(saveRun: true)
        } else {
            startRun()
        }
    }

    func togglePause() {
        isPaused.toggle()

        if isPaused {
            pauseRun()
        } else {
            resumeRun()
        }
    }

    func endRunAndSave() {
        stopRun(saveRun: true)
    }

    func requestDiscard() {
        showDiscardConfirmation = true
    }
    
    func confirmDiscard() {
        stopRun(saveRun: false)
        showDiscardConfirmation = false
    }

    // MARK: - Run lifecycle

    func startRun() {
        guard locationAuthStatus == .authorizedWhenInUse || locationAuthStatus == .authorizedAlways else {
            showLocationPermissionAlert = true
            return
        }
        
        totalDistance = 0.0
        lastLocation = nil
        elapsedTimeString = "00:00"
        restTimeString = "00:00"
        isPaused = false
        startTime = Date()
        lastRunDocumentId = nil
        errorMessage = nil
        currentPace = nil

        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            locationManager.startUpdatingLocation()
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateElapsedTime() }
        }

        isRunning = true
    }

    func stopRun(saveRun: Bool = true) {
        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        restTimer?.invalidate()
        timer = nil
        restTimer = nil
        isRunning = false
        isPaused = false

        if saveRun {
            saveRunToFirestore()
        }
    }

    private func pauseRun() {
        guard isRunning, !isPaused else { return }

        locationManager.stopUpdatingLocation()
        restStartTime = Date()

        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.updateRestTime() }
        }
    }

    private func resumeRun() {
        guard isRunning, isPaused else { return }

        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
            locationManager.startUpdatingLocation()
        }

        restTimer?.invalidate()
        restTimer = nil
        restStartTime = nil
    }

    // MARK: - Timers

    private func updateElapsedTime() {
        guard let start = startTime else { return }
        let elapsed = Int(Date().timeIntervalSince(start))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        elapsedTimeString = String(format: "%02d:%02d", minutes, seconds)
        
        if totalDistance > 0 {
            currentPace = Pace(distanceMeters: totalDistance, durationSeconds: TimeInterval(elapsed))
        }
    }

    private func updateRestTime() {
        guard let restStart = restStartTime else { return }
        let restElapsed = Int(Date().timeIntervalSince(restStart))
        let minutes = restElapsed / 60
        let seconds = restElapsed % 60
        restTimeString = String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: - Firestore: run save + feedback

    private func saveRunToFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "Not logged in. Sign in and try again."
            showError = true
            return
        }

        let db = Firestore.firestore()
        let runData: [String: Any] = [
            "userId": userId,
            "distance": totalDistance,
            "duration": elapsedTimeString,
            "restTime": restTimeString,
            "timestamp": Timestamp(date: Date())
        ]

        let docRef = db.collection("runs").document()
        lastRunDocumentId = docRef.documentID

        docRef.setData(runData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                let friendlyError = self.userFriendlyError(from: error)
                Task { @MainActor in
                    self.errorMessage = friendlyError
                    self.showError = true
                }
                print("Error saving run: \(error.localizedDescription)")
            } else {
                print("Run saved successfully")
            }
        }
    }

    func savePostRunFeedback(
        difficulty: Int,
        painAreas: [String],
        notes: String?,
        painLevel: Int
    ) {
        guard let runId = lastRunDocumentId else {
            errorMessage = "Cannot save feedback - run data not found."
            showError = true
            return
        }

        let db = Firestore.firestore()
        var update: [String: Any] = [
            "difficultyRating": difficulty,
            "painAreas": painAreas,
            "painLevel": painLevel,
            "feedbackTimestamp": Timestamp(date: Date())
        ]

        if let notes = notes,
           !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            update["feedbackNotes"] = notes
        }

        db.collection("runs").document(runId).updateData(update) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                let friendlyError = self.userFriendlyError(from: error)
                Task { @MainActor in
                    self.errorMessage = friendlyError
                    self.showError = true
                }
                print("Error saving post-run feedback: \(error.localizedDescription)")
            } else {
                print("Post-run feedback saved.")
            }
        }
    }
    
    private func userFriendlyError(from error: Error) -> String {
        let nsError = error as NSError
        
        switch nsError.code {
        case 7:
            return "You don't have permission to save this data. Try signing in again."
        case 14:
            return "The request timed out. Check your internet connection and try again."
        case 8:
            return "Too many requests. Please wait a moment and try again."
        default:
            return "Something went wrong saving your run. Please try again."
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension RunViewModel: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        Task { @MainActor in
            if let last = self.lastLocation, !self.isPaused {
                let distance = newLocation.distance(from: last)
                self.totalDistance += distance
            }
            
            self.lastLocation = newLocation
            self.cameraPosition = .userLocation(fallback: .automatic)
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        Task { @MainActor in
            switch status {
            case .denied, .restricted:
                if self.isRunning {
                    self.errorMessage = "Location access was denied. Your run has been paused."
                    self.showError = true
                    self.pauseRun()
                }
                self.showLocationPermissionAlert = true
                
            case .authorizedWhenInUse, .authorizedAlways:
                self.showLocationPermissionAlert = false
                
            case .notDetermined:
                break
                
            @unknown default:
                break
            }
        }
    }
}
