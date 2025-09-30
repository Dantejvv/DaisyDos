//
//  HabitManager+Analytics.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import Foundation
import SwiftData

// MARK: - Analytics Supporting Types

enum AnalyticsPeriod: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"

    var displayName: String {
        switch self {
        case .week: return "This Week"
        case .month: return "This Month"
        case .quarter: return "This Quarter"
        case .year: return "This Year"
        }
    }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .year: return 365
        }
    }
}

enum AnalyticsTimeframe: String, CaseIterable {
    case week = "week"
    case month = "month"
    case quarter = "quarter"
    case year = "year"

    var displayName: String {
        switch self {
        case .week: return "Week"
        case .month: return "Month"
        case .quarter: return "Quarter"
        case .year: return "Year"
        }
    }
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable
    case insufficient_data

    var emoji: String {
        switch self {
        case .increasing: return "📈"
        case .decreasing: return "📉"
        case .stable: return "➡️"
        case .insufficient_data: return "❓"
        }
    }

    var displayName: String {
        switch self {
        case .increasing: return "Improving"
        case .decreasing: return "Declining"
        case .stable: return "Stable"
        case .insufficient_data: return "Not enough data"
        }
    }
}

enum ChartType {
    case completion
    case streak
    case mood
    case timeOfDay
}

struct ChartDataPoint: Equatable {
    let date: Date
    let value: Double
    let label: String
    let metadata: [String: Any]

    static func == (lhs: ChartDataPoint, rhs: ChartDataPoint) -> Bool {
        lhs.date == rhs.date && lhs.value == rhs.value && lhs.label == rhs.label
    }
}

struct HeatmapDataPoint: Equatable {
    let date: Date
    let intensity: Double // 0.0 to 1.0
    let completionCount: Int
    let isCompleted: Bool
}

struct MilestoneProgress {
    let current: Int
    let nextMilestone: Int
    let progress: Double // 0.0 to 1.0
    let milestoneType: HabitStreak.Milestone.MilestoneType?
}

struct ProgressMetrics {
    let completionRate: Double
    let currentStreak: Int
    let longestStreak: Int
    let totalCompletions: Int
    let averageMood: Double
    let consistency: Double // How consistent completions are
    let momentum: HabitStreak.StreakMomentum
}

// MARK: - HabitManager Analytics Extension

extension HabitManager {

    // MARK: - Streak Analysis

    /// Calculate accurate streak
    func calculateAccurateStreak(for habit: Habit) -> Int {
        let completions = habit.completionEntries
            .sorted { $0.completedDate < $1.completedDate }

        guard !completions.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var currentStreak = 0
        var lastCompletionDate: Date?

        // Start from most recent completion and work backwards
        for completion in completions.reversed() {
            let completionDate = calendar.startOfDay(for: completion.completedDate)

            if lastCompletionDate == nil {
                // First completion in reverse order
                if completionDate == today ||
                   completionDate == calendar.date(byAdding: .day, value: -1, to: today) {
                    currentStreak = 1
                    lastCompletionDate = completionDate
                } else {
                    // Most recent completion is too old
                    break
                }
            } else {
                let daysBetween = calendar.dateComponents([.day],
                    from: completionDate, to: lastCompletionDate!).day ?? 0

                if daysBetween == 1 {
                    // Consecutive day
                    currentStreak += 1
                    lastCompletionDate = completionDate
                } else {
                    // Gap in days, end streak
                    break
                }
            }
        }

        return currentStreak
    }

    /// Get streak quality assessment
    func getStreakQuality(for habit: Habit) -> HabitStreak.StreakQuality {
        let currentStreak = calculateAccurateStreak(for: habit)

        // Simplified quality based on streak length and consistency
        let lengthScore = min(Double(currentStreak) / 30.0, 1.0)
        let consistencyScore = calculateConsistencyScore(for: habit)
        let qualityScore = (consistencyScore * 0.7) + (lengthScore * 0.3)

        switch qualityScore {
        case 0.9...1.0: return .excellent
        case 0.7..<0.9: return .good
        case 0.5..<0.7: return .fair
        default: return .needsImprovement
        }
    }

