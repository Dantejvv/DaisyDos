//
//  HabitNotificationManager.swift
//  DaisyDos
//
//  Created by Claude Code on 9/30/25.
//
//  REFACTORED: Now uses one-shot notifications like TaskNotificationManager
//  instead of repeating calendar triggers. This ensures notifications
//  are properly removed when habits are completed.
//

import Foundation
import UserNotifications
import SwiftData

@Observable
class HabitNotificationManager: BaseNotificationManager {
    // MARK: - BaseNotificationManager Protocol Requirements

    let modelContext: ModelContext
    let notificationCenter = UNUserNotificationCenter.current()

    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var isPermissionGranted: Bool = false

    var notificationCategoryIdentifier: String {
        return NotificationConstants.habitCategory
    }

    var isNotificationsEnabled: Bool = true {
        didSet {
            if !isNotificationsEnabled {
                removeAllHabitNotifications()
            } else {
                scheduleAllHabitNotifications()
            }
        }
    }

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
        // Observe habit changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(habitDidChange(_:)),
            name: .habitDidChange,
            object: nil
        )

        // Observe habit deletions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(habitWasDeleted(_:)),
            name: .habitWasDeleted,
            object: nil
        )

        // Observe habit completions - reschedule for next occurrence
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(habitWasCompleted(_:)),
            name: .habitWasCompleted,
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

    @objc private func habitDidChange(_ notification: Foundation.Notification) {
        guard let habitId = notification.userInfo?["habitId"] as? String else { return }

        // SwiftData ModelContext is not thread-safe - ensure main thread access
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let habit = self.getHabit(by: habitId) else { return }

            self.scheduleHabitReminder(for: habit)

            #if DEBUG
            print("Rescheduled notifications for habit '\(habit.title)' after change")
            #endif
        }
    }

    @objc private func habitWasDeleted(_ notification: Foundation.Notification) {
        guard let habitId = notification.userInfo?["habitId"] as? String else { return }

        // Notification removal doesn't need SwiftData access, safe to call directly
        removeHabitNotification(habitId: habitId)

        #if DEBUG
        print("Removed notifications for deleted habit (ID: \(habitId))")
        #endif
    }

    @objc private func habitWasCompleted(_ notification: Foundation.Notification) {
        guard let habitId = notification.userInfo?["habitId"] as? String else { return }

        // SwiftData ModelContext is not thread-safe - ensure main thread access
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let habit = self.getHabit(by: habitId) else { return }

            // Reschedule for next occurrence (removes today's, schedules tomorrow's)
            self.scheduleHabitReminder(for: habit)

            #if DEBUG
            print("Rescheduled notifications for completed habit '\(habit.title)'")
            #endif
        }
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

    // MARK: - Habit Notification Scheduling (One-Shot Pattern)

    /// Schedules a one-shot notification for the habit's next occurrence.
    /// This mirrors TaskNotificationManager's approach - schedule once, reschedule on completion.
    func scheduleHabitReminder(for habit: Habit) {
        #if DEBUG
        print("📣 scheduleHabitReminder called for '\(habit.title)'")
        print("   - isNotificationsEnabled: \(isNotificationsEnabled)")
        print("   - isPermissionGranted: \(isPermissionGranted)")
        print("   - isCompletedToday: \(habit.isCompletedToday)")
        print("   - effectiveReminderDate: \(habit.effectiveReminderDate?.description ?? "nil")")
        #endif

        guard isNotificationsEnabled && isPermissionGranted else {
            #if DEBUG
            print("   ❌ Skipped: notifications disabled or no permission")
            #endif
            return
        }
        guard !habit.isCompletedToday else {
            #if DEBUG
            print("   ❌ Skipped: habit is completed today")
            #endif
            return
        }

        // Remove existing notification first
        removeHabitNotification(habitId: habit.id.uuidString)

        // Use effectiveReminderDate which handles both absolute and relative reminders
        guard let reminderDate = habit.effectiveReminderDate else {
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
        habit.notificationFired = false
        // Explicit save for consistency
        try? modelContext.save()

        let identifier = "\(NotificationConstants.habitPrefix)\(habit.id.uuidString)"

        #if DEBUG
        print("   ✅ Scheduling notification:")
        print("      - identifier: \(identifier)")
        print("      - reminderDate: \(reminderDate)")
        print("      - isSnoozed: \(habit.snoozedUntil != nil)")
        #endif

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.body = habit.title
        content.sound = .default
        content.categoryIdentifier = notificationCategoryIdentifier
        content.userInfo = [
            NotificationConstants.habitIdKey: habit.id.uuidString,
            NotificationConstants.habitTitleKey: habit.title
        ]
        content.badge = NSNumber(value: getPendingHabitsCount())

        // Use UNCalendarNotificationTrigger for non-snoozed notifications (absolute date, idempotent).
        // Snoozed notifications use UNTimeIntervalNotificationTrigger (relative from now).
        let trigger: UNNotificationTrigger
        if habit.snoozedUntil != nil {
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
                print("   ❌ Failed to schedule habit notification: \(error)")
            } else {
                #if DEBUG
                print("   ✅ Successfully added notification request to system")
                #endif
            }
        }
    }

    func removeHabitNotification(habitId: String) {
        let identifier = "\(NotificationConstants.habitPrefix)\(habitId)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func removeHabitNotification(for habit: Habit) {
        removeHabitNotification(habitId: habit.id.uuidString)
    }

    func scheduleAllHabitNotifications() {
        guard isNotificationsEnabled && isPermissionGranted else { return }

        let habits = getAllHabits().filter { !$0.isCompletedToday }

        // Fetch all pending notifications in a single batch to avoid redundant remove+add cycles
        notificationCenter.getPendingNotificationRequests { [weak self] pendingRequests in
            guard let self = self else { return }

            // Build a lookup of existing pending notifications by identifier
            let pendingByID = Dictionary(uniqueKeysWithValues:
                pendingRequests.map { ($0.identifier, $0) }
            )

            DispatchQueue.main.async {
                for habit in habits {
                    let identifier = "\(NotificationConstants.habitPrefix)\(habit.id.uuidString)"

                    // If a notification already exists with a matching trigger date, skip it
                    if let existing = pendingByID[identifier],
                       let targetDate = habit.effectiveReminderDate,
                       self.triggerMatchesDate(existing.trigger, targetDate: targetDate) {
                        #if DEBUG
                        print("⏭️ Skipping habit '\(habit.title)' - notification already scheduled correctly")
                        #endif
                        continue
                    }

                    self.scheduleHabitReminder(for: habit)
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

    func removeAllHabitNotifications() {
        _Concurrency.Task {
            await removeNotifications(withPrefix: NotificationConstants.habitPrefix)
        }
    }

    // MARK: - Snooze Functionality

    func snoozeHabit(_ habit: Habit, by interval: TimeInterval = NotificationConstants.snoozeDuration) {
        let identifier = "\(NotificationConstants.habitPrefix)\(habit.id.uuidString)"

        // Remove both pending AND delivered notifications to prevent markDeliveredNotificationsAsFired
        // from re-marking this habit as fired during cold start
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])

        // Update habit state for snooze (mirrors Task snooze implementation)
        habit.notificationFired = false
        habit.snoozedUntil = Date().addingTimeInterval(interval)

        // Explicit save required for cold-start scenarios where iOS may terminate
        // the app before SwiftData autosave completes
        try? modelContext.save()

        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder (Snoozed)"
        content.body = habit.title
        content.sound = .default
        content.badge = NSNumber(value: getPendingHabitsCount())
        content.categoryIdentifier = notificationCategoryIdentifier
        content.userInfo = [
            NotificationConstants.habitIdKey: habit.id.uuidString,
            NotificationConstants.habitTitleKey: habit.title
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
                print("Failed to snooze habit notification: \(error)")
            } else {
                #if DEBUG
                print("Snoozed habit '\(habit.title)' for \(interval / 60) minutes")
                #endif
            }
        }
    }

    // MARK: - Helper Methods
    // NOTE: Notification actions (complete, skip, snooze) are handled directly by NotificationDelegate,
    // which has access to the shared HabitManager instance. This avoids duplicate manager issues.

    private func getAllHabits() -> [Habit] {
        let descriptor = FetchDescriptor<Habit>(sortBy: [SortDescriptor(\.createdDate, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func getHabit(by id: String) -> Habit? {
        guard let uuid = UUID(uuidString: id) else { return nil }

        let descriptor = FetchDescriptor<Habit>(
            predicate: #Predicate<Habit> { habit in
                habit.id == uuid
            }
        )
        return try? modelContext.fetch(descriptor).first
    }

    private func getPendingHabitsCount() -> Int {
        let habits = getAllHabits()
        return habits.filter { !$0.isCompletedToday && !$0.isSkippedToday }.count
    }

    // MARK: - Settings Management

    func getScheduledNotificationsCount() async -> Int {
        return await getScheduledNotificationsCount(prefix: NotificationConstants.habitPrefix)
    }
}