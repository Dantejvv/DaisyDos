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
        return NotificationConstants.taskCategory
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
        #if DEBUG
        print("📣 scheduleTaskReminder called for '\(task.title)'")
        print("   - isNotificationsEnabled: \(isNotificationsEnabled)")
        print("   - isPermissionGranted: \(isPermissionGranted)")
        print("   - isCompleted: \(task.isCompleted)")
        print("   - effectiveReminderDate: \(task.effectiveReminderDate?.description ?? "nil")")
        #endif

        guard isNotificationsEnabled && isPermissionGranted else {
            #if DEBUG
            print("   ❌ Skipped: notifications disabled or no permission")
            #endif
            return
        }
        guard !task.isCompleted else {
            #if DEBUG
            print("   ❌ Skipped: task is completed")
            #endif
            return
        }

        // Remove existing notifications
        removeTaskNotification(taskId: task.id.uuidString)

        // Use effectiveReminderDate which handles both absolute and relative reminders
        guard let reminderDate = task.effectiveReminderDate else {
            #if DEBUG
            print("   ❌ Skipped: no effectiveReminderDate")
            #endif
            return
        }

        // Only schedule if reminder date is in the future
        guard reminderDate > Date() else {
            #if DEBUG
            print("   ❌ Skipped: reminderDate is in the past (\(reminderDate))")
            #endif
            return
        }

        // Reset notification fired state since we're scheduling a new notification
        task.notificationFired = false
        // Explicit save for consistency
        try? modelContext.save()

        let identifier = "\(NotificationConstants.taskPrefix)\(task.id.uuidString)"

        #if DEBUG
        print("   ✅ Scheduling notification:")
        print("      - identifier: \(identifier)")
        print("      - reminderDate: \(reminderDate)")
        print("      - isSnoozed: \(task.snoozedUntil != nil)")
        #endif

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = task.title
        content.sound = .default
        content.categoryIdentifier = notificationCategoryIdentifier
        content.userInfo = [
            NotificationConstants.taskIdKey: task.id.uuidString,
            NotificationConstants.taskTitleKey: task.title
        ]
        content.badge = NSNumber(value: getPendingTasksCount())

        // Use UNCalendarNotificationTrigger for non-snoozed notifications (absolute date, idempotent).
        // Snoozed notifications use UNTimeIntervalNotificationTrigger (relative from now).
        let trigger: UNNotificationTrigger
        if task.snoozedUntil != nil {
            let timeInterval = reminderDate.timeIntervalSinceNow
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(timeInterval, 1), repeats: false)
        } else {
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: reminderDate
            )
            trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        }

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("   ❌ Failed to schedule task notification: \(error)")
            } else {
                #if DEBUG
                print("   ✅ Successfully added notification request to system")
                #endif
            }
        }
    }

    func removeTaskNotification(taskId: String) {
        let identifier = "\(NotificationConstants.taskPrefix)\(taskId)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func scheduleAllTaskNotifications() {
        guard isNotificationsEnabled && isPermissionGranted else { return }

        let tasks = getAllTasks().filter { !$0.isCompleted }

        // Fetch all pending notifications in a single batch to avoid redundant remove+add cycles
        notificationCenter.getPendingNotificationRequests { [weak self] pendingRequests in
            guard let self = self else { return }

            // Build a lookup of existing pending notifications by identifier
            let pendingByID = Dictionary(uniqueKeysWithValues:
                pendingRequests.map { ($0.identifier, $0) }
            )

            DispatchQueue.main.async {
                for task in tasks {
                    let identifier = "\(NotificationConstants.taskPrefix)\(task.id.uuidString)"

                    // If a notification already exists with a matching trigger date, skip it
                    if let existing = pendingByID[identifier],
                       let targetDate = task.effectiveReminderDate,
                       self.triggerMatchesDate(existing.trigger, targetDate: targetDate) {
                        #if DEBUG
                        print("⏭️ Skipping task '\(task.title)' - notification already scheduled correctly")
                        #endif
                        continue
                    }

                    self.scheduleTaskReminder(for: task)
                }
            }
        }
    }

    // MARK: - Trigger Comparison

    /// Compares a notification trigger's fire date against an expected date (1-second tolerance).
    /// Works with both UNCalendarNotificationTrigger and UNTimeIntervalNotificationTrigger.
    private func triggerMatchesDate(_ trigger: UNNotificationTrigger?, targetDate: Date) -> Bool {
        guard let trigger = trigger else { return false }

        if let calendarTrigger = trigger as? UNCalendarNotificationTrigger,
           let nextDate = calendarTrigger.nextTriggerDate() {
            return abs(nextDate.timeIntervalSince(targetDate)) < 1.0
        }

        // For time-interval triggers (snoozed notifications), we can't reliably compare
        // since the relative time drifts. Always reschedule these.
        return false
    }

    func removeAllTaskNotifications() {
        _Concurrency.Task {
            await removeNotifications(withPrefix: NotificationConstants.taskPrefix)
        }
    }

    // MARK: - Snooze Functionality

    func snoozeTask(_ task: Task, by interval: TimeInterval = NotificationConstants.snoozeDuration) {
        let identifier = "\(NotificationConstants.taskPrefix)\(task.id.uuidString)"

        // Remove both pending AND delivered notifications to prevent markDeliveredNotificationsAsFired
        // from re-marking this task as fired during cold start
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])

        // Update task state for snooze
        task.notificationFired = false
        task.snoozedUntil = Date().addingTimeInterval(interval)

        // Explicit save required for cold-start scenarios where iOS may terminate
        // the app before SwiftData autosave completes
        try? modelContext.save()

        // Schedule new notification after snooze interval
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder (Snoozed)"
        content.body = task.title
        content.sound = .default
        content.badge = NSNumber(value: getPendingTasksCount())
        content.categoryIdentifier = notificationCategoryIdentifier
        content.userInfo = [
            NotificationConstants.taskIdKey: task.id.uuidString,
            NotificationConstants.taskTitleKey: task.title
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
        return await getScheduledNotificationsCount(prefix: NotificationConstants.taskPrefix)
    }
}
