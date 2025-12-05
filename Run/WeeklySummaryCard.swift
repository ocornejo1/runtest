//
//  WeeklySummaryCard.swift
//  Run
//
//  Created by Omar Cornejo
//


import SwiftUI

struct WeeklySummaryCard: View {
    let recentRuns: [RunSummary]
    let unit: DistanceUnit

    private var thisWeekRuns: [RunSummary] {
        let cal = Calendar.current
        guard let weekAgo = cal.date(byAdding: .day, value: -7, to: Date()) else { return [] }
        return recentRuns.filter { $0.date >= weekAgo }
    }

    private var totalDistanceKm: Double {
        thisWeekRuns.reduce(0) { $0 + $1.distanceKm }
    }

    private var averageDifficulty: Double? {
        let rated = thisWeekRuns.map { Double($0.difficultyRating) }
        guard !rated.isEmpty else { return nil }
        let sum = rated.reduce(0, +)
        return sum / Double(rated.count)
    }

    private var weeklyPainAreas: [String] {
        let allAreas = thisWeekRuns.flatMap { $0.painAreas }
        let cleaned = allAreas
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return Array(Set(cleaned)).sorted()
    }

    private func formattedDistance() -> String {
        switch unit {
        case .kilometers:
            return String(format: "%.1f km", totalDistanceKm)
        case .miles:
            let miles = totalDistanceKm * 0.621371
            return String(format: "%.1f mi", miles)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("This Week")
                .font(.headline)

            if thisWeekRuns.isEmpty {
                Text("No runs logged yet this week.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Total distance: \(formattedDistance())")
                    .font(.subheadline)

                if let avgDiff = averageDifficulty {
                    Text(String(format: "Average difficulty: %.1f / 5", avgDiff))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if weeklyPainAreas.isEmpty {
                    Text("Pain reported: none")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Pain reported: \(weeklyPainAreas.joined(separator: ", "))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}
