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

    // MARK: - Pending Navigation (for cold start from notifications)

    /// Stores pending navigation request when app launches from notification before UI is ready
    /// This handles the race condition where notification tap triggers navigation before SwiftData is initialized
    private var pendingTaskNavigation: UUID?
    private var pendingHabitNavigation: UUID?

    /// Whether the navigation system is ready to handle navigation requests
    /// Set to true after modelContext is set AND views have rendered
    private(set) var isReady: Bool = false

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

    /// Mark the navigation system as ready and process any pending navigation
    /// Call this after the UI has fully rendered (e.g., in onAppear of ContentView)
    func markReady() {
        guard !isReady else { return }
        isReady = true

        #if DEBUG
        print("NavigationManager: Marked as ready, processing pending navigation")
        #endif

        processPendingNavigation()
    }

    /// Queue a navigation request for when the app is ready
    /// Used by NotificationDelegate when navigation arrives during cold start
    func queueTaskNavigation(taskID: UUID) {
        if isReady, modelContext != nil {
            // App is ready, navigate immediately
            if let task = fetchTask(by: taskID) {
                navigateToTask(task)
            } else {
                #if DEBUG
                print("NavigationManager: Task \(taskID) not found for immediate navigation")
                #endif
                showError("Task not found. It may have been deleted.")
                switchToTab(.tasks)
            }
        } else {
            // App not ready, queue for later
            #if DEBUG
            print("NavigationManager: Queuing task navigation for \(taskID)")
            #endif
            pendingTaskNavigation = taskID
            pendingHabitNavigation = nil
        }
    }

    /// Queue a habit navigation request for when the app is ready
    func queueHabitNavigation(habitID: UUID) {
        if isReady, modelContext != nil {
            // App is ready, navigate immediately
            if let habit = fetchHabit(by: habitID) {
                navigateToHabit(habit)
            } else {
                #if DEBUG
                print("NavigationManager: Habit \(habitID) not found for immediate navigation")
                #endif
                showError("Habit not found. It may have been deleted.")
                switchToTab(.habits)
            }
        } else {
            // App not ready, queue for later
            #if DEBUG
            print("NavigationManager: Queuing habit navigation for \(habitID)")
            #endif
            pendingHabitNavigation = habitID
            pendingTaskNavigation = nil
        }
    }

    /// Process any pending navigation requests (called when app becomes ready)
    private func processPendingNavigation() {
        if let taskID = pendingTaskNavigation {
            pendingTaskNavigation = nil
            #if DEBUG
            print("NavigationManager: Processing pending task navigation for \(taskID)")
            #endif

            if let task = fetchTask(by: taskID) {
                navigateToTask(task)
            } else {
                #if DEBUG
                print("NavigationManager: Pending task \(taskID) not found")
                #endif
                showError("Task not found. It may have been deleted.")
                switchToTab(.tasks)
            }
        } else if let habitID = pendingHabitNavigation {
            pendingHabitNavigation = nil
            #if DEBUG
            print("NavigationManager: Processing pending habit navigation for \(habitID)")
            #endif

            if let habit = fetchHabit(by: habitID) {
                navigateToHabit(habit)
            } else {
                #if DEBUG
                print("NavigationManager: Pending habit \(habitID) not found")
                #endif
                showError("Habit not found. It may have been deleted.")
                switchToTab(.habits)
            }
        }
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
        // Push task route onto navigation stack
        tasksPath.append(TasksRoute.detail(task))
    }

    /// Navigate to a specific habit (switches to Habits tab and pushes habit detail)
    func navigateToHabit(_ habit: Habit) {
        // Switch to Habits tab
        selectedTab = .habits
        // Clear existing navigation stack
        habitsPath = NavigationPath()
        // Push habit route onto navigation stack
        habitsPath.append(HabitsRoute.detail(habit))
    }

    /// Navigate to a task from Today tab (for notification taps when on Today)
    func navigateToTaskFromToday(_ task: Task) {
        // Switch to Today tab
        selectedTab = .today
        // Clear existing navigation stack
        todayPath = NavigationPath()
        // Push task route onto navigation stack
        todayPath.append(TodayRoute.taskDetail(task))
    }

    /// Navigate to a habit from Today tab (for notification taps when on Today)
    func navigateToHabitFromToday(_ habit: Habit) {
        // Switch to Today tab
        selectedTab = .today
        // Clear existing navigation stack
        todayPath = NavigationPath()
        // Push habit route onto navigation stack
        todayPath.append(TodayRoute.habitDetail(habit))
    }

    /// Navigate to a completed task in logbook
    func navigateToLogbookTask(_ task: Task) {
        // Switch to Logbook tab
        selectedTab = .logbook
        // Clear existing navigation stack
        logbookPath = NavigationPath()
        // Push task route onto navigation stack
        logbookPath.append(LogbookRoute.taskDetail(task))
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
}