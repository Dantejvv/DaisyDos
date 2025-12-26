//
//  NotificationGroup.swift
//  DaisyDos
//
//  Created by Claude Code on 12/22/25.
//

import Foundation

/// Notification grouping strategy for organizing related notifications
/// Uses thread identifiers to group notifications in the notification center
enum NotificationGroup: Equatable {
    case morningHabits    // 6 AM - 12 PM
    case afternoonHabits  // 12 PM - 6 PM
    case eveningHabits    // 6 PM - 12 AM
    case highPriorityTasks
    case dueTodayTasks
    case overdueTasksReminders
    case ungrouped        // Individual notification (no grouping)

    // MARK: - Thread Identifier

    /// Thread identifier for iOS notification grouping
    /// iOS automatically groups notifications with the same thread identifier
    var threadIdentifier: String? {
        switch self {
        case .morningHabits:
            return "habit-morning"
        case .afternoonHabits:
            return "habit-afternoon"
        case .eveningHabits:
            return "habit-evening"
        case .highPriorityTasks:
            return "task-high-priority"
        case .dueTodayTasks:
            return "task-due-today"
        case .overdueTasksReminders:
            return "task-overdue"
        case .ungrouped:
            return nil // No grouping
        }
    }

    // MARK: - Summary Text

    /// Generates summary text for grouped notifications
    /// Used when 4+ notifications share the same thread identifier
    func summaryText(count: Int) -> String {
        switch self {
        case .morningHabits:
            return count == 1 ? "morning habit" : "\(count) morning habits"
        case .afternoonHabits:
            return count == 1 ? "afternoon habit" : "\(count) afternoon habits"
        case .eveningHabits:
            return count == 1 ? "evening habit" : "\(count) evening habits"
        case .highPriorityTasks:
            return count == 1 ? "high priority task" : "\(count) high priority tasks"
        case .dueTodayTasks:
            return count == 1 ? "task due today" : "\(count) tasks due today"
        case .overdueTasksReminders:
            return count == 1 ? "overdue task" : "\(count) overdue tasks"
        case .ungrouped:
            return "" // No summary for ungrouped
        }
    }

    // MARK: - Factory Methods

    /// Determines the appropriate notification group for a task
    static func forTask(_ task: Task) -> NotificationGroup {
        // High priority tasks get their own group
        if task.priority == .high {
            return .highPriorityTasks
        }

        guard let dueDate = task.dueDate else {
            return .ungrouped
        }

        let calendar = Calendar.current
        let now = Date()

        // Check if task is overdue (due time has passed)
        // Use a 1-second tolerance to avoid race conditions with Date() comparisons
        if dueDate.addingTimeInterval(1) < now {
            return .overdueTasksReminders
        }

        // Check if task is due today (but not yet overdue)
        if calendar.isDateInToday(dueDate) {
            return .dueTodayTasks
        }

        // Default: no grouping for other tasks
        return .ungrouped
    }

    /// Determines the appropriate notification group for a habit based on alert time
    /// - Parameter habit: The habit with alertTimeInterval (seconds since midnight)
    /// - Returns: Morning, afternoon, or evening group based on time of day
    static func forHabit(_ habit: Habit) -> NotificationGroup {
        guard let alertTimeInterval = habit.alertTimeInterval else {
            return .ungrouped
        }

        // alertTimeInterval is seconds since midnight (0-86400)
        // Morning: 21600-43200 seconds (6:00 AM - 12:00 PM)
        // Afternoon: 43200-64800 seconds (12:00 PM - 6:00 PM)
        // Evening: 64800-86400 seconds (6:00 PM - 12:00 AM)
        // Before 6 AM (0-21600): Also morning group

        switch alertTimeInterval {
        case 0..<21600:
            return .morningHabits  // 12 AM - 6 AM (early morning)
        case 21600..<43200:
            return .morningHabits  // 6 AM - 12 PM
        case 43200..<64800:
            return .afternoonHabits  // 12 PM - 6 PM
        case 64800..<86400:
            return .eveningHabits  // 6 PM - 12 AM
        default:
            return .ungrouped
        }
    }

    /// Determines notification group for overdue task reminders
    static var overdueReminder: NotificationGroup {
        return .overdueTasksReminders
    }
}