    /// Get milestone progress for habit
    func getMilestoneProgress(for habit: Habit) -> MilestoneProgress {
        let currentStreak = calculateAccurateStreak(for: habit)
        let milestones: [Int] = [7, 14, 21, 30, 50, 75, 100, 150, 200, 365]

        for milestone in milestones {
            if currentStreak < milestone {
                let progress = Double(currentStreak) / Double(milestone)
                let milestoneType = getMilestoneType(for: milestone)
                return MilestoneProgress(
                    current: currentStreak,
                    nextMilestone: milestone,
                    progress: progress,
                    milestoneType: milestoneType
                )
            }
        }

        // Beyond all milestones
        return MilestoneProgress(
            current: currentStreak,
            nextMilestone: currentStreak + 1,
            progress: 1.0,
            milestoneType: .exceptional
        )
    }

    // MARK: - Completion Analytics

    /// Get completion rate for a specific period
    func getCompletionRate(for habit: Habit, period: AnalyticsPeriod) -> Double {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -period.days, to: endDate) else {
            return 0.0
        }

        let completions = habit.completionEntries.filter { completion in
            completion.completedDate >= startDate && completion.completedDate <= endDate
        }

        let totalDueDays = getDueDaysInPeriod(for: habit, from: startDate, to: endDate)
        guard totalDueDays > 0 else { return 0.0 }

