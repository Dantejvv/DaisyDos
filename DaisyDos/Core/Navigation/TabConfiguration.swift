//
//  TabConfiguration.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI

/// Defines the main tabs in the DaisyDos application
enum TabType: String, CaseIterable, Identifiable {
    case today = "today"
    case tasks = "tasks"
    case habits = "habits"
    case tags = "tags"
    case settings = "settings"

    var id: String { rawValue }

    // MARK: - Display Properties

    /// Display name for the tab
    var title: String {
        switch self {
        case .today:
            return "Today"
        case .tasks:
            return "Tasks"
        case .habits:
            return "Habits"
        case .tags:
            return "Tags"
        case .settings:
            return "Settings"
        }
    }

    /// SF Symbol icon for the tab
    var systemImage: String {
        switch self {
        case .today:
            return "calendar"
        case .tasks:
            return "list.bullet"
        case .habits:
            return "repeat.circle"
        case .tags:
            return "tag"
        case .settings:
            return "gearshape"
        }
    }

    // MARK: - Accessibility

    /// Accessibility label for VoiceOver
    var accessibilityLabel: String {
        return title
    }

    /// Accessibility hint for VoiceOver
    var accessibilityHint: String {
        switch self {
        case .today:
            return "View today's tasks and habits"
        case .tasks:
            return "Manage all your tasks"
        case .habits:
            return "Track your habits and streaks"
        case .tags:
            return "Organize with tags and labels"
        case .settings:
            return "App settings and preferences"
        }
    }

    // MARK: - Tab Label Helper

    /// Create a SwiftUI Label for the tab item
    var tabLabel: some View {
        Label(title, systemImage: systemImage)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
    }
}

/// Configuration for tab bar appearance and behavior
struct TabConfiguration {

    // MARK: - Tab Ordering

    /// Default order of tabs in the tab bar
    static let defaultTabOrder: [TabType] = [
        .today,
        .tasks,
        .habits,
        .tags,
        .settings
    ]

    // MARK: - Visual Configuration

    /// Tab bar styling constants following design system
    struct Appearance {
        /// Tab bar background style
        static let backgroundStyle = Material.thin

        /// Selected tab tint color (uses system accent color)
        static let selectedTintColor = Color.accentColor

        /// Unselected tab tint color
        static let unselectedTintColor = Color.secondary

        /// Tab bar height (system default, but documented for reference)
        static let tabBarHeight: CGFloat = 83 // iPhone standard tab bar height
    }

    // MARK: - Badge Configuration (Future)

    /// Configuration for tab badges (notification counts, etc.)
    struct BadgeConfiguration {
        /// Maximum number to display in badge before showing "99+"
        static let maxBadgeCount = 99

        /// Badge color for different types of notifications
        static let defaultBadgeColor = Color.red
        static let habitStreakBadgeColor = Color(.systemGreen)
        static let overdueTasksBadgeColor = Color(.systemOrange)
    }
}

// MARK: - Tab Navigation Extensions

extension TabType {

    /// Check if this tab should show a badge (future functionality)
    func shouldShowBadge() -> Bool {
        // TODO: Implement badge logic in future phases
        return false
    }

    /// Get badge count for this tab (future functionality)
    func badgeCount() -> Int {
        // TODO: Implement badge counting in future phases
        return 0
    }
}