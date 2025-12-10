//
//  NavigationRoute.swift
//  DaisyDos
//
//  Created by Claude Code on 11/30/25.
//

import Foundation

/// Type-safe navigation routes for deep linking throughout the app
enum NavigationRoute: Hashable {
    /// Navigate to a specific task detail view
    case task(UUID)

    /// Navigate to a specific habit detail view
    case habit(UUID)

    /// Navigate to Today tab (no detail view)
    case today

    /// Navigate to Tasks tab (no detail view)
    case tasks

    /// Navigate to Habits tab (no detail view)
    case habits

    /// Navigate to Logbook tab (no detail view)
    case logbook

    /// Navigate to Settings tab (no detail view)
    case settings

    // MARK: - URL Parsing

    /// Parse a URL into a NavigationRoute
    /// Supports URLs like: daisydos://task/{uuid}, daisydos://habit/{uuid}, daisydos://today
    static func parse(from url: URL) -> NavigationRoute? {
        // Check scheme
        guard url.scheme == "daisydos" else { return nil }

        // Get path components (removes empty strings and leading slash)
        let pathComponents = url.pathComponents.filter { !$0.isEmpty && $0 != "/" }

        guard !pathComponents.isEmpty else { return nil }

        let routeType = pathComponents[0].lowercased()

        switch routeType {
        case "today":
            return .today
        case "tasks":
            return .tasks
        case "habits":
            return .habits
        case "logbook":
            return .logbook
        case "settings":
            return .settings
        case "task":
            // Requires UUID: daisydos://task/{uuid}
            guard pathComponents.count > 1,
                  let uuid = UUID(uuidString: pathComponents[1]) else {
                return nil
            }
            return .task(uuid)
        case "habit":
            // Requires UUID: daisydos://habit/{uuid}
            guard pathComponents.count > 1,
                  let uuid = UUID(uuidString: pathComponents[1]) else {
                return nil
            }
            return .habit(uuid)
        default:
            return nil
        }
    }

    // MARK: - Route Properties

    /// Get the target tab for this route
    var targetTab: TabType {
        switch self {
        case .today:
            return .today
        case .tasks, .task:
            return .tasks
        case .habits, .habit:
            return .habits
        case .logbook:
            return .logbook
        case .settings:
            return .settings
        }
    }

    /// Check if this route requires navigation (vs just tab switching)
    var requiresNavigation: Bool {
        switch self {
        case .task, .habit:
            return true
        case .today, .tasks, .habits, .logbook, .settings:
            return false
        }
    }
}
