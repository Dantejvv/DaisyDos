//
//  Habit.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData

@Model
class Habit {
    var id: UUID
    var title: String
    var habitDescription: String
    var currentStreak: Int
    var longestStreak: Int
    var createdDate: Date
    var lastCompletedDate: Date?

    // MARK: - Enhanced Properties for Phase 3

    /// Recurrence rule for habit scheduling (optional for flexible habits)
    var recurrenceRule: RecurrenceRule?

    /// Grace period in days for maintaining streaks when missed
    var gracePeriodDays: Int = 1

    /// Date when grace period expires (if applicable)
    var gracePeriodExpiryDate: Date?

    /// Track if habit is currently in grace period
    var isInGracePeriod: Bool = false

    // MARK: - Relationships

    @Relationship(deleteRule: .nullify, inverse: \Tag.habits)
    var tags: [Tag] = [] {
        didSet {
            if tags.count > 3 {
                tags = Array(tags.prefix(3))
            }
        }
    }

    /// Individual completion entries with detailed tracking
    var completionEntries: [HabitCompletion] = []

    /// Streak history and management
    var streaks: [HabitStreak] = []

    init(title: String, habitDescription: String = "", recurrenceRule: RecurrenceRule? = nil, gracePeriodDays: Int = 1) {
        self.id = UUID()
        self.title = title
        self.habitDescription = habitDescription
        self.currentStreak = 0
        self.longestStreak = 0
        self.createdDate = Date()
        self.lastCompletedDate = nil
        self.recurrenceRule = recurrenceRule
        self.gracePeriodDays = gracePeriodDays
        self.gracePeriodExpiryDate = nil
        self.isInGracePeriod = false
    }

    var tagCount: Int {
        tags.count
    }

    func canAddTag() -> Bool {
        return tagCount < 3
    }

    func addTag(_ tag: Tag) -> Bool {
        guard canAddTag() else { return false }
        if !tags.contains(tag) {
            tags.append(tag)
            return true
        }
        return false
    }

    func removeTag(_ tag: Tag) {
        tags.removeAll { $0 == tag }
    }

    func markCompleted() {
        let today = Calendar.current.startOfDay(for: Date())

        // Check if already completed today
        if let lastCompleted = lastCompletedDate,
           Calendar.current.isDate(lastCompleted, inSameDayAs: today) {
            return
        }

        lastCompletedDate = today

        // Update streak
        if let lastCompleted = lastCompletedDate,
           Calendar.current.dateInterval(of: .day, for: lastCompleted)?.end == Calendar.current.dateInterval(of: .day, for: today)?.start {
            // Consecutive day
            currentStreak += 1
        } else {
            // Start new streak
            currentStreak = 1
        }

        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }

    func resetStreak() {
        currentStreak = 0
        lastCompletedDate = nil
    }

    var isCompletedToday: Bool {
        guard let lastCompleted = lastCompletedDate else { return false }
        return Calendar.current.isDate(lastCompleted, inSameDayAs: Date())
    }

    func canMarkCompleted() -> Bool {
        return !isCompletedToday
    }

    // MARK: - Enhanced Business Logic for Phase 3

    /// Enhanced completion tracking with grace period logic
    func markCompletedWithTracking(notes: String = "", mood: HabitCompletion.Mood = .neutral) -> HabitCompletion? {
        let today = Calendar.current.startOfDay(for: Date())

        // Check if already completed today
        if isCompletedToday {
            return nil
        }

        // Create completion entry
        let completion = HabitCompletion(
            habit: self,
            completedDate: today,
            notes: notes,
            mood: mood
        )

        // Update streak with grace period logic
        updateStreakWithGracePeriod(completionDate: today)

        // Clear grace period if we were in one
        if isInGracePeriod {
            isInGracePeriod = false
            gracePeriodExpiryDate = nil
        }

        lastCompletedDate = today
        return completion
    }

    /// Skip habit with reason tracking
    func skipHabit(reason: HabitSkip.SkipReason, notes: String = "") -> HabitSkip {
        let today = Calendar.current.startOfDay(for: Date())

        let skip = HabitSkip(
            habit: self,
            skippedDate: today,
            reason: reason,
            notes: notes
        )

        // Handle grace period logic for skips
        handleSkipGracePeriod(skipDate: today, reason: reason)

        return skip
    }

