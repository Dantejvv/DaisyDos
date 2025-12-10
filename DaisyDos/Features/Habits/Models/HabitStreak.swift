//
//  HabitStreak.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class HabitStreak {

    // MARK: - Properties (CloudKit-compatible: all have defaults)

    var id: UUID = UUID()
    var startDate: Date = Date()
    var endDate: Date?
    var length: Int = 0
    var isActive: Bool = true
    var streakType: StreakType = StreakType.daily
    var notes: String = ""

    // MARK: - Relationships

    @Relationship(inverse: \Habit.streaks)
    var habit: Habit?

    // MARK: - Streak Types

    enum StreakType: String, CaseIterable, Codable {
        case daily = "daily"
        case weekly = "weekly"
        case custom = "custom"

        var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .custom: return "Custom"
            }
        }
    }

    // MARK: - Initializers

    init(habit: Habit, startDate: Date, streakType: StreakType = .daily) {
        self.id = UUID()
        self.habit = habit
        self.startDate = startDate
        self.endDate = nil
        self.length = 1
        self.isActive = true
        self.streakType = streakType
    }

    // MARK: - Computed Properties

    var duration: TimeInterval {
        let endDate = self.endDate ?? Date()
        return endDate.timeIntervalSince(startDate)
    }

    var durationInDays: Int {
        let calendar = Calendar.current
        let endDate = self.endDate ?? Date()
        return calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    var isCurrentStreak: Bool {
        return isActive && endDate == nil
    }

    var streakQuality: StreakQuality {
        let lengthScore = min(Double(length) / 30.0, 1.0) // 30 days = perfect length score

        let qualityScore = lengthScore

        switch qualityScore {
        case 0.9...1.0:
            return .excellent
        case 0.7..<0.9:
            return .good
        case 0.5..<0.7:
            return .fair
        default:
            return .needsImprovement
        }
    }

    // MARK: - Business Logic

    /// Extend the streak by one unit (day/week/custom period)
    func extend() {
        guard isActive else { return }
        length += 1
    }

    /// End the streak
    func end(on date: Date = Date()) {
        isActive = false
        endDate = date
    }


    /// Calculate streak momentum (rate of recent progress)
    func momentum() -> StreakMomentum {
        guard let habit = habit, length > 0 else { return .stagnant }

        let recentCompletions = (habit.completionEntries ?? [])
            .filter { completion in
                let daysSince = Calendar.current.dateComponents([.day],
                    from: completion.completedDate, to: Date()).day ?? 0
                return daysSince <= 7 // Last week
            }
            .count

        let weeklyTarget = streakType == .daily ? 7 : 1
        let completionRate = Double(recentCompletions) / Double(weeklyTarget)

        switch completionRate {
        case 1.0...:
            return .accelerating
        case 0.8..<1.0:
            return .strong
        case 0.6..<0.8:
            return .steady
        case 0.3..<0.6:
            return .slowing
        default:
            return .stagnant
        }
    }

    /// Get milestone information for this streak
    func milestone() -> Milestone? {
        let milestones: [Int] = [7, 14, 21, 30, 50, 75, 100, 150, 200, 365]

        for milestone in milestones {
            if length == milestone {
                return Milestone(days: milestone, type: milestoneType(for: milestone))
            }
        }
        return nil
    }

    /// Get next milestone to work towards
    func nextMilestone() -> Milestone? {
        let milestones: [Int] = [7, 14, 21, 30, 50, 75, 100, 150, 200, 365]

        for milestone in milestones {
            if length < milestone {
                return Milestone(days: milestone, type: milestoneType(for: milestone))
            }
        }
        return nil
    }

    // MARK: - Private Helper Methods

    private func milestoneType(for days: Int) -> Milestone.MilestoneType {
        switch days {
        case 7:
            return .week
        case 14, 21:
            return .multiWeek
        case 30:
            return .month
        case 50, 75:
            return .extended
        case 100:
            return .century
        case 150, 200:
            return .exceptional
        case 365:
            return .year
        default:
            return .custom
        }
    }
}

