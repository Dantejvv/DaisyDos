//
//  NotificationDelegate.swift
//  DaisyDos
//
//  Created by Claude Code on 11/30/25.
//

import Foundation
import UserNotifications
import SwiftData

/// Handles notification presentation and user interactions
/// Integrates with NavigationManager for deep linking and managers for actions
///
/// Supports deferred manager injection for cold start scenarios where the delegate
/// must be registered before SwiftData managers are initialized.
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    // MARK: - Dependencies

    private let navigationManager: NavigationManager

    /// Managers are optional to support cold start - they're injected after SwiftData is ready
    private var habitManager: HabitManager?
    private var taskManager: TaskManager?
    private var taskNotificationManager: TaskNotificationManager?
    private var habitNotificationManager: HabitNotificationManager?
    private var badgeManager: BadgeManager?

    /// Whether managers have been injected and are ready for use
    private var managersReady: Bool {
        habitManager != nil && taskManager != nil &&
        taskNotificationManager != nil && habitNotificationManager != nil &&
        badgeManager != nil
    }

    // MARK: - Pending Actions (for cold start)

    /// Stores pending notification actions that arrived before managers were ready
    private struct PendingAction {
        enum ActionType {
            case completeHabit(UUID)
            case skipHabit(UUID)
            case snoozeHabit(UUID)
            case completeTask(UUID)
            case snoozeTask(UUID)
        }
        let action: ActionType
    }

    /// Queue of actions waiting for managers to be ready
    private var pendingActions: [PendingAction] = []

    /// Stores pending markNotificationFired calls that arrived before managers were ready
    private var pendingMarkFiredUserInfos: [[AnyHashable: Any]] = []

    // MARK: - Initialization

    /// Initialize with just navigationManager for early registration in didFinishLaunchingWithOptions
    /// Call setManagers() later when SwiftData context is available
    init(navigationManager: NavigationManager) {
        self.navigationManager = navigationManager
        super.init()
    }

    /// Full initializer for backwards compatibility (when managers are available at init time)
    convenience init(
        navigationManager: NavigationManager,
        habitManager: HabitManager,
        taskManager: TaskManager,
        taskNotificationManager: TaskNotificationManager,
        habitNotificationManager: HabitNotificationManager,
        badgeManager: BadgeManager
    ) {
        self.init(navigationManager: navigationManager)
        self.habitManager = habitManager
        self.taskManager = taskManager
        self.taskNotificationManager = taskNotificationManager
        self.habitNotificationManager = habitNotificationManager
        self.badgeManager = badgeManager
    }

    /// Inject managers after initialization (for cold start scenarios)
    /// This processes any pending actions that arrived before managers were ready
    func setManagers(
        habitManager: HabitManager,
        taskManager: TaskManager,
        taskNotificationManager: TaskNotificationManager,
        habitNotificationManager: HabitNotificationManager,
        badgeManager: BadgeManager
    ) {
        self.habitManager = habitManager
        self.taskManager = taskManager
        self.taskNotificationManager = taskNotificationManager
        self.habitNotificationManager = habitNotificationManager
        self.badgeManager = badgeManager

        #if DEBUG
        print("NotificationDelegate: Managers injected, processing \(pendingActions.count) pending actions and \(pendingMarkFiredUserInfos.count) pending markFired calls")
        #endif

        // Process any pending markNotificationFired calls
        processPendingMarkFired()

        // Process any pending actions
        processPendingActions()
    }

    // MARK: - Pending Action Processing

    private func processPendingActions() {
        let actions = pendingActions
        pendingActions = []

        for pending in actions {
            switch pending.action {
            case .completeHabit(let uuid):
                completeHabit(uuid: uuid)
            case .skipHabit(let uuid):
                skipHabit(uuid: uuid)
            case .snoozeHabit(let uuid):
                snoozeHabit(uuid: uuid)
            case .completeTask(let uuid):
                completeTask(uuid: uuid)
            case .snoozeTask(let uuid):
                snoozeTask(uuid: uuid)
            }
        }
    }

    private func processPendingMarkFired() {
        let userInfos = pendingMarkFiredUserInfos
        pendingMarkFiredUserInfos = []

        for userInfo in userInfos {
            markNotificationFiredSync(userInfo: userInfo)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when a notification is delivered while the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Mark the notification as fired so the bell badge disappears from row views
        let userInfo = notification.request.content.userInfo
        markNotificationFired(userInfo: userInfo)

        // Show notification even when app is in foreground
        // Display banner, play sound, and update badge
        completionHandler([.banner, .sound, .badge])
    }

    /// Called when the user interacts with a notification (tap or action button)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier

        #if DEBUG
        print("NotificationDelegate: didReceive called with action '\(actionIdentifier)', managersReady=\(managersReady)")
        #endif

        // Mark the notification as fired ONLY for non-snooze actions
        // Snooze actions will reschedule the notification, so the alert badge should remain visible
        let isSnoozeAction = actionIdentifier == "snooze_task" || actionIdentifier == "snooze_habit"
        if !isSnoozeAction {
            markNotificationFired(userInfo: userInfo)
        }

        // Handle different notification types
        if let habitID = userInfo["habit_id"] as? String {
            handleHabitNotificationResponse(habitID: habitID, actionIdentifier: actionIdentifier)
        } else if let taskID = userInfo["task_id"] as? String {
            handleTaskNotificationResponse(taskID: taskID, actionIdentifier: actionIdentifier)
        }

        completionHandler()
    }

    // MARK: - Habit Notification Handling

    private func handleHabitNotificationResponse(habitID: String, actionIdentifier: String) {
        guard let uuid = UUID(uuidString: habitID) else { return }

        switch actionIdentifier {
        case "complete_habit":
            // Complete the habit (or queue if managers not ready)
            // No navigation - action runs in background without launching app
            if managersReady {
                completeHabit(uuid: uuid)
            } else {
                pendingActions.append(PendingAction(action: .completeHabit(uuid)))
                #if DEBUG
                print("NotificationDelegate: Queued completeHabit for \(uuid)")
                #endif
            }

        case "skip_habit":
            // Skip the habit for today (or queue if managers not ready)
            // No navigation - action runs in background without launching app
            if managersReady {
                skipHabit(uuid: uuid)
            } else {
                pendingActions.append(PendingAction(action: .skipHabit(uuid)))
                #if DEBUG
                print("NotificationDelegate: Queued skipHabit for \(uuid)")
                #endif
            }

        case "snooze_habit":
            // Snooze the notification reminder (or queue if managers not ready)
            // No navigation - action runs in background without launching app
            if managersReady {
                snoozeHabit(uuid: uuid)
            } else {
                pendingActions.append(PendingAction(action: .snoozeHabit(uuid)))
                #if DEBUG
                print("NotificationDelegate: Queued snoozeHabit for \(uuid)")
                #endif
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself (not an action button)
            // Navigation works immediately - NavigationManager queues if not ready
            navigateToHabit(uuid: uuid)

        default:
            break
        }
    }

    // MARK: - Task Notification Handling

    private func handleTaskNotificationResponse(taskID: String, actionIdentifier: String) {
        guard let uuid = UUID(uuidString: taskID) else { return }

        switch actionIdentifier {
        case "complete_task":
            // Complete the task (or queue if managers not ready)
            // No navigation - action runs in background without launching app
            if managersReady {
                completeTask(uuid: uuid)
            } else {
                pendingActions.append(PendingAction(action: .completeTask(uuid)))
                #if DEBUG
                print("NotificationDelegate: Queued completeTask for \(uuid)")
                #endif
            }

        case "snooze_task":
            // Snooze the task (or queue if managers not ready)
            // No navigation - action runs in background without launching app
            if managersReady {
                snoozeTask(uuid: uuid)
            } else {
                pendingActions.append(PendingAction(action: .snoozeTask(uuid)))
                #if DEBUG
                print("NotificationDelegate: Queued snoozeTask for \(uuid)")
                #endif
            }

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself
            // Navigation works immediately - NavigationManager queues if not ready
            navigateToTask(uuid: uuid)

        default:
            break
        }
    }

    // MARK: - Navigation Helpers

    private func navigateToHabit(uuid: UUID) {
        // Use queued navigation to handle cold start race condition
        // NavigationManager will either navigate immediately (if ready) or queue for later
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            #if DEBUG
            print("NotificationDelegate: Requesting navigation to habit \(uuid)")
            #endif

            // Queue navigation - NavigationManager handles ready state check
            self.navigationManager.queueHabitNavigation(habitID: uuid)
        }
    }

    private func navigateToTask(uuid: UUID) {
        // Use queued navigation to handle cold start race condition
        // NavigationManager will either navigate immediately (if ready) or queue for later
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            #if DEBUG
            print("NotificationDelegate: Requesting navigation to task \(uuid)")
            #endif

            // Queue navigation - NavigationManager handles ready state check
            self.navigationManager.queueTaskNavigation(taskID: uuid)
        }
    }

    // MARK: - Action Handlers

    private func completeHabit(uuid: UUID) {
        guard let habitManager = habitManager else {
            #if DEBUG
            print("NotificationDelegate: Cannot complete habit - habitManager not set")
            #endif
            return
        }

        // Fetch the habit
        guard let habit = fetchHabit(by: uuid) else {
            #if DEBUG
            print("NotificationDelegate: Could not find habit \(uuid) to complete")
            #endif
            return
        }

        // Mark habit as completed using HabitManager
        let success = habitManager.markHabitCompleted(habit)

        #if DEBUG
        if success {
            print("NotificationDelegate: Successfully completed habit '\(habit.title)'")
        } else {
            print("NotificationDelegate: Failed to complete habit '\(habit.title)' (already completed or skipped today)")
        }
        #endif
    }

    private func skipHabit(uuid: UUID) {
        guard let habitManager = habitManager else {
            #if DEBUG
            print("NotificationDelegate: Cannot skip habit - habitManager not set")
            #endif
            return
        }

        // Fetch the habit
        guard let habit = fetchHabit(by: uuid) else {
            #if DEBUG
            print("NotificationDelegate: Could not find habit \(uuid) to skip")
            #endif
            return
        }

        // Skip habit using HabitManager
        if habitManager.skipHabit(habit) != nil {
            #if DEBUG
            print("NotificationDelegate: Successfully skipped habit '\(habit.title)'")
            #endif
        } else {
            #if DEBUG
            print("NotificationDelegate: Failed to skip habit '\(habit.title)' (already completed or skipped today)")
            #endif
        }
    }

    private func snoozeHabit(uuid: UUID) {
        guard let habitNotificationManager = habitNotificationManager else {
            #if DEBUG
            print("NotificationDelegate: Cannot snooze habit - habitNotificationManager not set")
            #endif
            return
        }

        // Fetch the habit
        guard let habit = fetchHabit(by: uuid) else {
            #if DEBUG
            print("NotificationDelegate: Could not find habit \(uuid) to snooze")
            #endif
            return
        }

        // Snooze habit notification for 1 hour
        habitNotificationManager.snoozeHabit(habit, by: 3600) // 1 hour

        #if DEBUG
        print("NotificationDelegate: Successfully snoozed habit '\(habit.title)' for 1 hour")
        #endif
    }

    private func completeTask(uuid: UUID) {
        guard let taskManager = taskManager else {
            #if DEBUG
            print("NotificationDelegate: Cannot complete task - taskManager not set")
            #endif
            return
        }

        // Complete the task using TaskManager
        guard let task = fetchTask(by: uuid) else {
            #if DEBUG
            print("NotificationDelegate: Could not find task \(uuid) to complete")
            #endif
            return
        }

        // Use toggleTaskCompletion to properly set completedDate (required for logbook)
        let result = taskManager.toggleTaskCompletion(task)

        switch result {
        case .success:
            #if DEBUG
            print("NotificationDelegate: Successfully toggled task '\(task.title)' to \(task.isCompleted ? "completed" : "incomplete")")
            #endif

        case .failure(let error):
            #if DEBUG
            print("NotificationDelegate: Failed to toggle task completion: \(error.userMessage)")
            #endif
        }
    }

    private func snoozeTask(uuid: UUID) {
        guard let taskNotificationManager = taskNotificationManager else {
            #if DEBUG
            print("NotificationDelegate: Cannot snooze task - taskNotificationManager not set")
            #endif
            return
        }

        // Fetch the task
        guard let task = fetchTask(by: uuid) else {
            #if DEBUG
            print("NotificationDelegate: Could not find task \(uuid) to snooze")
            #endif
            return
        }

        // Snooze task for 1 hour using TaskNotificationManager
        taskNotificationManager.snoozeTask(task, by: 3600) // 1 hour

        #if DEBUG
        print("NotificationDelegate: Successfully snoozed task '\(task.title)' for 1 hour")
        #endif
    }

    // MARK: - Entity Fetching

    private func fetchHabit(by id: UUID) -> Habit? {
        guard let context = habitManager?.modelContext else { return nil }

        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.id == id
            }
        )

        return try? context.fetch(descriptor).first
    }

    private func fetchTask(by id: UUID) -> Task? {
        guard let context = taskManager?.modelContext else { return nil }

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.id == id
            }
        )

        return try? context.fetch(descriptor).first
    }

    // MARK: - Notification State Tracking

    /// Marks all delivered notifications as fired
    /// Call this when app becomes active to handle notifications delivered while backgrounded
    /// This is necessary because customDismissAction callbacks are unreliable when app is in background
    func markDeliveredNotificationsAsFired() async {
        let center = UNUserNotificationCenter.current()
        let delivered = await center.deliveredNotifications()

        // Extract IDs on current thread, then update on main thread
        var habitIDs: [String] = []
        var taskIDs: [String] = []

        for notification in delivered {
            let userInfo = notification.request.content.userInfo
            if let habitID = userInfo["habit_id"] as? String {
                habitIDs.append(habitID)
            } else if let taskID = userInfo["task_id"] as? String {
                taskIDs.append(taskID)
            }
        }

        // Capture as let constants for Swift 6 concurrency safety
        let capturedHabitIDs = habitIDs
        let capturedTaskIDs = taskIDs

        // Update on main thread for SwiftData safety
        await MainActor.run {
            for habitID in capturedHabitIDs {
                if let uuid = UUID(uuidString: habitID),
                   let habit = fetchHabit(by: uuid) {
                    habit.notificationFired = true
                    #if DEBUG
                    print("NotificationDelegate: Marked delivered habit '\(habit.title)' notification as fired")
                    #endif
                }
            }
            for taskID in capturedTaskIDs {
                if let uuid = UUID(uuidString: taskID),
                   let task = fetchTask(by: uuid) {
                    task.notificationFired = true
                    task.snoozedUntil = nil // Clear snooze state when notification fires
                    #if DEBUG
                    print("NotificationDelegate: Marked delivered task '\(task.title)' notification as fired")
                    #endif
                }
            }
        }
    }

    /// Marks the notification as fired so the bell badge disappears from row views
    /// Called from didReceive delegate - dispatches to main thread for SwiftData safety
    /// If managers aren't ready yet, queues the userInfo for later processing
    private func markNotificationFired(userInfo: [AnyHashable: Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if self.managersReady {
                self.markNotificationFiredSync(userInfo: userInfo)
            } else {
                // Queue for later when managers are ready
                self.pendingMarkFiredUserInfos.append(userInfo)
                #if DEBUG
                print("NotificationDelegate: Queued markNotificationFired (managers not ready)")
                #endif
            }
        }
    }

    /// Internal synchronous implementation - must be called on main thread
    /// Requires managers to be set
    private func markNotificationFiredSync(userInfo: [AnyHashable: Any]) {
        if let habitID = userInfo["habit_id"] as? String,
           let uuid = UUID(uuidString: habitID),
           let habit = fetchHabit(by: uuid) {
            habit.notificationFired = true
            #if DEBUG
            print("NotificationDelegate: Marked habit '\(habit.title)' notification as fired")
            #endif
        } else if let taskID = userInfo["task_id"] as? String,
                  let uuid = UUID(uuidString: taskID),
                  let task = fetchTask(by: uuid) {
            task.notificationFired = true
            task.snoozedUntil = nil // Clear snooze state when notification fires
            #if DEBUG
            print("NotificationDelegate: Marked task '\(task.title)' notification as fired")
            #endif
        }
    }
}
