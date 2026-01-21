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
    // Note: Overdue reminders removed - notifications are now controlled solely by alert settings

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
        guard let taskId = notification.userInfo?["taskId"] as? String else { return }

        // SwiftData ModelContext is not thread-safe - ensure main thread access
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let task = self.getTask(by: taskId) else { return }

            // Reschedule notifications for the changed task
            self.scheduleTaskReminder(for: task)

            #if DEBUG
            print("Rescheduled notifications for task '\(task.title)' after change")
            #endif
        }
    }

    @objc private func taskWasDeleted(_ notification: Foundation.Notification) {
        guard let taskId = notification.userInfo?["taskId"] as? String else { return }

        // Notification removal doesn't need SwiftData access, safe to call directly
        removeTaskNotification(taskId: taskId)

        #if DEBUG
        print("Removed notifications for deleted task (ID: \(taskId))")
        #endif
    }

    @objc private func taskWasCompleted(_ notification: Foundation.Notification) {
        guard let taskId = notification.userInfo?["taskId"] as? String else { return }

        // Notification removal doesn't need SwiftData access, safe to call directly
        removeTaskNotification(taskId: taskId)

        #if DEBUG
        print("Removed notifications for completed task (ID: \(taskId))")
        #endif
    }

    @objc private func globalNotificationSettingChanged(_ notification: Foundation.Notification) {
        guard let enabled = notification.userInfo?["enabled"] as? Bool else { return }

        // Ensure main thread for SwiftData access in schedule/remove methods
        DispatchQueue.main.async { [weak self] in
            self?.isNotificationsEnabled = enabled

            #if DEBUG
            print("Global notification setting changed to: \(enabled ? "enabled" : "disabled")")
            #endif
        }
    }

    // MARK: - Action Registration

    func registerNotificationActions() async {
        // Categories are registered centrally in DaisyDosApp.registerNotificationCategories()
        // to ensure all categories are set in a single call (per Apple guidelines)
    }

    // MARK: - Task Notification Scheduling

    func scheduleTaskReminder(for task: Task) {
        guard isNotificationsEnabled && isPermissionGranted else { return }
        guard !task.isCompleted else { return } // Don't schedule for completed tasks

        // Remove existing notifications
        removeTaskNotification(taskId: task.id.uuidString)

        // Use effectiveReminderDate which handles both absolute and relative reminders
        guard let reminderDate = task.effectiveReminderDate else {
            return
        }

        // Only schedule if reminder date is in the future
        guard reminderDate > Date() else {
            return
        }

        // Reset notification fired state since we're scheduling a new notification
        task.notificationFired = false

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

        // Schedule the notification using the absolute reminder date
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: reminderDate.timeIntervalSinceNow,
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
    }

    func removeTaskNotification(taskId: String) {
        let identifier = "task_\(taskId)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
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
        let identifier = "task_\(task.id.uuidString)"

        // Remove both pending AND delivered notifications to prevent markDeliveredNotificationsAsFired
        // from re-marking this task as fired during cold start
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])

        // Update task state for snooze
        task.notificationFired = false
        task.snoozedUntil = Date().addingTimeInterval(interval)

        // Schedule new notification after snooze interval
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder (Snoozed)"
        content.body = task.title
        content.sound = .default
        content.badge = NSNumber(value: getPendingTasksCount())
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
