//
//  NavigationRoute.swift
//  DaisyDos
//
//  Created by Claude Code on 11/30/25.
//

import Foundation

/// Type-safe navigation routes for deep linking throughout the app
enum NavigationRoute: Hashable {

    // MARK: - Constants

    /// The URL scheme for deep links
    static let scheme = "daisydos"

    // MARK: - Cases

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
        guard url.scheme == scheme else { return nil }

        // URL structure: scheme://host/path
        // For daisydos://today → host="today", path=""
        // For daisydos://task/uuid → host="task", path="/uuid"
        guard let host = url.host?.lowercased() else { return nil }

        // Get path components for entity routes (removes empty strings and leading slash)
        let pathComponents = url.pathComponents.filter { !$0.isEmpty && $0 != "/" }

        switch host {
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
            guard let uuidString = pathComponents.first,
                  let uuid = UUID(uuidString: uuidString) else {
                return nil
            }
            return .task(uuid)
        case "habit":
            // Requires UUID: daisydos://habit/{uuid}
            guard let uuidString = pathComponents.first,
                  let uuid = UUID(uuidString: uuidString) else {
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

    // MARK: - URL Generation

    /// Generate a URL from this route
    var url: URL? {
        switch self {
        case .today:
            return URL(string: "\(Self.scheme)://today")
        case .tasks:
            return URL(string: "\(Self.scheme)://tasks")
        case .habits:
            return URL(string: "\(Self.scheme)://habits")
        case .logbook:
            return URL(string: "\(Self.scheme)://logbook")
        case .settings:
            return URL(string: "\(Self.scheme)://settings")
        case .task(let uuid):
            return URL(string: "\(Self.scheme)://task/\(uuid.uuidString)")
        case .habit(let uuid):
            return URL(string: "\(Self.scheme)://habit/\(uuid.uuidString)")
        }
    }
}
