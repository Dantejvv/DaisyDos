//
//  TaskNotificationManager.swift
//  DaisyDos
//
//  Created by Claude Code on 12/01/25.
//

import Foundation
import UserNotifications
import SwiftData

@Observable
class TaskNotificationManager: BaseNotificationManager {
    // MARK: - BaseNotificationManager Protocol Requirements

    let modelContext: ModelContext
    let notificationCenter = UNUserNotificationCenter.current()

    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var isPermissionGranted: Bool = false

    var notificationCategoryIdentifier: String {
        return "task_reminder"
    }

    var isNotificationsEnabled: Bool = true {
        didSet {
            if !isNotificationsEnabled {
                removeAllTaskNotifications()
            } else {
                scheduleAllTaskNotifications()
            }
        }
    }

    // MARK: - Task-Specific Settings

    // Overdue reminder settings
    var enableOverdueReminders: Bool = true
    var overdueReminderInterval: TimeInterval = 3600 // 1 hour after due

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkNotificationPermissions()
        setupNotificationObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Reactive Scheduling

    private func setupNotificationObservers() {
        // Observe task changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(taskDidChange(_:)),
            name: .taskDidChange,
            object: nil
        )

        // Observe task deletions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(taskWasDeleted(_:)),
            name: .taskWasDeleted,
            object: nil
        )

        // Observe task completions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(taskWasCompleted(_:)),
            name: .taskWasCompleted,
            object: nil
        )

        // Observe global notification setting changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(globalNotificationSettingChanged(_:)),
            name: .globalNotificationSettingChanged,
            object: nil
        )
    }

    @objc private func taskDidChange(_ notification: Foundation.Notification) {
        guard let taskId = notification.userInfo?["taskId"] as? String,
              let task = getTask(by: taskId) else {
            return
        }

        // Reschedule notifications for the changed task
        scheduleTaskReminder(for: task)

        #if DEBUG
        print("Rescheduled notifications for task '\(task.title)' after change")
        #endif
    }

    @objc private func taskWasDeleted(_ notification: Foundation.Notification) {
        guard let taskId = notification.userInfo?["taskId"] as? String else {
            return
        }

        removeTaskNotification(taskId: taskId)

        #if DEBUG
        print("Removed notifications for deleted task (ID: \(taskId))")
        #endif
    }

    @objc private func taskWasCompleted(_ notification: Foundation.Notification) {
        guard let taskId = notification.userInfo?["taskId"] as? String else {
            return
        }

        // Remove notifications when task is completed
        removeTaskNotification(taskId: taskId)

        #if DEBUG
        print("Removed notifications for completed task (ID: \(taskId))")
        #endif
    }

    @objc private func globalNotificationSettingChanged(_ notification: Foundation.Notification) {
        guard let enabled = notification.userInfo?["enabled"] as? Bool else { return }

        isNotificationsEnabled = enabled

        #if DEBUG
        print("Global notification setting changed to: \(enabled ? "enabled" : "disabled")")
        #endif
    }

    // MARK: - Action Registration

    func registerNotificationActions() async {
        let completeAction = UNNotificationAction(
            identifier: "complete_task",
            title: "Mark Complete ✓",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "snooze_task",
            title: "Snooze 1 Hour",
            options: []
        )

        let taskCategory = UNNotificationCategory(
            identifier: notificationCategoryIdentifier,
            actions: [completeAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        notificationCenter.setNotificationCategories([taskCategory])
    }

    // MARK: - Task Notification Scheduling

    func scheduleTaskReminder(for task: Task) {
        guard isNotificationsEnabled && isPermissionGranted else { return }
        guard !task.isCompleted else { return } // Don't schedule for completed tasks

        // Remove existing notifications
        removeTaskNotification(taskId: task.id.uuidString)

        // Only schedule if task has a due date
        guard let dueDate = task.dueDate else { return }

        // Only schedule if task has an alert time interval set
        guard let alertInterval = task.alertTimeInterval else {
            // No alert set for this task, but still check for overdue reminders
            if enableOverdueReminders {
                scheduleOverdueReminder(for: task)
            }
            return
        }

        let identifier = "task_\(task.id.uuidString)"

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default
        content.categoryIdentifier = notificationCategoryIdentifier
        content.userInfo = [
            "task_id": task.id.uuidString,
            "task_title": task.title
        ]
        content.badge = NSNumber(value: getPendingTasksCount())

        // Calculate alert time using task's specific alert interval
        let alertDate = dueDate.addingTimeInterval(alertInterval)

        // Only schedule if alert date is in the future
        guard alertDate > Date() else {
            // Task alert time has passed, check if we should schedule overdue reminder
            scheduleOverdueReminder(for: task)
            return
        }

        // Schedule the notification
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: alertDate.timeIntervalSinceNow,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule task notification: \(error)")
            }
        }

        // Schedule overdue reminder if enabled
        if enableOverdueReminders {
            scheduleOverdueReminder(for: task)
        }
    }

    private func scheduleOverdueReminder(for task: Task) {
        guard enableOverdueReminders else { return }
        guard let dueDate = task.dueDate else { return }
        guard !task.isCompleted else { return }

        let overdueDate = dueDate.addingTimeInterval(overdueReminderInterval)

        // Only schedule if overdue date is in the future
        guard overdueDate > Date() else { return }

        let identifier = "task_overdue_\(task.id.uuidString)"

        let content = UNMutableNotificationContent()
        content.title = "Task Overdue ⚠️"
        content.body = task.title
        content.sound = .default
        content.categoryIdentifier = notificationCategoryIdentifier
        content.userInfo = [
            "task_id": task.id.uuidString,
            "task_title": task.title,
            "is_overdue": true
        ]
        content.badge = NSNumber(value: getPendingTasksCount())

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: overdueDate.timeIntervalSinceNow,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule overdue reminder: \(error)")
            }
        }
    }

    func removeTaskNotification(taskId: String) {
        let identifier = "task_\(taskId)"
        let overdueIdentifier = "task_overdue_\(taskId)"

        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [identifier, overdueIdentifier]
        )
    }

    func scheduleAllTaskNotifications() {
        guard isNotificationsEnabled && isPermissionGranted else { return }

        let tasks = getAllTasks()
        for task in tasks where !task.isCompleted {
            scheduleTaskReminder(for: task)
        }
    }

    func removeAllTaskNotifications() {
        // Use base protocol's removeNotifications method
        _Concurrency.Task {
            await removeNotifications(withPrefix: "task_")
        }
    }

    // MARK: - Snooze Functionality

    func snoozeTask(_ task: Task, by interval: TimeInterval = 3600) {
        // Remove existing notification
        removeTaskNotification(taskId: task.id.uuidString)

        // Schedule new notification after snooze interval
        let identifier = "task_\(task.id.uuidString)"

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder (Snoozed)"
        content.body = task.title
        content.sound = .default
        content.categoryIdentifier = notificationCategoryIdentifier
        content.userInfo = [
            "task_id": task.id.uuidString,
            "task_title": task.title
        ]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to snooze task notification: \(error)")
            } else {
                #if DEBUG
                print("Snoozed task '\(task.title)' for \(interval / 60) minutes")
                #endif
            }
        }
    }

    // MARK: - Helper Methods

    private func getAllTasks() -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.parentTask == nil // Only root tasks
            },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func getTask(by id: String) -> Task? {
        guard let uuid = UUID(uuidString: id) else { return nil }

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.id == uuid
            }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func getPendingTasksCount() -> Int {
        let tasks = getAllTasks()
        return tasks.filter { !$0.isCompleted && $0.dueDate != nil }.count
    }

    // MARK: - Settings Management

    func getScheduledNotificationsCount() async -> Int {
        // Use base protocol's getScheduledNotificationsCount method
        return await getScheduledNotificationsCount(prefix: "task_")
    }
}
