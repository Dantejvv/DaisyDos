//
//  TodayItem.swift
//  DaisyDos
//
//  Created by Claude Code on 1/2/25.
//

import Foundation

/// Unified representation of both tasks and habits for the Today view
enum TodayItem: Identifiable, Hashable {
    case task(Task)
    case habit(Habit)

    var id: UUID {
        switch self {
        case .task(let task):
            return task.id
        case .habit(let habit):
            return habit.id
        }
    }

    /// Title of the item (task or habit)
    var title: String {
        switch self {
        case .task(let task):
            return task.title
        case .habit(let habit):
            return habit.title
        }
    }

    /// Priority level for sorting
    var priority: Priority {
        switch self {
        case .task(let task):
            return task.priority
        case .habit(let habit):
            return habit.priority
        }
    }

    /// Due/scheduled time for sorting
    /// Tasks: dueDate, Habits: no explicit time (nil)
    var sortTime: Date? {
        switch self {
        case .task(let task):
            return task.dueDate
        case .habit:
            return nil // Habits don't have specific times, sort to bottom
        }
    }

    /// Creation date for sorting
    var createdDate: Date {
        switch self {
        case .task(let task):
            return task.createdDate
        case .habit(let habit):
            return habit.createdDate
        }
    }

    /// Due date for sorting (tasks only)
    var dueDate: Date? {
        switch self {
        case .task(let task):
            return task.dueDate
        case .habit:
            return nil
        }
    }

    /// Check if item is overdue (only applicable to tasks)
    var isOverdue: Bool {
        switch self {
        case .task(let task):
            return task.hasOverdueStatus
        case .habit:
            return false
        }
    }

    /// Check if item is completed/done for today
    var isCompletedToday: Bool {
        switch self {
        case .task(let task):
            return task.isCompleted
        case .habit(let habit):
            return habit.isCompletedToday
        }
    }

    /// Get the underlying task (if this is a task)
    var asTask: Task? {
        if case .task(let task) = self {
            return task
        }
        return nil
    }

    /// Get the underlying habit (if this is a habit)
    var asHabit: Habit? {
        if case .habit(let habit) = self {
            return habit
        }
        return nil
    }

    // MARK: - Hashable & Equatable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TodayItem, rhs: TodayItem) -> Bool {
        lhs.id == rhs.id
    }
}
