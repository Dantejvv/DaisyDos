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
    @Relationship(deleteRule: .cascade) var completionEntries: [HabitCompletion] = []

    /// Streak history and management
    @Relationship(deleteRule: .cascade) var streaks: [HabitStreak] = []

    /// Skip entries for tracking when habit was skipped
    @Relationship(deleteRule: .cascade) var skips: [HabitSkip] = []

    init(title: String, habitDescription: String = "", recurrenceRule: RecurrenceRule? = nil) {
        self.id = UUID()
        self.title = title
        self.habitDescription = habitDescription
        self.currentStreak = 0
        self.longestStreak = 0
        self.createdDate = Date()
        self.lastCompletedDate = nil
        self.recurrenceRule = recurrenceRule
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

    /// Undo today's completion and recalculate streak
    func undoTodaysCompletion() -> Bool {
        guard isCompletedToday else { return false }

        let today = Calendar.current.startOfDay(for: Date())

        // Remove today's completion entry
        if let todaysCompletion = completionEntries.first(where: { Calendar.current.isDate($0.completedDate, inSameDayAs: today) }) {
            completionEntries.removeAll { $0.id == todaysCompletion.id }
        }

        // Recalculate streak from completion history
        recalculateStreakFromHistory()

        return true
    }

    /// Recalculate current streak based on completion history
    private func recalculateStreakFromHistory() {
        let sortedCompletions = completionEntries.sorted { $0.completedDate > $1.completedDate }

        guard !sortedCompletions.isEmpty else {
            currentStreak = 0
            lastCompletedDate = nil
            return
        }

        let mostRecentCompletion = sortedCompletions.first!
        lastCompletedDate = mostRecentCompletion.completedDate

        // Calculate streak by counting consecutive days from most recent completion
        var streak = 1
        let calendar = Calendar.current

        for i in 1..<sortedCompletions.count {
            let currentDate = sortedCompletions[i-1].completedDate
            let previousDate = sortedCompletions[i].completedDate

            let daysBetween = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0

            if daysBetween == 1 {
                streak += 1
            } else {
                break // Streak broken
            }
        }

        currentStreak = streak
    }

    var isCompletedToday: Bool {
        guard let lastCompleted = lastCompletedDate else { return false }
        return Calendar.current.isDate(lastCompleted, inSameDayAs: Date())
    }

    var isSkippedToday: Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return skips.contains { Calendar.current.isDate($0.skippedDate, inSameDayAs: today) }
    }

    func canMarkCompleted() -> Bool {
        return !isCompletedToday && !isSkippedToday
    }

    func canSkip() -> Bool {
        return !isCompletedToday && !isSkippedToday
    }

    // MARK: - Enhanced Business Logic for Phase 3

    /// Enhanced completion tracking
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

        // Add to completion entries
        completionEntries.append(completion)

        // Update streak with simple consecutive day logic
        updateStreak(completionDate: today)

        lastCompletedDate = today
        return completion
    }

    /// Skip habit with optional reason
    func skipHabit(reason: String? = nil) -> HabitSkip? {
        guard canSkip() else { return nil }

        let today = Calendar.current.startOfDay(for: Date())

        let skip = HabitSkip(
            habit: self,
            skippedDate: today,
            reason: reason
        )

        // Add to skip entries
        skips.append(skip)

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

    private func updateStreak(completionDate: Date) {
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
        } else {
            // Gap in days, restart streak
            currentStreak = 1
        }

        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
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

