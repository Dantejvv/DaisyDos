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
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    // MARK: - Dependencies

    private let navigationManager: NavigationManager
    private let habitManager: HabitManager
    private let taskManager: TaskManager
    private let taskNotificationManager: TaskNotificationManager
    private let habitNotificationManager: HabitNotificationManager

    // MARK: - Initialization

    init(
        navigationManager: NavigationManager,
        habitManager: HabitManager,
        taskManager: TaskManager,
        taskNotificationManager: TaskNotificationManager,
        habitNotificationManager: HabitNotificationManager
    ) {
        self.navigationManager = navigationManager
        self.habitManager = habitManager
        self.taskManager = taskManager
        self.taskNotificationManager = taskNotificationManager
        self.habitNotificationManager = habitNotificationManager
        super.init()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when a notification is delivered while the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
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
            // Complete the habit
            completeHabit(uuid: uuid)

        case "skip_habit":
            // Skip the habit for today (user won't do it)
            skipHabit(uuid: uuid)

        case "snooze_habit":
            // Snooze the notification reminder by 1 hour
            snoozeHabit(uuid: uuid)

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself (not an action button)
            // Navigate to habit detail using deep link
            navigateToHabit(uuid: uuid)

        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification - do nothing
            break

        default:
            break
        }
    }

    // MARK: - Task Notification Handling

    private func handleTaskNotificationResponse(taskID: String, actionIdentifier: String) {
        guard let uuid = UUID(uuidString: taskID) else { return }

        switch actionIdentifier {
        case "complete_task":
            // Complete the task
            completeTask(uuid: uuid)

        case "snooze_task":
            // Snooze the task
            snoozeTask(uuid: uuid)

        case UNNotificationDefaultActionIdentifier:
            // User tapped the notification itself
            // Navigate to task detail using deep link
            navigateToTask(uuid: uuid)

        case UNNotificationDismissActionIdentifier:
            // User dismissed the notification - do nothing
            break

        default:
            break
        }
    }

    // MARK: - Navigation Helpers

    private func navigateToHabit(uuid: UUID) {
        // Fetch the habit from the database
        guard let habit = fetchHabit(by: uuid) else {
            #if DEBUG
            print("NotificationDelegate: Could not find habit with ID \(uuid)")
            #endif
            return
        }

        // Use NavigationManager to navigate to the habit
        navigationManager.navigateToHabit(habit)
    }

    private func navigateToTask(uuid: UUID) {
        // Fetch the task from the database
        guard let task = fetchTask(by: uuid) else {
            #if DEBUG
            print("NotificationDelegate: Could not find task with ID \(uuid)")
            #endif
            return
        }

        // Use NavigationManager to navigate to the task
        navigationManager.navigateToTask(task)
    }

    // MARK: - Action Handlers

    private func completeHabit(uuid: UUID) {
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
        // Fetch the habit
        guard let habit = fetchHabit(by: uuid) else {
            #if DEBUG
            print("NotificationDelegate: Could not find habit \(uuid) to skip")
            #endif
            return
        }

        // Skip habit using HabitManager
        if habitManager.skipHabit(habit, reason: "Skipped from notification") != nil {
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
        let context = habitManager.modelContext

        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.id == id
            }
        )

        return try? context.fetch(descriptor).first
    }

    private func fetchTask(by id: UUID) -> Task? {
        let context = taskManager.modelContext

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.id == id
            }
        )

        return try? context.fetch(descriptor).first
    }
}
