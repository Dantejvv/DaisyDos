//
//  TodayViewModel.swift
//  DaisyDos
//
//  Created by Claude Code on 1/2/25.
//

import Foundation
import SwiftUI

@Observable
class TodayViewModel {
    /// Unified and sorted list of today's items (tasks + habits)
    private(set) var todayItems: [TodayItem] = []

    /// Build unified list from tasks and habits with time-based sorting
    func buildTodayItems(from tasks: [Task], habits: [Habit]) {
        var items: [TodayItem] = []

        // Add today's tasks (due today + overdue + no date)
        let todayTasks = filterTodayTasks(tasks)
        items.append(contentsOf: todayTasks.map { TodayItem.task($0) })

        // Add today's habits (active today based on recurrence)
        let todayHabits = filterTodayHabits(habits)
        items.append(contentsOf: todayHabits.map { TodayItem.habit($0) })

        // Sort with time-based logic
        todayItems = sortItems(items)
    }

    // MARK: - Private Helpers

    /// Filter tasks that should appear in today view
    private func filterTodayTasks(_ tasks: [Task]) -> [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return tasks.filter { task in
            // Include if:
            // 1. Due today
            if let dueDate = task.dueDate {
                if calendar.isDate(dueDate, inSameDayAs: today) {
                    return true
                }
                // 2. Overdue (past due date, not completed)
                if dueDate < today && !task.isCompleted {
                    return true
                }
            }

            return false
        }
    }

    /// Filter habits that should appear in today view
    private func filterTodayHabits(_ habits: [Habit]) -> [Habit] {
        let today = Date()

        return habits.filter { habit in
            // Check if habit is due today based on recurrence rule
            habit.isDueOn(date: today)
        }
    }

    /// Sort items with time-based logic:
    /// 1. Overdue tasks first (by time, earliest first)
    /// 2. Tasks with times (by time, earliest first)
    /// 3. Tasks without times (by priority)
    /// 4. Habits (by priority)
    private func sortItems(_ items: [TodayItem]) -> [TodayItem] {
        let calendar = Calendar.current
        let now = Date()
        _ = calendar.startOfDay(for: now) // Reference for future time-based logic

        return items.sorted { item1, item2 in
            let isOverdue1 = item1.isOverdue
            let isOverdue2 = item2.isOverdue

            // 1. Overdue items come first
            if isOverdue1 != isOverdue2 {
                return isOverdue1
            }

            let time1 = item1.sortTime
            let time2 = item2.sortTime

            // 2. If both have times, sort by time (earliest first)
            if let t1 = time1, let t2 = time2 {
                return t1 < t2
            }

            // 3. Items with time come before items without time
            if time1 != nil && time2 == nil {
                return true
            }
            if time1 == nil && time2 != nil {
                return false
            }

            // 4. Both have no time, sort by priority (high to low)
            let priority1 = item1.priority.sortOrder
            let priority2 = item2.priority.sortOrder
            if priority1 != priority2 {
                return priority1 > priority2 // Higher sortOrder = higher priority
            }

            // 5. Same priority, sort by type (tasks before habits)
            let isTask1 = item1.asTask != nil
            let isTask2 = item2.asTask != nil
            if isTask1 != isTask2 {
                return isTask1
            }

            // 6. Fallback: alphabetical by title
            return item1.title < item2.title
        }
    }
}
