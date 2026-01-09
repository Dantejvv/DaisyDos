//
//  ChartData.swift
//  DaisyDos
//
//  Created by Claude Code on 12/10/25.
//

import Foundation

/// Data point for completion charts
struct CompletionDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int

    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

/// Data for streak display
struct StreakData: Identifiable {
    let id: UUID
    let habitName: String
    let currentStreak: Int
    let longestStreak: Int
    let progress: Double // 0.0 to 1.0
    let nextMilestone: Int

    var progressPercentage: String {
        String(format: "%.0f%%", progress * 100)
    }
}

/// Completion rate data for pie charts
struct CompletionRateData: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
    let percentage: Double

    var percentageText: String {
        String(format: "%.1f%%", percentage * 100)
    }
}

/// Time of day distribution data
struct TimeOfDayData: Identifiable {
    let id = UUID()
    let timeOfDay: String
    let count: Int
    let percentage: Double
}
