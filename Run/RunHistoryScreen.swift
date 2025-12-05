//
//  RunHistoryScreen.swift
//  Run
//
//  Created by Omar Cornejo
//

import SwiftUI

enum RunSortOption: String, CaseIterable, Identifiable {
    case date = "Date"
    case distance = "Distance"
    case duration = "Duration"
    
    var id: String { rawValue }
}

struct RunHistoryScreen: View {
    let unit: DistanceUnit

    @StateObject private var viewModel = RunHistoryViewModel()
    @State private var sortOption: RunSortOption = .date
    @State private var expandedRunId: String? = nil
    
    private var userAveragePace: Pace? {
        guard !viewModel.runs.isEmpty else { return nil }
        
        let recentRuns = viewModel.runs.prefix(20)  // Use last 20 runs
        let summaries = recentRuns.map { run in
            RunSummary(
                date: run.date,
                durationMinutes: run.durationSeconds / 60,
                distanceKm: run.distanceKm,
                difficultyRating: run.difficultyRating ?? 3,
                painLevel: run.painLevel ?? 0,
                painAreas: run.painAreas ?? []
            )
        }
        
        return UserRelativePaceAnalyzer.calculateAveragePace(from: Array(summaries))
    }

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    private var isMiles: Bool {
        unit == .miles
    }

    private var unitLabel: String {
        isMiles ? "mi" : "km"
    }
    
    private var sortedRuns: [RunRecord] {
        switch sortOption {
        case .date:
            return viewModel.runs.sorted { $0.date > $1.date }
        case .distance:
            return viewModel.runs.sorted { $0.distanceMeters > $1.distanceMeters }
        case .duration:
            return viewModel.runs.sorted { $0.durationSeconds > $1.durationSeconds }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading runs...")
                } else if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else if viewModel.runs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.run")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No runs recorded yet")
                            .font(.headline)
                        Text("Start your first run to see it here!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    VStack(spacing: 0) {
                        Picker("Sort by", selection: $sortOption) {
                            ForEach(RunSortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        
                        List(sortedRuns) { run in
                            RunHistoryRow(
                                run: run,
                                unit: unit,
                                userAveragePace: userAveragePace,
                                isExpanded: expandedRunId == run.id,
                                onTap: {
                                    withAnimation {
                                        if expandedRunId == run.id {
                                            expandedRunId = nil
                                        } else {
                                            expandedRunId = run.id
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Run History")
            .onAppear {
                viewModel.loadRuns()
            }
        }
    }
}

// MARK: - Run History Row

struct RunHistoryRow: View {
    let run: RunRecord
    let unit: DistanceUnit
    let userAveragePace: Pace?
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // MARK: - Main Summary (Always Visible)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(formatDate(run.date))
                            .font(.headline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Distance")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(run.formattedDistance(unit: unit))
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(run.durationFormatted)
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pace")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(run.formattedPace(unit: unit))
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // MARK: - Expanded Details
                if isExpanded {
                    Divider()
                        .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        if let difficulty = run.difficultyRating {
                            HStack(spacing: 8) {
                                Image(systemName: "gauge.medium")
                                    .foregroundColor(.blue)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("How it felt")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    HStack(spacing: 4) {
                                        ForEach(1...5, id: \.self) { level in
                                            Circle()
                                                .fill(level <= difficulty ? Color.blue : Color.gray.opacity(0.3))
                                                .frame(width: 8, height: 8)
                                        }
                                        Text(difficultyDescription(difficulty))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        if let painLevel = run.painLevel {
                            HStack(spacing: 8) {
                                Image(systemName: painLevel == 0 ? "checkmark.circle" : "exclamationmark.triangle")
                                    .foregroundColor(painLevel == 0 ? .green : (painLevel <= 3 ? .orange : .red))
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Pain level")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(painDescription(painLevel))
                                        .font(.subheadline)
                                        .foregroundColor(painLevel == 0 ? .green : (painLevel <= 3 ? .orange : .red))
                                }
                            }
                            
                            if let areas = run.painAreas, !areas.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "figure.stand")
                                        .foregroundColor(.orange)
                                        .frame(width: 20)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Areas")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(areas.joined(separator: ", "))
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        
                        if let rest = run.restTime,
                           !rest.isEmpty,
                           rest != "00:00" {
                            HStack(spacing: 8) {
                                Image(systemName: "pause.circle")
                                    .foregroundColor(.orange)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Rest taken")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(rest)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                        
                        if let notes = run.notes, !notes.isEmpty {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "note.text")
                                    .foregroundColor(.blue)
                                    .frame(width: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Notes")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        
                        Text(encouragementMessage(for: run))
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func difficultyDescription(_ level: Int) -> String {
        switch level {
        case 1:
            return "Very easy"
        case 2:
            return "Comfortable"
        case 3:
            return "Moderate effort"
        case 4:
            return "Challenging"
        case 5:
            return "Very hard"
        default:
            return ""
        }
    }
    
    private func painDescription(_ level: Int) -> String {
        switch level {
        case 0:
            return "No pain - feeling great! ✓"
        case 1...2:
            return "Minimal discomfort"
        case 3...5:
            return "Moderate - monitor this"
        case 6...7:
            return "Significant - consider rest"
        case 8...10:
            return "Severe - rest needed"
        default:
            return ""
        }
    }
    
    private func encouragementMessage(for run: RunRecord) -> String {
        if let avgPace = userAveragePace {
            return run.encouragementMessage(comparedTo: avgPace)
        }
        
        if let painLevel = run.painLevel, painLevel >= 6 {
            return "Listen to your body. Rest and recovery are part of training!"
        }
        
        return "Great job completing this run! Keep building your fitness consistently."
    }
}