        return Double(completions.count) / Double(totalDueDays)
    }

    /// Get completion trend direction
    func getCompletionTrend(for habit: Habit, period: AnalyticsPeriod) -> TrendDirection {
        let currentRate = getCompletionRate(for: habit, period: period)

        // Compare with previous period
        let endDate = Calendar.current.date(byAdding: .day, value: -period.days, to: Date()) ?? Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -period.days, to: endDate) else {
            return .insufficient_data
        }

        let previousCompletions = habit.completionEntries.filter { completion in
            completion.completedDate >= startDate && completion.completedDate <= endDate
        }

        let previousDueDays = getDueDaysInPeriod(for: habit, from: startDate, to: endDate)
        guard previousDueDays > 0 else { return .insufficient_data }

        let previousRate = Double(previousCompletions.count) / Double(previousDueDays)

        let threshold = 0.05 // 5% threshold for stability
        if currentRate > previousRate + threshold {
            return .increasing
        } else if currentRate < previousRate - threshold {
            return .decreasing
        } else {
            return .stable
        }
    }

    /// Get best performing time of day
    func getBestPerformingTimeOfDay(for habit: Habit) -> HabitCompletion.TimeOfDay? {
        let completions = habit.completionEntries
        guard !completions.isEmpty else { return nil }

        var timeOfDayCount: [HabitCompletion.TimeOfDay: Int] = [:]

        for completion in completions {
            let timeOfDay = completion.timeOfDay
            timeOfDayCount[timeOfDay, default: 0] += 1
        }

        return timeOfDayCount.max { $0.value < $1.value }?.key
    }

    // MARK: - Progress Data for Charts

    /// Get chart data for various visualization types
    func getChartData(for habit: Habit, type: ChartType, period: AnalyticsPeriod) -> [ChartDataPoint] {
        switch type {
        case .completion:
            return getCompletionChartData(for: habit, period: period)
        case .streak:
            return getStreakChartData(for: habit, period: period)
        case .mood:
            return getMoodChartData(for: habit, period: period)
        case .timeOfDay:
            return getTimeOfDayChartData(for: habit, period: period)
        }
    }

    /// Get heatmap data for calendar visualization
    func getHeatmapData(for habit: Habit, dateRange: ClosedRange<Date>) -> [HeatmapDataPoint] {
        var heatmapData: [HeatmapDataPoint] = []
        let calendar = Calendar.current

        var currentDate = dateRange.lowerBound
        while currentDate <= dateRange.upperBound {
            let dayStart = calendar.startOfDay(for: currentDate)

            let completionsForDay = habit.completionEntries.filter { completion in
                calendar.isDate(completion.completedDate, inSameDayAs: dayStart)
            }

            let isCompleted = !completionsForDay.isEmpty
            let completionCount = completionsForDay.count

            // Calculate intensity based on completion frequency for this day of week historically
            let intensity = calculateHeatmapIntensity(for: habit, date: dayStart)

            heatmapData.append(HeatmapDataPoint(
                date: dayStart,
                intensity: intensity,
                completionCount: completionCount,
                isCompleted: isCompleted
            ))

            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }

        return heatmapData
    }

    /// Get comprehensive progress metrics
    func getProgressMetrics(for habit: Habit, period: AnalyticsPeriod) -> ProgressMetrics {
        let completionRate = getCompletionRate(for: habit, period: period)
        let currentStreak = calculateAccurateStreak(for: habit)
        let longestStreak = habit.longestStreak

        let recentCompletions = getRecentCompletions(for: habit, period: period)
        let totalCompletions = recentCompletions.count

        let averageMood = recentCompletions.isEmpty ? 3.0 :
            recentCompletions.map { Double($0.mood.score) }.reduce(0, +) / Double(recentCompletions.count)

        let consistency = calculateConsistency(for: habit, period: period)
        let momentum = calculateMomentum(for: habit)

        return ProgressMetrics(
            completionRate: completionRate,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalCompletions: totalCompletions,
            averageMood: averageMood,
            consistency: consistency,
            momentum: momentum
        )
    }

    // MARK: - Private Helper Methods

    private func calculateConsistencyScore(for habit: Habit) -> Double {
        // Calculate consistency based on completion regularity
        let recentCompletions = habit.completionEntries.suffix(30) // Last 30 completions
        guard recentCompletions.count > 1 else { return 1.0 }

        var consecutiveDays = 0
        let calendar = Calendar.current

        for i in 1..<recentCompletions.count {
            let current = recentCompletions[i]
            let previous = recentCompletions[i-1]

            let daysBetween = calendar.dateComponents([.day],
                from: previous.completedDate, to: current.completedDate).day ?? 0

            if daysBetween == 1 {
                consecutiveDays += 1
            }
        }

        return Double(consecutiveDays) / Double(recentCompletions.count - 1)
    }

    private func getMilestoneType(for days: Int) -> HabitStreak.Milestone.MilestoneType {
        switch days {
        case 7: return .week
        case 14, 21: return .multiWeek
        case 30: return .month
        case 50, 75: return .extended
        case 100: return .century
        case 150, 200: return .exceptional
        case 365: return .year
        default: return .custom
        }
    }

    private func getDueDaysInPeriod(for habit: Habit, from startDate: Date, to endDate: Date) -> Int {
        guard let recurrenceRule = habit.recurrenceRule else {
            // Flexible habit - every day is due
            let calendar = Calendar.current
            return calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        }

        let occurrences = recurrenceRule.occurrences(from: startDate, limit: 1000)
        return occurrences.filter { $0 <= endDate }.count
    }

    private func getCompletionChartData(for habit: Habit, period: AnalyticsPeriod) -> [ChartDataPoint] {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -period.days, to: endDate) else {
            return []
        }

        var chartData: [ChartDataPoint] = []
        let calendar = Calendar.current

        // Group completions by week for the chart
        var currentDate = startDate
        while currentDate <= endDate {
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate

            let weekCompletions = habit.completionEntries.filter { completion in
                completion.completedDate >= currentDate && completion.completedDate < weekEnd
            }

            chartData.append(ChartDataPoint(
                date: currentDate,
                value: Double(weekCompletions.count),
                label: DateFormatter.shortWeek.string(from: currentDate),
                metadata: ["completions": weekCompletions.count]
            ))

            currentDate = weekEnd
        }

        return chartData
    }

    private func getStreakChartData(for habit: Habit, period: AnalyticsPeriod) -> [ChartDataPoint] {
        // Simplified streak progression over time
        let streaks = habit.streaks.sorted { $0.startDate < $1.startDate }

        return streaks.map { streak in
            ChartDataPoint(
                date: streak.startDate,
                value: Double(streak.length),
                label: "Streak \(streak.length)",
                metadata: ["length": streak.length, "quality": streak.streakQuality.displayName]
            )
        }
    }

    private func getMoodChartData(for habit: Habit, period: AnalyticsPeriod) -> [ChartDataPoint] {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -period.days, to: endDate) else {
            return []
        }

        let recentCompletions = habit.completionEntries.filter { completion in
            completion.completedDate >= startDate && completion.completedDate <= endDate
        }.sorted { $0.completedDate < $1.completedDate }

        return recentCompletions.map { completion in
            ChartDataPoint(
                date: completion.completedDate,
                value: Double(completion.mood.score),
                label: completion.mood.displayName,
                metadata: ["mood": completion.mood.displayName, "emoji": completion.mood.emoji]
            )
        }
    }

    private func getTimeOfDayChartData(for habit: Habit, period: AnalyticsPeriod) -> [ChartDataPoint] {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -period.days, to: endDate) else {
            return []
        }

        let recentCompletions = habit.completionEntries.filter { completion in
            completion.completedDate >= startDate && completion.completedDate <= endDate
        }

        var timeOfDayCount: [HabitCompletion.TimeOfDay: Int] = [:]
        for completion in recentCompletions {
            timeOfDayCount[completion.timeOfDay, default: 0] += 1
        }

        return HabitCompletion.TimeOfDay.allCases.map { timeOfDay in
            ChartDataPoint(
                date: startDate, // Using start date as reference
                value: Double(timeOfDayCount[timeOfDay] ?? 0),
                label: timeOfDay.displayName,
                metadata: ["timeOfDay": timeOfDay.displayName, "emoji": timeOfDay.emoji]
            )
        }
    }

    private func calculateHeatmapIntensity(for habit: Habit, date: Date) -> Double {
        let calendar = Calendar.current
        let completionsForDay = habit.completionEntries.filter { completion in
            calendar.isDate(completion.completedDate, inSameDayAs: date)
        }

        if completionsForDay.isEmpty {
            return 0.0
        }

        // Base intensity on completion + mood
        let avgMood = completionsForDay.map { Double($0.mood.score) }.reduce(0, +) / Double(completionsForDay.count)
        let normalizedMood = (avgMood - 1.0) / 4.0 // Convert 1-5 scale to 0-1

        return min(1.0, 0.5 + (normalizedMood * 0.5)) // Always at least 0.5 if completed
    }

    private func getRecentCompletions(for habit: Habit, period: AnalyticsPeriod) -> [HabitCompletion] {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -period.days, to: endDate) else {
            return []
        }

        return habit.completionEntries.filter { completion in
            completion.completedDate >= startDate && completion.completedDate <= endDate
        }
    }

    private func calculateConsistency(for habit: Habit, period: AnalyticsPeriod) -> Double {
        let completions = getRecentCompletions(for: habit, period: period)
        guard completions.count > 1 else { return 0.0 }

        let calendar = Calendar.current
        let sortedCompletions = completions.sorted { $0.completedDate < $1.completedDate }

        var intervals: [Int] = []
        for i in 1..<sortedCompletions.count {
            let interval = calendar.dateComponents([.day],
                from: sortedCompletions[i-1].completedDate,
                to: sortedCompletions[i].completedDate).day ?? 0
            intervals.append(interval)
        }

        guard !intervals.isEmpty else { return 0.0 }

        let averageInterval = Double(intervals.reduce(0, +)) / Double(intervals.count)
        let variance = intervals.map { pow(Double($0) - averageInterval, 2) }.reduce(0, +) / Double(intervals.count)
        let standardDeviation = sqrt(variance)

        // Lower standard deviation = higher consistency
        return max(0.0, 1.0 - (standardDeviation / averageInterval))
    }

    private func calculateMomentum(for habit: Habit) -> HabitStreak.StreakMomentum {
        let recentCompletions = habit.completionEntries
            .filter { completion in
                let daysSince = Calendar.current.dateComponents([.day],
                    from: completion.completedDate, to: Date()).day ?? 0
                return daysSince <= 7 // Last week
            }
            .count

        let weeklyTarget = habit.recurrenceRule?.frequency == .daily ? 7 : 1
        let completionRate = Double(recentCompletions) / Double(weeklyTarget)

        switch completionRate {
        case 1.0...: return .accelerating
        case 0.8..<1.0: return .strong
        case 0.6..<0.8: return .steady
        case 0.3..<0.6: return .slowing
        default: return .stagnant
        }
    }
}

// MARK: - Date Formatter Extensions

private extension DateFormatter {
    static let shortWeek: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}