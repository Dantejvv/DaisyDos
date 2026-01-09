//
//  AnalyticsManager.swift
//  DaisyDos
//
//  Created by Claude Code on 12/10/25.
//

import Foundation
import Observation
import SwiftData

@Observable
final class AnalyticsManager {
    // Dependencies
    private let habitManager: HabitManager

    // Cache
    private var cachedAnalytics: [AnalyticsPeriod: HabitAnalytics] = [:]
    private var lastCacheUpdate: [AnalyticsPeriod: Date] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes

    init(modelContext: ModelContext) {
        self.habitManager = HabitManager(modelContext: modelContext)
    }

    // MARK: - Public API

    /// Get habit analytics for a specific period
    func getHabitAnalytics(for period: AnalyticsPeriod) -> HabitAnalytics {
        // Check cache
        if let cached = cachedAnalytics[period],
           let lastUpdate = lastCacheUpdate[period],
           Date().timeIntervalSince(lastUpdate) < cacheValidityDuration {
            return cached
        }

        // Calculate fresh analytics
        let analytics = calculateHabitAnalytics(for: period)

        // Update cache
        cachedAnalytics[period] = analytics
        lastCacheUpdate[period] = Date()

        return analytics
    }

    /// Force refresh analytics for a specific period
    func refreshAnalytics(for period: AnalyticsPeriod) {
        let analytics = calculateHabitAnalytics(for: period)
        cachedAnalytics[period] = analytics
        lastCacheUpdate[period] = Date()
    }

    /// Clear all cached analytics
    func clearCache() {
        cachedAnalytics.removeAll()
        lastCacheUpdate.removeAll()
    }

    // MARK: - Private Methods

    private func calculateHabitAnalytics(for period: AnalyticsPeriod) -> HabitAnalytics {
        // Weekly completions
        let weeklyCompletions = habitManager.completionsInPeriod(days: period.days)

        // Top streaks
        let topStreaks = habitManager.topStreakData(limit: 5)

        // Streak statistics
        let averageStreak = habitManager.averageStreak
        let longestActiveStreak = habitManager.longestActiveStreak

        // Completion rate for today
        let completionRateData = habitManager.todayCompletionRateData()
        let completionRate = completionRateData.first ?? CompletionRateData(
            category: "None",
            count: 0,
            percentage: 0
        )

        // Today's stats
        let totalHabits = habitManager.habitCount
        let completedToday = habitManager.completedTodayCount
        let pendingToday = habitManager.pendingTodayCount

        // Time of day distribution
        let timeOfDayDistribution = habitManager.timeOfDayDistribution(days: period.days)

        return HabitAnalytics(
            period: period,
            weeklyCompletions: weeklyCompletions,
            topStreaks: topStreaks,
            averageStreak: Int(averageStreak),
            longestActiveStreak: longestActiveStreak,
            completionRate: completionRate,
            totalHabits: totalHabits,
            completedToday: completedToday,
            pendingToday: pendingToday,
            timeOfDayDistribution: timeOfDayDistribution
        )
    }
}
