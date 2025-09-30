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

    func createHabit(title: String, habitDescription: String = "") -> Habit {
        let habit = Habit(title: title, habitDescription: habitDescription)
        modelContext.insert(habit)

        do {
            try modelContext.save()
        } catch {
            lastError = ErrorTransformer.transformHabitError(error, operation: "create habit")
        }

        return habit
    }

    func updateHabit(_ habit: Habit, title: String? = nil, habitDescription: String? = nil) {
        if let title = title {
            habit.title = title
        }
        if let habitDescription = habitDescription {
            habit.habitDescription = habitDescription
        }

        do {
            try modelContext.save()
        } catch {
            lastError = ErrorTransformer.transformHabitError(error, operation: "update habit")
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

    func skipHabit(_ habit: Habit, reason: String? = nil) -> HabitSkip? {
        let skip = habit.skipHabit(reason: reason)

        do {
            try modelContext.save()
            return skip
        } catch {
            lastError = ErrorTransformer.transformHabitError(error, operation: "skip habit")
            return nil
        }
    }

    func resetHabitStreak(_ habit: Habit) {
        habit.resetStreak()

        do {
            try modelContext.save()
        } catch {
            print("Failed to reset habit streak: \(error)")
        }
    }

    func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete habit: \(error)")
        }
    }

    func deleteHabits(_ habits: [Habit]) {
        for habit in habits {
            modelContext.delete(habit)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete habits: \(error)")
        }
    }

    // MARK: - Tag Management

    func addTag(_ tag: Tag, to habit: Habit) -> Bool {
        let success = habit.addTag(tag)
        if success {
            do {
                try modelContext.save()
            } catch {
                print("Failed to add tag to habit: \(error)")
                return false
            }
        }
        return success
    }

    func removeTag(_ tag: Tag, from habit: Habit) {
        habit.removeTag(tag)

        do {
            try modelContext.save()
        } catch {
            print("Failed to remove tag from habit: \(error)")
        }
    }

    // MARK: - Search and Filtering

    func searchHabits(query: String) -> [Habit] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allHabits
        }

        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.title.localizedStandardContains(query) ||
                habit.habitDescription.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
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