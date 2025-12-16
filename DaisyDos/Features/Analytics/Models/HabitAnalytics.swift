//
//  HabitAnalytics.swift
//  DaisyDos
//
//  Created by Claude Code on 12/10/25.
//

import Foundation

/// Aggregated analytics data for habits over a specific period
struct HabitAnalytics {
    let period: AnalyticsPeriod

    // Weekly completions
    let weeklyCompletions: [CompletionDataPoint]

    // Streak data
    let topStreaks: [StreakData]
    let averageStreak: Int
    let longestActiveStreak: Int

    // Completion rates
    let completionRate: CompletionRateData
    let totalHabits: Int
    let completedToday: Int
    let pendingToday: Int

    // Mood trends
    let moodTrends: [MoodDataPoint]
    let averageMood: Double

    // Time of day distribution
    let timeOfDayDistribution: [TimeOfDayData]

    // Computed properties
    var hasData: Bool {
        return !weeklyCompletions.isEmpty || !topStreaks.isEmpty
    }

    var completionPercentage: Double {
        guard totalHabits > 0 else { return 0 }
        return Double(completedToday) / Double(totalHabits)
    }

    var completionPercentageText: String {
        String(format: "%.0f%%", completionPercentage * 100)
    }

    /// Empty analytics (for when there's no data)
    static func empty(period: AnalyticsPeriod) -> HabitAnalytics {
        return HabitAnalytics(
            period: period,
            weeklyCompletions: [],
            topStreaks: [],
            averageStreak: 0,
            longestActiveStreak: 0,
            completionRate: CompletionRateData(category: "None", count: 0, percentage: 0),
            totalHabits: 0,
            completedToday: 0,
            pendingToday: 0,
            moodTrends: [],
            averageMood: 3.0,
            timeOfDayDistribution: []
        )
    }
}