// MARK: - Supporting Types

extension HabitStreak {

    enum StreakQuality {
        case excellent
        case good
        case fair
        case needsImprovement

        var displayName: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair"
            case .needsImprovement: return "Needs Improvement"
            }
        }

        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .needsImprovement: return .red
            }
        }

        var emoji: String {
            switch self {
            case .excellent: return "🌟"
            case .good: return "👍"
            case .fair: return "👌"
            case .needsImprovement: return "💪"
            }
        }
    }

    enum StreakMomentum {
        case accelerating
        case strong
        case steady
        case slowing
        case stagnant

        var displayName: String {
            switch self {
            case .accelerating: return "Accelerating"
            case .strong: return "Strong"
            case .steady: return "Steady"
            case .slowing: return "Slowing"
            case .stagnant: return "Stagnant"
            }
        }

        var emoji: String {
            switch self {
            case .accelerating: return "🚀"
            case .strong: return "💪"
            case .steady: return "⚡"
            case .slowing: return "⏳"
            case .stagnant: return "😴"
            }
        }

        var motivationalMessage: String {
            switch self {
            case .accelerating:
                return "You're on fire! Keep this momentum going!"
            case .strong:
                return "Strong consistency! You're building a solid habit!"
            case .steady:
                return "Steady progress! Consistency is key!"
            case .slowing:
                return "Don't give up! Small steps count!"
            case .stagnant:
                return "Time to restart! You've got this!"
            }
        }
    }

    struct Milestone {
        let days: Int
        let type: MilestoneType

        enum MilestoneType {
            case week
            case multiWeek
            case month
            case extended
            case century
            case exceptional
            case year
            case custom

            var displayName: String {
                switch self {
                case .week: return "First Week"
                case .multiWeek: return "Multi-Week"
                case .month: return "One Month"
                case .extended: return "Extended Streak"
                case .century: return "Century Club"
                case .exceptional: return "Exceptional"
                case .year: return "Full Year"
                case .custom: return "Milestone"
                }
            }

            var emoji: String {
                switch self {
                case .week: return "📅"
                case .multiWeek: return "📊"
                case .month: return "🗓️"
                case .extended: return "🎯"
                case .century: return "💯"
                case .exceptional: return "🏆"
                case .year: return "🎉"
                case .custom: return "⭐"
                }
            }

            var celebrationMessage: String {
                switch self {
                case .week:
                    return "First week complete! The habit is forming!"
                case .multiWeek:
                    return "Multiple weeks strong! You're getting into rhythm!"
                case .month:
                    return "One month streak! This is becoming automatic!"
                case .extended:
                    return "Extended streak achieved! You're in the zone!"
                case .century:
                    return "100 days! Welcome to the century club!"
                case .exceptional:
                    return "Exceptional commitment! You're an inspiration!"
                case .year:
                    return "One full year! Incredible dedication!"
                case .custom:
                    return "Milestone reached! Keep up the great work!"
                }
            }
        }

        var progressMessage: String {
            return "\(type.emoji) \(type.displayName) - \(days) days"
        }

        var celebrationMessage: String {
            return type.celebrationMessage
        }
    }
}

// MARK: - Analytics Extensions

extension HabitStreak {

    /// Calculate average streak length for a habit
    static func averageLength(for streaks: [HabitStreak]) -> Double {
        guard !streaks.isEmpty else { return 0.0 }
        let totalLength = streaks.reduce(0) { $0 + $1.length }
        return Double(totalLength) / Double(streaks.count)
    }

    /// Find the longest streak in a collection
    static func longest(in streaks: [HabitStreak]) -> HabitStreak? {
        return streaks.max { $0.length < $1.length }
    }

    /// Get streak distribution by quality
    static func qualityDistribution(for streaks: [HabitStreak]) -> [StreakQuality: Int] {
        var distribution: [StreakQuality: Int] = [:]

        for streak in streaks {
            let quality = streak.streakQuality
            distribution[quality, default: 0] += 1
        }

        return distribution
    }
}