    /// Check if habit should be due based on recurrence rule
    func isDueOn(date: Date) -> Bool {
        guard let recurrenceRule = recurrenceRule else {
            // No recurrence rule means flexible habit - due every day
            return true
        }

        return recurrenceRule.matches(date: date, relativeTo: createdDate)
    }

    /// Get next due date based on recurrence rule
    func nextDueDate(after date: Date = Date()) -> Date? {
        guard let recurrenceRule = recurrenceRule else {
            // Flexible habit - next day
            return Calendar.current.date(byAdding: .day, value: 1, to: date)
        }

        return recurrenceRule.nextOccurrence(after: date)
    }

    /// Calculate completion rate over a period
    func completionRate(over days: Int) -> Double {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) else {
            return 0.0
        }

        let completedDays = completionEntries.filter { completion in
            completion.completedDate >= startDate && completion.completedDate <= endDate
        }.count

        let totalDueDays = dueDaysInPeriod(from: startDate, to: endDate)
        guard totalDueDays > 0 else { return 0.0 }

        return Double(completedDays) / Double(totalDueDays)
    }

    // MARK: - Private Helper Methods

    private func updateStreakWithGracePeriod(completionDate: Date) {
        guard let lastCompleted = lastCompletedDate else {
            // First completion
            currentStreak = 1
            return
        }

        let calendar = Calendar.current
        let daysBetween = calendar.dateComponents([.day], from: lastCompleted, to: completionDate).day ?? 0

        if daysBetween == 1 {
            // Consecutive day
            currentStreak += 1
        } else if daysBetween <= gracePeriodDays + 1 {
            // Within grace period
            currentStreak += 1
        } else {
            // Too many days missed, restart streak
            currentStreak = 1
        }

        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }
    }

    private func handleSkipGracePeriod(skipDate: Date, reason: HabitSkip.SkipReason) {
        let calendar = Calendar.current

        // Some skip reasons preserve streaks
        switch reason {
        case .vacation, .sick, .emergency:
            // Don't break streak, extend grace period
            let extendedGracePeriod = calendar.date(byAdding: .day, value: gracePeriodDays, to: skipDate)
            gracePeriodExpiryDate = extendedGracePeriod
            isInGracePeriod = true
        case .noTime, .forgotTo, .notMotivated, .other:
            // Standard grace period logic applies
            if !isInGracePeriod {
                let gracePeriodEnd = calendar.date(byAdding: .day, value: gracePeriodDays, to: skipDate)
                gracePeriodExpiryDate = gracePeriodEnd
                isInGracePeriod = true
            }
        }
    }

    private func dueDaysInPeriod(from startDate: Date, to endDate: Date) -> Int {
        guard let recurrenceRule = recurrenceRule else {
            // Flexible habit - every day is due
            let calendar = Calendar.current
            return calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        }

        let occurrences = recurrenceRule.occurrences(from: startDate, limit: 100)
        return occurrences.filter { $0 <= endDate }.count
    }
}

// MARK: - Skip Functionality

class HabitSkip {
    enum SkipReason: String, CaseIterable, Codable {
        case vacation = "vacation"
        case sick = "sick"
        case emergency = "emergency"
        case noTime = "no_time"
        case forgotTo = "forgot_to"
        case notMotivated = "not_motivated"
        case other = "other"

        var displayName: String {
            switch self {
            case .vacation: return "Vacation"
            case .sick: return "Sick"
            case .emergency: return "Emergency"
            case .noTime: return "No Time"
            case .forgotTo: return "Forgot To"
            case .notMotivated: return "Not Motivated"
            case .other: return "Other"
            }
        }

        var preservesStreak: Bool {
            switch self {
            case .vacation, .sick, .emergency:
                return true
            case .noTime, .forgotTo, .notMotivated, .other:
                return false
            }
        }
    }

    let id: UUID
    weak var habit: Habit?
    let skippedDate: Date
    let reason: SkipReason
    let notes: String
    let createdDate: Date

    init(habit: Habit, skippedDate: Date, reason: SkipReason, notes: String = "") {
        self.id = UUID()
        self.habit = habit
        self.skippedDate = skippedDate
        self.reason = reason
        self.notes = notes
        self.createdDate = Date()
    }
}