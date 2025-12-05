//
//  MapScreen.swift
//  Run
//
//  Created by Omar Cornejo
//

import SwiftUI
import MapKit

struct MapScreen: View {
    @StateObject private var viewModel = RunViewModel()
    @EnvironmentObject var profileVM: ProfileViewModel
    @State private var showPostRun = false

    var body: some View {
        VStack(spacing: 16) {
            Map(position: $viewModel.cameraPosition) {
            }
            .edgesIgnoringSafeArea(.top)
            .frame(height: 400)

            // MARK: - Run Stats
            VStack(spacing: 12) {
                HStack(spacing: 30) {
                    VStack {
                        Text("TIME")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.elapsedTimeString)
                            .font(.title2)
                            .bold()
                    }
                    
                    // Distance
                    VStack {
                        Text("DISTANCE")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let unit = profileVM.profile?.distanceUnit {
                            Text(formatDistance(viewModel.totalDistance, unit: unit))
                                .font(.title2)
                                .bold()
                        } else {
                            Text(String(format: "%.2f m", viewModel.totalDistance))
                                .font(.title2)
                                .bold()
                        }
                    }
                    
                    VStack {
                        Text("PACE")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let pace = viewModel.currentPace,
                           let unit = profileVM.profile?.distanceUnit {
                            Text(pace.formattedWithoutUnit(for: unit))
                                .font(.title2)
                                .bold()
                            Text(unit == .kilometers ? "/km" : "/mi")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("--:--")
                                .font(.title2)
                                .bold()
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                if viewModel.isPaused {
                    HStack {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(.orange)
                        Text("Rest: \(viewModel.restTimeString)")
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal)
                }
            }

            // MARK: - Controls
            if !viewModel.isRunning {
                Button(action: {
                    viewModel.startRun()
                }) {
                    Text("Start Run")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            } else {
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.togglePause()
                    }) {
                        Text(viewModel.isPaused ? "Resume" : "Pause")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        viewModel.endRunAndSave()
                        showPostRun = true
                    }) {
                        Text("End Run")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        viewModel.requestDiscard()
                    }) {
                        Text("Discard")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .onAppear {
            viewModel.requestLocationPermission()
        }
        .sheet(isPresented: $showPostRun) {
            PostRunScreen(runViewModel: viewModel)
        }
        // Discard confirmation alert
        .alert("Discard Run?", isPresented: $viewModel.showDiscardConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.confirmDiscard()
            }
            Button("Discard", role: .destructive) {
                viewModel.confirmDiscard()
            }
        } message: {
            Text("This will permanently delete your run data. This action cannot be undone.")
        }
        .alert("Location Access Required", isPresented: $viewModel.showLocationPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
        } message: {
            Text("RunRight needs access to your location to track your runs. Please enable location access in Settings.")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.showError = false
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Helper
    
    private func formatDistance(_ meters: Double, unit: DistanceUnit) -> String {
        switch unit {
        case .kilometers:
            return String(format: "%.2f km", meters / 1000.0)
        case .miles:
            return String(format: "%.2f mi", meters / 1609.34)
        }
    }
}

