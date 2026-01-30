//
//  HabitReplenishmentService.swift
//  DaisyDos
//
//  Manages habit instance replenishment - resetting instance state at replenishment time
//  Unlike tasks (which create new objects), habits persist and have their state reset
//

import Foundation
import SwiftData

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when a habit is replenished (new instance started)
    static let habitReplenished = Notification.Name("habitReplenished")
}

/// Manages habit replenishment - resetting instance state when habits are due for a new period
/// This is the habit equivalent of RecurrenceScheduler for tasks
///
/// Key differences from tasks:
/// - Habits are NOT recreated - they persist as single objects
/// - Replenishment resets `currentInstanceDate` and `notificationFired`
/// - Habits only replenish if the previous instance was completed or skipped
@Observable
class HabitReplenishmentService {
    let modelContext: ModelContext
    private let replenishmentTimeManager: ReplenishmentTimeManager

    init(modelContext: ModelContext, replenishmentTimeManager: ReplenishmentTimeManager = ReplenishmentTimeManager()) {
        self.modelContext = modelContext
        self.replenishmentTimeManager = replenishmentTimeManager
    }

    // MARK: - Processing

    /// Process all habits that are due for replenishment
    /// Should be called when app comes to foreground (alongside processPendingRecurrences)
    func processHabitReplenishments() -> Result<[Habit], AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "process habit replenishments",
            entityType: "habit"
        ) {
            let now = Date()
            let todayReplenishment = replenishmentTimeManager.todayReplenishmentDate

            // Get all habits (we'll filter in memory for more complex logic)
            let descriptor = FetchDescriptor<Habit>()
            let allHabits = try modelContext.fetch(descriptor)

            var replenishedHabits: [Habit] = []

            for habit in allHabits {
                if shouldReplenish(habit, now: now, replenishmentTime: todayReplenishment) {
                    replenishHabit(habit, instanceDate: todayReplenishment)
                    replenishedHabits.append(habit)
                }
            }

            if !replenishedHabits.isEmpty {
                try modelContext.save()

                #if DEBUG
                print("Replenished \(replenishedHabits.count) habit(s)")
                for habit in replenishedHabits {
                    print("   - '\(habit.title)' instance date: \(habit.currentInstanceDate?.formatted() ?? "nil")")
                }
                #endif

                // Notify for each replenished habit (triggers notification scheduling)
                for habit in replenishedHabits {
                    NotificationCenter.default.post(
                        name: .habitReplenished,
                        object: nil,
                        userInfo: ["habitId": habit.id.uuidString]
                    )
                }
            } else {
                #if DEBUG
                print("No habits ready for replenishment")
                #endif
            }

            return replenishedHabits
        }
    }

    // MARK: - Replenishment Logic

    /// Determines if a habit should replenish to a new instance
    /// Returns true if:
    /// 1. We're past today's replenishment time
    /// 2. The habit hasn't already replenished today
    /// 3. The previous instance was completed or skipped (or this is a new habit)
    /// 4. Today is a scheduled day for the recurrence pattern (or habit has no pattern = daily)
    private func shouldReplenish(_ habit: Habit, now: Date, replenishmentTime: Date) -> Bool {
        let calendar = Calendar.current

        // 1. Must be past today's replenishment time
        guard now >= replenishmentTime else {
            return false
        }

        // 2. Check if habit has a valid instance date
        if let instanceDate = habit.currentInstanceDate {
            // Already replenished today?
            if calendar.isDate(instanceDate, inSameDayAs: now) {
                return false
            }

            // 3. Previous instance must be completed or skipped
            // Check if the habit was completed on or after the instance date
            let wasCompleted = wasCompletedDuringInstance(habit, instanceDate: instanceDate)
            let wasSkipped = wasSkippedDuringInstance(habit, instanceDate: instanceDate)

            guard wasCompleted || wasSkipped else {
                #if DEBUG
                print("Habit '\(habit.title)' not replenishing - previous instance incomplete")
                #endif
                return false
            }
        }
        // If no currentInstanceDate, this is a legacy habit or new habit - allow replenishment

        // 4. Check if today is a scheduled day for this habit
        if let recurrenceRule = habit.recurrenceRule {
            // Use the recurrence rule to check if today matches
            return recurrenceRule.matches(date: now, relativeTo: habit.createdDate)
        }

        // Habits without recurrence rules replenish daily
        return true
    }

    /// Check if habit was completed during its instance period
    private func wasCompletedDuringInstance(_ habit: Habit, instanceDate: Date) -> Bool {
        guard let lastCompleted = habit.lastCompletedDate else { return false }
        // Completed on or after the instance started
        return lastCompleted >= Calendar.current.startOfDay(for: instanceDate)
    }

    /// Check if habit was skipped during its instance period
    private func wasSkippedDuringInstance(_ habit: Habit, instanceDate: Date) -> Bool {
        let calendar = Calendar.current
        let instanceDay = calendar.startOfDay(for: instanceDate)

        // Check if any skip entry is on or after the instance date
        return (habit.skips ?? []).contains { skip in
            calendar.startOfDay(for: skip.skippedDate) >= instanceDay
        }
    }

    /// Replenish a habit to a new instance
    /// Resets instance state without modifying completion history
    private func replenishHabit(_ habit: Habit, instanceDate: Date) {
        habit.currentInstanceDate = instanceDate
        habit.notificationFired = false
        habit.snoozedUntil = nil  // Clear any snooze from previous instance
        habit.modifiedDate = Date()

        // Reset all subtask completion states when habit replenishes
        for subtask in (habit.subtasks ?? []) {
            subtask.setCompleted(false)
        }

        #if DEBUG
        print("Replenished habit '\(habit.title)' with instance date: \(instanceDate.formatted())")
        #endif
    }

    // MARK: - Manual Replenishment

    /// Manually replenish a specific habit (useful for testing or admin functions)
    func replenishHabit(_ habit: Habit) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "replenish habit",
            entityType: "habit"
        ) {
            let now = replenishmentTimeManager.todayReplenishmentDate
            replenishHabit(habit, instanceDate: now)
            try modelContext.save()

            NotificationCenter.default.post(
                name: .habitReplenished,
                object: nil,
                userInfo: ["habitId": habit.id.uuidString]
            )
        }
    }
}
