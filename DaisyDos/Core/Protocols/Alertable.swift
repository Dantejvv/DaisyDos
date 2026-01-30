//
//  Alertable.swift
//  DaisyDos
//
//  Protocol for items that support time-of-day alert notifications
//  Provides shared logic for computing alert state based on instance lifecycle
//

import Foundation

/// Protocol for items (Tasks, Habits) that support alert notifications
/// Both Tasks and Habits can have time-of-day alerts that fire on their scheduled days
protocol Alertable {
    // MARK: - Required Properties

    var id: UUID { get }
    var title: String { get }

    /// Hour component of alert time (0-23), nil if no alert configured
    var alertTimeHour: Int? { get set }

    /// Minute component of alert time (0-59), nil if no alert configured
    var alertTimeMinute: Int? { get set }

    /// Whether the notification has been delivered for this instance
    var notificationFired: Bool { get set }

    /// Optional snooze override time - when set, overrides normal alert time
    var snoozedUntil: Date? { get set }

    /// When the current instance started (for instance-based alert tracking)
    /// - For habits: set at replenishment time
    /// - For tasks: typically the dueDate for recurring tasks
    var currentInstanceDate: Date? { get }

    /// Whether this item is completed for the current instance
    /// - For tasks: `isCompleted`
    /// - For habits: `isCompletedToday`
    var isItemCompleted: Bool { get }

    // MARK: - Computed Properties (implemented by conforming types)

    var hasAlert: Bool { get }
    var effectiveReminderDate: Date? { get }
    var hasPendingAlert: Bool { get }
    var reminderDisplayText: String? { get }
}

// MARK: - Default Implementations

extension Alertable {
    /// Whether this item has an alert configured
    var hasAlert: Bool {
        alertTimeHour != nil
    }

    /// Computes the effective reminder date for this instance
    /// Returns nil if no alert configured or no active instance
    var effectiveReminderDate: Date? {
        // If snoozed, use the snooze time
        if let snoozed = snoozedUntil {
            return snoozed
        }

        guard let hour = alertTimeHour, let minute = alertTimeMinute else {
            return nil
        }

        // Must have an active instance to have an effective reminder
        guard let instanceDate = currentInstanceDate else {
            return nil
        }

        // Apply alert time to the instance date
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: instanceDate)
        components.hour = hour
        components.minute = minute
        components.second = 0

        return calendar.date(from: components)
    }

    /// Whether there's a pending (future, unfired) alert for this instance
    var hasPendingAlert: Bool {
        // No pending alert if instance is completed
        guard !isItemCompleted else { return false }

        guard let date = effectiveReminderDate else { return false }
        return date > Date() && !notificationFired
    }

    /// Display text for the alert time (e.g., "9:00 AM")
    var reminderDisplayText: String? {
        guard let hour = alertTimeHour, let minute = alertTimeMinute else {
            return nil
        }

        // Only show reminder text if there's an active instance
        guard currentInstanceDate != nil else {
            return nil
        }

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        guard let date = Calendar.current.date(from: components) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
