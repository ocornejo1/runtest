//
//  PaceCard.swift
//  Run
//
//  Created by Omar Cornejo
//

import Foundation
import SwiftUI

struct PaceInsightsCard: View {
    let recentRuns: [RunSummary]
    let unit: DistanceUnit
    
    private var averagePace: Pace? {
        guard !recentRuns.isEmpty else { return nil }
        
        let totalDistance = recentRuns.reduce(0.0) { $0 + $1.distanceKm }
        let totalDuration = recentRuns.reduce(0.0) { $0 + ($1.durationMinutes * 60) }
        
        guard totalDistance > 0 else { return nil }
        
        return Pace(distanceKm: totalDistance, durationSeconds: totalDuration)
    }
    
    private var fastestPace: Pace? {
        guard !recentRuns.isEmpty else { return nil }
        
        let paces = recentRuns.compactMap { run -> Pace? in
            let durationSeconds = run.durationMinutes * 60
            return Pace(distanceKm: run.distanceKm, durationSeconds: durationSeconds)
        }
        
        return paces.min(by: { $0.secondsPerKilometer < $1.secondsPerKilometer })
    }
    
    private var paceZones: PaceZoneCalculator? {
        guard let avgPace = averagePace else { return nil }
        return PaceZoneCalculator(recentAveragePace: avgPace)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pace Insights")
                .font(.headline)
            
            if let avgPace = averagePace, let fastPace = fastestPace {
                HStack {
                    Image(systemName: "gauge.medium")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Average Pace")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(avgPace.formatted(for: unit))
                            .font(.subheadline)
                            .bold()
                    }
                    Spacer()
                }
                
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fastest Pace")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(fastPace.formatted(for: unit))
                            .font(.subheadline)
                            .bold()
                    }
                    Spacer()
                }
                
                Divider()
                
                if let zones = paceZones {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your Training Zones")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        PaceZoneRow(
                            title: "Easy",
                            range: zones.formatRange(zones.easyPace, unit: unit),
                            color: .green
                        )
                        
                        PaceZoneRow(
                            title: "Tempo",
                            range: zones.formatRange(zones.tempoPace, unit: unit),
                            color: .orange
                        )
                        
                        PaceZoneRow(
                            title: "Threshold",
                            range: zones.formatRange(zones.thresholdPace, unit: unit),
                            color: .red
                        )
                    }
                }
            } else {
                Text("Complete a few runs to see your pace insights")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.08))
        .cornerRadius(12)
    }
}

struct PaceZoneRow: View {
    let title: String
    let range: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text(range)
                .font(.caption2)
                .bold()
        }
    }
}
