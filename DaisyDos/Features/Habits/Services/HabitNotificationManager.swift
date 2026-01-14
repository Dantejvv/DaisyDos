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
        return "habit_reminder"
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
        let completeAction = UNNotificationAction(
            identifier: "complete_habit",
            title: "Mark Complete ✓",
            options: [.foreground]
        )

        let skipAction = UNNotificationAction(
            identifier: "skip_habit",
            title: "Skip Today",
            options: []
        )

        let snoozeAction = UNNotificationAction(
            identifier: "snooze_habit",
            title: "Snooze 1 Hour",
            options: []
        )

        let habitCategory = UNNotificationCategory(
            identifier: notificationCategoryIdentifier,
            actions: [completeAction, skipAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        notificationCenter.setNotificationCategories([habitCategory])
    }

    // MARK: - Habit Notification Scheduling (One-Shot Pattern)

    /// Schedules a one-shot notification for the habit's next occurrence.
    /// This mirrors TaskNotificationManager's approach - schedule once, reschedule on completion.
    func scheduleHabitReminder(for habit: Habit) {
        guard isNotificationsEnabled && isPermissionGranted else { return }
        guard !habit.isCompletedToday else { return } // Don't schedule if already completed today

        // Remove existing notification first
        removeHabitNotification(habitId: habit.id.uuidString)

        // Only schedule if habit has a reminder date set
        guard let reminderDate = habit.reminderDate else { return }

        // Only schedule if reminder date is in the future
        guard reminderDate > Date() else { return }

        // Reset notification fired state since we're scheduling a new notification
        habit.notificationFired = false

        let identifier = "habit_\(habit.id.uuidString)"

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder"
        content.body = habit.title
        content.sound = .default
        content.categoryIdentifier = notificationCategoryIdentifier
        content.userInfo = [
            "habit_id": habit.id.uuidString,
            "habit_title": habit.title
        ]
        content.badge = NSNumber(value: getPendingHabitsCount())

        // Schedule using absolute time interval (one-shot, like tasks)
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
                print("Failed to schedule habit notification: \(error)")
            }
        }
    }

    func removeHabitNotification(habitId: String) {
        let identifier = "habit_\(habitId)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func removeHabitNotification(for habit: Habit) {
        removeHabitNotification(habitId: habit.id.uuidString)
    }

    func scheduleAllHabitNotifications() {
        guard isNotificationsEnabled && isPermissionGranted else { return }

        let habits = getAllHabits()
        for habit in habits where !habit.isCompletedToday {
            scheduleHabitReminder(for: habit)
        }
    }

    func removeAllHabitNotifications() {
        _Concurrency.Task {
            await removeNotifications(withPrefix: "habit_")
        }
    }

    // MARK: - Snooze Functionality

    func snoozeHabit(_ habit: Habit, by interval: TimeInterval = 3600) {
        removeHabitNotification(habitId: habit.id.uuidString)

        // Reset notification fired state since we're scheduling a new snoozed notification
        habit.notificationFired = false

        let identifier = "habit_\(habit.id.uuidString)"

        let content = UNMutableNotificationContent()
        content.title = "Habit Reminder (Snoozed)"
        content.body = habit.title
        content.sound = .default
        content.badge = NSNumber(value: getPendingHabitsCount())
        content.categoryIdentifier = notificationCategoryIdentifier
        content.userInfo = [
            "habit_id": habit.id.uuidString,
            "habit_title": habit.title
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

    // MARK: - Notification Handling

    func handleNotificationAction(identifier: String, habitId: String) async -> Bool {
        guard let habit = getHabit(by: habitId) else { return false }

        let habitManager = HabitManager(modelContext: modelContext)

        switch identifier {
        case "complete_habit":
            return habitManager.markHabitCompleted(habit)

        case "skip_habit":
            return habitManager.skipHabit(habit) != nil

        case "snooze_habit":
            snoozeHabit(habit)
            return true

        default:
            return false
        }
    }

    // MARK: - Helper Methods

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
        return await getScheduledNotificationsCount(prefix: "habit_")
    }
}