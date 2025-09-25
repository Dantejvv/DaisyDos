//
//  NavigationManager.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI

@Observable
class NavigationManager {

    // MARK: - Tab Selection State

    /// Currently selected tab
    var selectedTab: TabType = .today

    // MARK: - Navigation Paths

    /// Independent NavigationPath for each tab to maintain separate navigation stacks
    var todayPath = NavigationPath()
    var tasksPath = NavigationPath()
    var habitsPath = NavigationPath()
    var tagsPath = NavigationPath()
    var settingsPath = NavigationPath()

    // MARK: - Initialization

    init() {
        // Initialize with Today tab selected by default
        self.selectedTab = .today
    }

    // MARK: - Path Management

    /// Get the navigation path for a specific tab
    func path(for tab: TabType) -> NavigationPath {
        switch tab {
        case .today:
            return todayPath
        case .tasks:
            return tasksPath
        case .habits:
            return habitsPath
        case .tags:
            return tagsPath
        case .settings:
            return settingsPath
        }
    }

    /// Get a binding to the navigation path for a specific tab
    func pathBinding(for tab: TabType) -> Binding<NavigationPath> {
        switch tab {
        case .today:
            return Binding(
                get: { self.todayPath },
                set: { self.todayPath = $0 }
            )
        case .tasks:
            return Binding(
                get: { self.tasksPath },
                set: { self.tasksPath = $0 }
            )
        case .habits:
            return Binding(
                get: { self.habitsPath },
                set: { self.habitsPath = $0 }
            )
        case .tags:
            return Binding(
                get: { self.tagsPath },
                set: { self.tagsPath = $0 }
            )
        case .settings:
            return Binding(
                get: { self.settingsPath },
                set: { self.settingsPath = $0 }
            )
        }
    }

    // MARK: - Tab Navigation

    /// Switch to a specific tab
    func switchToTab(_ tab: TabType) {
        selectedTab = tab
    }

    /// Pop to root for the currently selected tab
    func popToRoot() {
        popToRoot(for: selectedTab)
    }

    /// Pop to root for a specific tab
    func popToRoot(for tab: TabType) {
        switch tab {
        case .today:
            todayPath = NavigationPath()
        case .tasks:
            tasksPath = NavigationPath()
        case .habits:
            habitsPath = NavigationPath()
        case .tags:
            tagsPath = NavigationPath()
        case .settings:
            settingsPath = NavigationPath()
        }
    }

    // MARK: - Deep Linking Support (Future)

    /// Navigate to a specific item from a deep link (prepared for future implementation)
    func handleDeepLink(url: URL) {
        // TODO: Implement deep linking in future phase
        // This method provides the foundation for URL-based navigation
    }

    /// Get the current navigation state as a restorable representation
    func getNavigationState() -> [String: Any] {
        // TODO: Implement navigation state preservation for app backgrounding
        return [:]
    }

    /// Restore navigation state from a saved representation
    func restoreNavigationState(_ state: [String: Any]) {
        // TODO: Implement navigation state restoration
    }
}