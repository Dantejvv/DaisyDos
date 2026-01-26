//
//  ReplenishmentTimeManager.swift
//  DaisyDos
//
//  Created by Claude Code on 1/25/26.
//  Manages the global replenishment time for recurring tasks and habits
//

import Foundation

/// Notification posted when replenishment time changes
extension Notification.Name {
    static let replenishmentTimeChanged = Notification.Name("replenishmentTimeChanged")
}

/// Manages the global replenishment time for recurring items
/// This is when new instances of recurring tasks/habits become visible each day
@Observable
class ReplenishmentTimeManager {
    // MARK: - UserDefaults Keys

    private static let hourKey = "replenishmentHour"
    private static let minuteKey = "replenishmentMinute"

    // MARK: - Properties

    /// The hour component of replenishment time (0-23)
    /// Default is 6 (6:00 AM)
    var replenishmentHour: Int {
        didSet {
            let clamped = max(0, min(23, replenishmentHour))
            if clamped != replenishmentHour {
                replenishmentHour = clamped
            }
            UserDefaults.standard.set(replenishmentHour, forKey: Self.hourKey)
            notifyChange()
        }
    }

    /// The minute component of replenishment time (0-59)
    /// Default is 0
    var replenishmentMinute: Int {
        didSet {
            let clamped = max(0, min(59, replenishmentMinute))
            if clamped != replenishmentMinute {
                replenishmentMinute = clamped
            }
            UserDefaults.standard.set(replenishmentMinute, forKey: Self.minuteKey)
            notifyChange()
        }
    }

    // MARK: - Initialization

    init() {
        // Load from UserDefaults or use defaults
        if UserDefaults.standard.object(forKey: Self.hourKey) != nil {
            self.replenishmentHour = UserDefaults.standard.integer(forKey: Self.hourKey)
        } else {
            self.replenishmentHour = 6 // Default: 6:00 AM
        }

        if UserDefaults.standard.object(forKey: Self.minuteKey) != nil {
            self.replenishmentMinute = UserDefaults.standard.integer(forKey: Self.minuteKey)
        } else {
            self.replenishmentMinute = 0 // Default: 0 minutes
        }
    }

    // MARK: - Computed Properties

    /// The replenishment time as DateComponents
    var replenishmentTime: DateComponents {
        DateComponents(hour: replenishmentHour, minute: replenishmentMinute)
    }

    /// Display text for the replenishment time (e.g., "6:00 AM")
    var displayText: String {
        var components = DateComponents()
        components.hour = replenishmentHour
        components.minute = replenishmentMinute

        guard let date = Calendar.current.date(from: components) else {
            return "\(replenishmentHour):\(String(format: "%02d", replenishmentMinute))"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    /// Applies the replenishment time to a given date (preserving year/month/day)
    /// - Parameter date: The date to apply the replenishment time to
    /// - Returns: The date with hour/minute set to replenishment time
    func applyReplenishmentTime(to date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = replenishmentHour
        components.minute = replenishmentMinute
        components.second = 0
        components.nanosecond = 0

        return calendar.date(from: components) ?? date
    }

    /// Creates a Date object representing today's replenishment time
    var todayReplenishmentDate: Date {
        applyReplenishmentTime(to: Date())
    }

    /// Creates a Date object representing tomorrow's replenishment time
    var tomorrowReplenishmentDate: Date {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) else {
            return todayReplenishmentDate
        }
        return applyReplenishmentTime(to: tomorrow)
    }

    // MARK: - Private Methods

    private func notifyChange() {
        NotificationCenter.default.post(name: .replenishmentTimeChanged, object: nil)
    }
}
