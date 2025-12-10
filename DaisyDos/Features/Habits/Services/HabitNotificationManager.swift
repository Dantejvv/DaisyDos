//
//  HabitNotificationManager.swift
//  DaisyDos
//
//  Created by Claude Code on 9/30/25.
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

    // MARK: - Habit-Specific Settings

    // Default reminder time (9:00 AM)
    var defaultReminderTime: DateComponents = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return components
    }()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        checkNotificationPermissions()
        setupNotificationObservers()
    }

    deinit {
        // Remove observers when manager is deallocated
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
    }

    @objc private func habitDidChange(_ notification: Foundation.Notification) {
        guard let habitId = notification.userInfo?["habitId"] as? String,
              let habit = getHabit(by: habitId) else {
            return
        }

        // Reschedule notifications for the changed habit
        scheduleHabitReminder(for: habit)

        #if DEBUG
        print("Rescheduled notifications for habit '\(habit.title)' after change")
        #endif
    }

    @objc private func habitWasDeleted(_ notification: Foundation.Notification) {
        guard let habitId = notification.userInfo?["habitId"] as? String else {
            return
        }

        // Remove notifications for the deleted habit
        let identifier = "habit_\(habitId)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        // Also remove any weekly notifications
        let weeklyIdentifiers = (0..<7).map { "\(identifier)_\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: weeklyIdentifiers)

        #if DEBUG
        print("Removed notifications for deleted habit (ID: \(habitId))")
        #endif
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

        let habitCategory = UNNotificationCategory(
            identifier: notificationCategoryIdentifier,
            actions: [completeAction, skipAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        notificationCenter.setNotificationCategories([habitCategory])
    }

    // MARK: - Habit Notification Scheduling

    func scheduleHabitReminder(for habit: Habit, at reminderTime: DateComponents? = nil) {
        guard isNotificationsEnabled && isPermissionGranted else { return }

        let time = reminderTime ?? defaultReminderTime
        let identifier = "habit_\(habit.id.uuidString)"

        // Remove existing notification
        removeHabitNotification(for: habit)

        // Create new notification
        let content = UNMutableNotificationContent()
        content.title = "Time for your habit!"
        content.body = habit.title
        content.sound = .default
        content.categoryIdentifier = notificationCategoryIdentifier
        content.userInfo = [
            "habit_id": habit.id.uuidString,
            "habit_title": habit.title
        ]

        // Add badge and sound
        content.badge = NSNumber(value: getPendingHabitsCount())

        // Schedule for recurring notification based on habit's recurrence rule
        if let recurrenceRule = habit.recurrenceRule {
            scheduleRecurringNotification(
                content: content,
                identifier: identifier,
                time: time,
                recurrenceRule: recurrenceRule,
                referenceDate: habit.createdDate
            )
        } else {
            // Daily notification for flexible habits
            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule habit notification: \(error)")
                }
            }
        }
    }

    private func scheduleRecurringNotification(
        content: UNMutableNotificationContent,
        identifier: String,
        time: DateComponents,
        recurrenceRule: RecurrenceRule,
        referenceDate: Date
    ) {
        let calendar = Calendar.current

        // Get timezone from recurrence rule
        let timezone = recurrenceRule.timeZone

        switch recurrenceRule.frequency {
        case .daily:
            var dailyTime = time
            dailyTime.timeZone = timezone

            let trigger = UNCalendarNotificationTrigger(dateMatching: dailyTime, repeats: true)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule daily habit notification: \(error)")
                }
            }

        case .weekly:
            // Schedule for each day of the week specified in the recurrence rule
            if let daysOfWeek = recurrenceRule.daysOfWeek {
                for (index, day) in daysOfWeek.enumerated() {
                    var weeklyTime = time
                    weeklyTime.weekday = day
                    weeklyTime.timeZone = timezone

                    let weeklyTrigger = UNCalendarNotificationTrigger(dateMatching: weeklyTime, repeats: true)
                    let weeklyRequest = UNNotificationRequest(
                        identifier: "\(identifier)_\(index)",
                        content: content,
                        trigger: weeklyTrigger
                    )

                    notificationCenter.add(weeklyRequest) { error in
                        if let error = error {
                            print("Failed to schedule weekly habit notification for day \(day): \(error)")
                        }
                    }
                }
            }

        case .monthly:
            // For monthly habits, schedule on the day of month
            if let dayOfMonth = recurrenceRule.dayOfMonth {
                // Handle edge cases: February 29th, days that don't exist in all months
                let validDayOfMonth = min(dayOfMonth, 28) // Cap at 28 to ensure all months work

                var monthlyTime = time
                monthlyTime.day = validDayOfMonth
                monthlyTime.timeZone = timezone

                let trigger = UNCalendarNotificationTrigger(dateMatching: monthlyTime, repeats: true)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                notificationCenter.add(request) { error in
                    if let error = error {
                        print("Failed to schedule monthly habit notification: \(error)")
                    }
                }

                // If original day was > 28, log a warning
                if dayOfMonth > 28 {
                    #if DEBUG
                    print("Monthly notification for day \(dayOfMonth) adjusted to day 28 to avoid missing months")
                    #endif
                }
            }

        case .yearly:
            // For yearly habits, extract month and day from reference date
            let components = calendar.dateComponents([.month, .day], from: referenceDate)

            guard let month = components.month, let day = components.day else {
                print("Failed to extract month/day from reference date for yearly notification")
                return
            }

            // Handle February 29th edge case
            var yearlyDay = day
            if month == 2 && day == 29 {
                yearlyDay = 28 // Move to Feb 28 for non-leap years
                #if DEBUG
                print("Yearly notification for Feb 29 adjusted to Feb 28 for non-leap years")
                #endif
            }

            var yearlyTime = time
            yearlyTime.month = month
            yearlyTime.day = yearlyDay
            yearlyTime.timeZone = timezone

            let trigger = UNCalendarNotificationTrigger(dateMatching: yearlyTime, repeats: true)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule yearly habit notification: \(error)")
                }
            }

        case .custom:
            // For custom recurrence, fall back to daily notification
            var customTime = time
            customTime.timeZone = timezone

            let trigger = UNCalendarNotificationTrigger(dateMatching: customTime, repeats: true)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule custom habit notification: \(error)")
                }
            }
        }
    }

    func removeHabitNotification(for habit: Habit) {
        let identifier = "habit_\(habit.id.uuidString)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        // Also remove any weekly notifications
        let weeklyIdentifiers = (0..<7).map { "\(identifier)_\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: weeklyIdentifiers)
    }

    func scheduleAllHabitNotifications() {
        guard isNotificationsEnabled && isPermissionGranted else { return }

        let habits = getAllHabits()
        for habit in habits {
            scheduleHabitReminder(for: habit)
        }
    }

    func removeAllHabitNotifications() {
        // Use base protocol's removeNotifications method
        _Concurrency.Task {
            await removeNotifications(withPrefix: "habit_")
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

    func updateDefaultReminderTime(hour: Int, minute: Int) {
        defaultReminderTime.hour = hour
        defaultReminderTime.minute = minute

        // Reschedule all notifications with new time
        if isNotificationsEnabled {
            removeAllHabitNotifications()
            scheduleAllHabitNotifications()
        }
    }

    func getScheduledNotificationsCount() async -> Int {
        // Use base protocol's getScheduledNotificationsCount method
        return await getScheduledNotificationsCount(prefix: "habit_")
    }
}