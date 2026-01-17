//
//  TabRoutes.swift
//  DaisyDos
//
//  Created by Claude Code on 1/15/26.
//
//  Type-safe route enums for each tab's NavigationStack.
//  These enums define all possible navigation destinations within each tab,
//  enabling type-safe programmatic navigation and deep linking.
//

import Foundation

// MARK: - Today Tab Routes

/// Routes for the Today tab's NavigationStack
/// Today can navigate to both Task and Habit details since it shows both
enum TodayRoute: Hashable {
    /// Navigate to task detail view
    case taskDetail(Task)
    /// Navigate to habit detail view
    case habitDetail(Habit)
}

// MARK: - Tasks Tab Routes

/// Routes for the Tasks tab's NavigationStack
enum TasksRoute: Hashable {
    /// Navigate to task detail view
    case detail(Task)
    /// Navigate to task detail in logbook mode (read-only for completed tasks)
    case logbookDetail(Task)
}

// MARK: - Habits Tab Routes

/// Routes for the Habits tab's NavigationStack
enum HabitsRoute: Hashable {
    /// Navigate to habit detail view
    case detail(Habit)
}

// MARK: - Logbook Tab Routes

/// Routes for the Logbook tab's NavigationStack
enum LogbookRoute: Hashable {
    /// Navigate to completed task detail (logbook mode)
    case taskDetail(Task)
}

// MARK: - Settings Tab Routes

/// Routes for the Settings tab's NavigationStack
/// Currently empty as Settings uses sheet presentations, but available for future expansion
enum SettingsRoute: Hashable {
    // Future routes can be added here, e.g.:
    // case notificationSettings
    // case appearanceSettings
    // case privacySettings
}
