//
//  HabitManager.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData

@Observable
class HabitManager {
    private let modelContext: ModelContext

    // Error handling
    var lastError: (any RecoverableError)?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Computed Properties for Filtered Data

    var allHabits: [Habit] {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdDate, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var activeHabits: [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.currentStreak >= 0
            },
            sortBy: [SortDescriptor(\.currentStreak, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var completedTodayHabits: [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.isCompletedToday == true
            },
            sortBy: [SortDescriptor(\.currentStreak, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var pendingTodayHabits: [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.isCompletedToday == false
            },
            sortBy: [SortDescriptor(\.currentStreak, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var habitsByStreak: [Habit] {
        let descriptor = FetchDescriptor<Habit>(
            sortBy: [SortDescriptor(\.currentStreak, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - CRUD Operations

    func createHabit(title: String, habitDescription: String = "") -> Result<Habit, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "create habit",
            entityType: "habit"
        ) {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DaisyDosError.validationFailed("title")
            }

            let habit = Habit(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                habitDescription: habitDescription.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            modelContext.insert(habit)
            try modelContext.save()
            return habit
        }
    }

    func updateHabit(_ habit: Habit, title: String? = nil, habitDescription: String? = nil) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "update habit",
            entityType: "habit"
        ) {
            var hasChanges = false

            if let title = title {
                let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedTitle.isEmpty else {
                    throw DaisyDosError.validationFailed("title")
                }
                habit.title = trimmedTitle
                hasChanges = true
            }

            if let habitDescription = habitDescription {
                habit.habitDescription = habitDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                hasChanges = true
            }

            if hasChanges {
                habit.modifiedDate = Date()
                try modelContext.save()
            }
        }
    }

    func markHabitCompleted(_ habit: Habit) -> Bool {
        guard habit.canMarkCompleted() else {
            return false // Already completed today
        }

        habit.markCompleted()

        do {
            try modelContext.save()
            return true
        } catch {
            lastError = ErrorTransformer.transformHabitError(error, operation: "mark habit completed")
            return false
        }
    }

    /// Mark habit completed with detailed tracking
    func markHabitCompletedWithTracking(_ habit: Habit, notes: String = "", mood: HabitCompletion.Mood = .neutral) -> HabitCompletion? {
        guard habit.canMarkCompleted() else {
            return nil // Already completed today
        }

        let completion = habit.markCompletedWithTracking(notes: notes, mood: mood)

        if let completion = completion {
            modelContext.insert(completion)
        }

        do {
            try modelContext.save()
            return completion
        } catch {
            lastError = ErrorTransformer.transformHabitError(error, operation: "mark habit completed with tracking")
            return nil
        }
    }

    /// Undo today's habit completion
    func undoHabitCompletion(_ habit: Habit) -> Bool {
        guard habit.undoTodaysCompletion() else {
            return false // Nothing to undo
        }

        do {
            try modelContext.save()
            return true
        } catch {
            lastError = ErrorTransformer.transformHabitError(error, operation: "undo habit completion")
            return false
        }
    }

    func skipHabit(_ habit: Habit, reason: String? = nil) -> HabitSkip? {
        guard let skip = habit.skipHabit(reason: reason) else {
            return nil // Already completed or skipped today
        }

        // Insert the skip into the model context
        modelContext.insert(skip)

        do {
            try modelContext.save()
            return skip
        } catch {
            lastError = ErrorTransformer.transformHabitError(error, operation: "skip habit")
            return nil
        }
    }

    func resetHabitStreak(_ habit: Habit) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "reset habit streak",
            entityType: "habit"
        ) {
            habit.resetStreak()
            try modelContext.save()
        }
    }

    func deleteHabit(_ habit: Habit) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "delete habit",
            entityType: "habit"
        ) {
            modelContext.delete(habit)
            try modelContext.save()
        }
    }

    func deleteHabits(_ habits: [Habit]) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "delete habits",
            entityType: "habits"
        ) {
            for habit in habits {
                modelContext.delete(habit)
            }
            try modelContext.save()
        }
    }

    // MARK: - Tag Management

    func addTag(_ tag: Tag, to habit: Habit) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "add tag to habit",
            entityType: "habit"
        ) {
            guard habit.addTag(tag) else {
                throw DaisyDosError.tagLimitExceeded
            }
            try modelContext.save()
        }
    }

    func removeTag(_ tag: Tag, from habit: Habit) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "remove tag from habit",
            entityType: "habit"
        ) {
            habit.removeTag(tag)
            try modelContext.save()
        }
    }

    // MARK: - Search and Filtering

    func searchHabits(query: String) -> [Habit] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allHabits
        }

        // Manual filtering because habitDescription is a computed property
        // and can't be used in #Predicate
        return allHabits.filter { habit in
            habit.title.localizedStandardContains(query) ||
            habit.habitDescription.localizedStandardContains(query)
        }
    }

    func habitsWithTag(_ tag: Tag) -> [Habit] {
        // For now, fetch all habits and filter in memory since @Predicate with contains is complex
        return allHabits.filter { habit in
            habit.tags.contains { $0.id == tag.id }
        }
    }

    // MARK: - Statistics and Analytics

    var habitCount: Int {
        allHabits.count
    }

    var completedTodayCount: Int {
        completedTodayHabits.count
    }

    var pendingTodayCount: Int {
        pendingTodayHabits.count
    }

    var todayCompletionRate: Double {
        guard habitCount > 0 else { return 0.0 }
        return Double(completedTodayCount) / Double(habitCount)
    }

    var averageStreak: Double {
        let habits = allHabits
        guard !habits.isEmpty else { return 0.0 }
        let totalStreak = habits.reduce(0) { $0 + $1.currentStreak }
        return Double(totalStreak) / Double(habits.count)
    }

    var longestActiveStreak: Int {
        allHabits.map(\.currentStreak).max() ?? 0
    }

    var longestEverStreak: Int {
        allHabits.map(\.longestStreak).max() ?? 0
    }

    // MARK: - Helper Properties

    var habitsCompletableToday: [Habit] {
        allHabits.filter { $0.canMarkCompleted() }
    }

    var habitsDueToday: [Habit] {
        // For now, all habits are considered "due" every day
        // This can be enhanced with recurrence rules in future phases
        return allHabits
    }
}