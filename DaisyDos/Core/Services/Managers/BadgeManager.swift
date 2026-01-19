//
//  BadgeManager.swift
//  DaisyDos
//
//  Created by Claude Code on 1/18/26.
//

import Foundation
import SwiftData
import UserNotifications

/// Manages the app's badge count based on actionable items
///
/// Badge count = (incomplete tasks due today or overdue) + (incomplete habits for today)
///
/// Excludes:
/// - Tasks without a due date
/// - Tasks due in the future
/// - Completed tasks/habits
/// - Skipped habits
@Observable
class BadgeManager {

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Badge Count Computation

    /// Computes the current badge count based on actionable items
    func computeBadgeCount() -> Int {
        let taskCount = getActionableTaskCount()
        let habitCount = getActionableHabitCount()
        return taskCount + habitCount
    }

    /// Returns count of tasks due today or overdue that are incomplete
    /// Excludes tasks without a due date and subtasks
    private func getActionableTaskCount() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let tasks = getAllTasks()
        return tasks.filter { task in
            guard !task.isCompleted,
                  let dueDate = task.dueDate else { return false }

            let dueDayStart = calendar.startOfDay(for: dueDate)
            // Due today OR overdue (past)
            return dueDayStart <= today
        }.count
    }

    /// Returns count of habits not completed or skipped today
    private func getActionableHabitCount() -> Int {
        let habits = getAllHabits()
        return habits.filter { habit in
            !habit.isCompletedToday && !habit.isSkippedToday
        }.count
    }

    // MARK: - Data Fetching

    private func getAllTasks() -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.parentTask == nil // Only root tasks, not subtasks
            }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func getAllHabits() -> [Habit] {
        let descriptor = FetchDescriptor<Habit>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Badge Update

    /// Updates the system badge to reflect current actionable items
    func updateBadge() async {
        let count = computeBadgeCount()

        do {
            try await UNUserNotificationCenter.current().setBadgeCount(count)
            #if DEBUG
            print("BadgeManager: Updated badge to \(count)")
            #endif
        } catch {
            #if DEBUG
            print("BadgeManager: Failed to set badge count: \(error)")
            #endif
        }
    }

    /// Synchronous version that dispatches badge update to background
    func updateBadgeAsync() {
        _Concurrency.Task {
            await updateBadge()
        }
    }

    // MARK: - Notification Observers

    private func setupObservers() {
        let center = NotificationCenter.default

        // Task observers
        center.addObserver(
            self,
            selector: #selector(handleTaskChange),
            name: .taskDidChange,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleTaskChange),
            name: .taskWasDeleted,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleTaskChange),
            name: .taskWasCompleted,
            object: nil
        )

        // Habit observers
        center.addObserver(
            self,
            selector: #selector(handleHabitChange),
            name: .habitDidChange,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleHabitChange),
            name: .habitWasDeleted,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleHabitChange),
            name: .habitWasCompleted,
            object: nil
        )
    }

    @objc private func handleTaskChange(_ notification: Notification) {
        updateBadgeAsync()
    }

    @objc private func handleHabitChange(_ notification: Notification) {
        updateBadgeAsync()
    }
}
