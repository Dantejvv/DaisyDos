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
class HabitNotificationManager {
    private let modelContext: ModelContext
    private let notificationCenter = UNUserNotificationCenter.current()

    // Permission status
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var isPermissionGranted: Bool = false

    // Settings
    var isNotificationsEnabled: Bool = true {
        didSet {
            if !isNotificationsEnabled {
                removeAllHabitNotifications()
            } else {
                scheduleAllHabitNotifications()
            }
        }
    }

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
    }

    // MARK: - Permission Management

    func requestNotificationPermissions() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            await MainActor.run {
                self.isPermissionGranted = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }

            if granted {
                await registerNotificationActions()
            }

            return granted
        } catch {
            print("Failed to request notification permissions: \(error)")
            return false
        }
    }

    private func checkNotificationPermissions() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    private func registerNotificationActions() async {
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
            identifier: "habit_reminder",
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
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])

        // Create new notification
        let content = UNMutableNotificationContent()
        content.title = "Time for your habit!"
        content.body = habit.title
        content.sound = .default
        content.categoryIdentifier = "habit_reminder"
        content.userInfo = [
            "habit_id": habit.id.uuidString,
            "habit_title": habit.title
        ]

        // Add badge and sound
        content.badge = NSNumber(value: getPendingHabitsCount())

        // Schedule for recurring notification based on habit's recurrence rule
        if let recurrenceRule = habit.recurrenceRule {
            scheduleRecurringNotification(content: content, identifier: identifier, time: time, recurrenceRule: recurrenceRule)
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

    private func scheduleRecurringNotification(content: UNMutableNotificationContent, identifier: String, time: DateComponents, recurrenceRule: RecurrenceRule) {
        switch recurrenceRule.frequency {
        case .daily:
            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
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
                    weeklyTime.weekday = day // day is already an Int

                    let weeklyTrigger = UNCalendarNotificationTrigger(dateMatching: weeklyTime, repeats: true)
                    let weeklyRequest = UNNotificationRequest(
                        identifier: "\(identifier)_\(index)",
                        content: content,
                        trigger: weeklyTrigger
                    )

                    notificationCenter.add(weeklyRequest) { error in
                        if let error = error {
                            print("Failed to schedule weekly habit notification: \(error)")
                        }
                    }
                }
            }

        case .monthly:
            // For monthly habits, schedule on the day of month
            if let dayOfMonth = recurrenceRule.dayOfMonth {
                var monthlyTime = time
                monthlyTime.day = dayOfMonth

                let trigger = UNCalendarNotificationTrigger(dateMatching: monthlyTime, repeats: true)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                notificationCenter.add(request) { error in
                    if let error = error {
                        print("Failed to schedule monthly habit notification: \(error)")
                    }
                }
            }

        case .yearly:
            // For yearly habits, schedule on the same day each year (simplified approach)
            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            notificationCenter.add(request) { error in
                if let error = error {
                    print("Failed to schedule yearly habit notification: \(error)")
                }
            }

        case .custom:
            // For custom recurrence, fall back to daily notification
            let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
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
        notificationCenter.removeAllPendingNotificationRequests()
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
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        return pendingRequests.filter { $0.identifier.hasPrefix("habit_") }.count
    }
}

// MARK: - Extensions

extension HabitNotificationManager {
    enum NotificationError: Error {
        case permissionDenied
        case habitNotFound
        case schedulingFailed

        var localizedDescription: String {
            switch self {
            case .permissionDenied:
                return "Notification permission denied"
            case .habitNotFound:
                return "Habit not found"
            case .schedulingFailed:
                return "Failed to schedule notification"
            }
        }
    }
}