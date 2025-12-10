//
//  NavigationManager.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
import SwiftData

@Observable
class NavigationManager {

    // MARK: - Tab Selection State

    /// Currently selected tab
    var selectedTab: TabType = .today

    // MARK: - Error State

    /// Error message to show in alert
    var errorMessage: String?

    /// Whether error alert is showing
    var showingErrorAlert: Bool = false

    // MARK: - Navigation Paths

    /// Independent NavigationPath for each tab to maintain separate navigation stacks
    var todayPath = NavigationPath()
    var tasksPath = NavigationPath()
    var habitsPath = NavigationPath()
    var logbookPath = NavigationPath()
    var settingsPath = NavigationPath()

    // MARK: - Dependencies

    /// ModelContext for fetching entities when handling deep links
    private var modelContext: ModelContext?

    // MARK: - Initialization

    init(modelContext: ModelContext? = nil) {
        self.selectedTab = .today
        self.modelContext = modelContext
    }

    /// Set the model context after initialization (for cases where context is not available at init time)
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
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
        case .logbook:
            return logbookPath
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
        case .logbook:
            return Binding(
                get: { self.logbookPath },
                set: { self.logbookPath = $0 }
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
        case .logbook:
            logbookPath = NavigationPath()
        case .settings:
            settingsPath = NavigationPath()
        }
    }

    // MARK: - Deep Linking Support

    /// Navigate to a specific item from a deep link
    /// Supports URLs like: daisydos://task/{uuid}, daisydos://habit/{uuid}, daisydos://today
    func handleDeepLink(url: URL) {
        // Parse URL into NavigationRoute
        guard let route = NavigationRoute.parse(from: url) else {
            #if DEBUG
            print("NavigationManager: Failed to parse deep link URL: \(url)")
            #endif
            return
        }

        // Navigate using the parsed route
        navigate(to: route)
    }

    /// Navigate to a specific route
    func navigate(to route: NavigationRoute) {
        switch route {
        case .today:
            switchToTab(.today)
        case .tasks:
            switchToTab(.tasks)
        case .habits:
            switchToTab(.habits)
        case .logbook:
            switchToTab(.logbook)
        case .settings:
            switchToTab(.settings)
        case .task(let uuid):
            guard let task = fetchTask(by: uuid) else {
                #if DEBUG
                print("NavigationManager: Task with ID \(uuid) not found")
                #endif
                // Show error and fallback to Tasks tab
                showError("Task not found. It may have been deleted.")
                switchToTab(.tasks)
                return
            }
            navigateToTask(task)
        case .habit(let uuid):
            guard let habit = fetchHabit(by: uuid) else {
                #if DEBUG
                print("NavigationManager: Habit with ID \(uuid) not found")
                #endif
                // Show error and fallback to Habits tab
                showError("Habit not found. It may have been deleted.")
                switchToTab(.habits)
                return
            }
            navigateToHabit(habit)
        }
    }

    // MARK: - Error Handling

    /// Show an error message to the user
    private func showError(_ message: String) {
        errorMessage = message
        showingErrorAlert = true
    }

    /// Navigate to a specific task (switches to Tasks tab and pushes task detail)
    func navigateToTask(_ task: Task) {
        // Switch to Tasks tab
        selectedTab = .tasks
        // Clear existing navigation stack
        tasksPath = NavigationPath()
        // Push task onto navigation stack
        tasksPath.append(task)
    }

    /// Navigate to a specific habit (switches to Habits tab and pushes habit detail)
    func navigateToHabit(_ habit: Habit) {
        // Switch to Habits tab
        selectedTab = .habits
        // Clear existing navigation stack
        habitsPath = NavigationPath()
        // Push habit onto navigation stack
        habitsPath.append(habit)
    }

    // MARK: - Entity Fetching

    /// Fetch a task by UUID from SwiftData
    private func fetchTask(by id: UUID) -> Task? {
        guard let context = modelContext else { return nil }

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.id == id
            }
        )

        return try? context.fetch(descriptor).first
    }

    /// Fetch a habit by UUID from SwiftData
    private func fetchHabit(by id: UUID) -> Habit? {
        guard let context = modelContext else { return nil }

        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.id == id
            }
        )

        return try? context.fetch(descriptor).first
    }

    // MARK: - State Preservation (Future)

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