//
//  HabitManager+Analytics.swift
//  DaisyDos
//
//  Created by Claude Code on 12/10/25.
//

import Foundation
import SwiftData

extension HabitManager {
    // MARK: - Completion Data

    /// Get daily completion counts for the specified period
    func completionsInPeriod(days: Int) -> [CompletionDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }

        // Get all habits
        let habits = allHabits

        // Create date buckets
        var dateCounts: [Date: Int] = [:]
        var currentDate = startDate
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            dateCounts[dayStart] = 0
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }

        // Count completions per day
        for habit in habits {
            for completion in habit.completionEntries ?? [] {
                let completionDay = calendar.startOfDay(for: completion.completedDate)
                if completionDay >= startDate && completionDay <= endDate {
                    dateCounts[completionDay, default: 0] += 1
                }
            }
        }

        // Convert to data points
        return dateCounts
            .sorted { $0.key < $1.key }
            .map { CompletionDataPoint(date: $0.key, count: $0.value) }
    }

    // MARK: - Streak Data

    /// Get top streaks across all habits
    func topStreakData(limit: Int = 5) -> [StreakData] {
        let sortedHabits = habitsByStreak.prefix(limit)

        return sortedHabits.map { habit in
            let milestones = [7, 14, 21, 30, 50, 75, 100, 150, 200, 365]
            let nextMilestone = milestones.first { $0 > habit.currentStreak } ?? 365

            let progress: Double
            if habit.currentStreak == 0 {
                progress = 0
            } else {
                // Find previous milestone
                let previousMilestone = milestones.last { $0 <= habit.currentStreak } ?? 0
                if nextMilestone == previousMilestone {
                    progress = 1.0
                } else {
                    let progressInRange = Double(habit.currentStreak - previousMilestone)
                    let rangeSize = Double(nextMilestone - previousMilestone)
                    progress = progressInRange / rangeSize
                }
            }

            return StreakData(
                id: habit.id,
                habitName: habit.title,
                currentStreak: habit.currentStreak,
                longestStreak: habit.longestStreak,
                progress: min(progress, 1.0),
                nextMilestone: nextMilestone
            )
        }
    }

    // MARK: - Time of Day Distribution

    /// Get distribution of completions by time of day
    func timeOfDayDistribution(days: Int) -> [TimeOfDayData] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }

        // Get all habits
        let habits = allHabits

        // Count by time of day
        var timeCounts: [HabitCompletion.TimeOfDay: Int] = [:]

        for habit in habits {
            for completion in habit.completionEntries ?? [] {
                if completion.completedDate >= startDate && completion.completedDate <= endDate {
                    timeCounts[completion.timeOfDay, default: 0] += 1
                }
            }
        }

        let totalCount = timeCounts.values.reduce(0, +)
        guard totalCount > 0 else { return [] }

        // Convert to data points
        return HabitCompletion.TimeOfDay.allCases.compactMap { timeOfDay in
            let count = timeCounts[timeOfDay] ?? 0
            guard count > 0 else { return nil }

            let percentage = Double(count) / Double(totalCount)
            return TimeOfDayData(
                timeOfDay: timeOfDay.displayName,
                count: count,
                percentage: percentage
            )
        }
    }

    // MARK: - Completion Rate

    /// Get completion rate data for today
    func todayCompletionRateData() -> [CompletionRateData] {
        let completed = completedTodayCount
        let pending = pendingTodayCount
        let total = completed + pending

        guard total > 0 else {
            return [CompletionRateData(category: "No Habits", count: 0, percentage: 1.0)]
        }

        var data: [CompletionRateData] = []

        if completed > 0 {
            data.append(CompletionRateData(
                category: "Completed",
                count: completed,
                percentage: Double(completed) / Double(total)
            ))
        }

        if pending > 0 {
            data.append(CompletionRateData(
                category: "Pending",
                count: pending,
                percentage: Double(pending) / Double(total)
            ))
        }

        return data
    }
}
