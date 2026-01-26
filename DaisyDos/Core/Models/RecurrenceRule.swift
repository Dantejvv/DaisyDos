//
//  RecurrenceRule.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import Foundation

/// Recurrence rule system for tasks and habits with dynamic date calculation
/// Supports flexible scheduling patterns with timezone awareness
struct RecurrenceRule: Codable, Equatable, Identifiable {

    let id: UUID
    let frequency: Frequency
    let interval: Int
    let daysOfWeek: Set<Int>?
    let dayOfMonth: Int?
    let endDate: Date?
    let repeatMode: RepeatMode
    let timeZoneIdentifier: String

    // MARK: - Computed Properties

    /// The actual TimeZone object from the stored identifier
    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? TimeZone.current
    }

    /// Short display name for compact UI (e.g., "Daily", "Weekly", "Every 3 days")
    var frequencyDisplayName: String {
        // If interval is greater than 1, show custom interval format
        if interval > 1 {
            switch frequency {
            case .minutely:
                return "Every \(interval)min"
            case .hourly:
                return "Every \(interval)h"
            case .daily:
                return "Every \(interval)d"
            case .weekly:
                return "Every \(interval)w"
            case .monthly:
                return "Every \(interval)mo"
            case .yearly:
                return "Every \(interval)y"
            case .custom:
                return "Custom"
            }
        }
        return frequency.displayName
    }

    // MARK: - Repeat Mode

    enum RepeatMode: String, Codable, CaseIterable {
        case fromOriginalDate = "from_original"
        case fromCompletionDate = "from_completion"

        var displayName: String {
            switch self {
            case .fromOriginalDate:
                return "From original date"
            case .fromCompletionDate:
                return "From completion"
            }
        }

        var description: String {
            switch self {
            case .fromOriginalDate:
                return "Repeat based on the original scheduled date"
            case .fromCompletionDate:
                return "Repeat based on when you complete it"
            }
        }

        var icon: String {
            switch self {
            case .fromOriginalDate:
                return "calendar"
            case .fromCompletionDate:
                return "checkmark.circle"
            }
        }
    }

    // MARK: - Frequency Types

    enum Frequency: String, CaseIterable, Codable {
        case minutely = "minutely"
        case hourly = "hourly"
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case yearly = "yearly"
        case custom = "custom"

        var displayName: String {
            switch self {
            case .minutely:
                return "Every X minutes"
            case .hourly:
                return "Hourly"
            case .daily:
                return "Daily"
            case .weekly:
                return "Weekly"
            case .monthly:
                return "Monthly"
            case .yearly:
                return "Yearly"
            case .custom:
                return "Custom"
            }
        }

        var description: String {
            switch self {
            case .minutely:
                return "Repeats every few minutes"
            case .hourly:
                return "Repeats every hour or every few hours"
            case .daily:
                return "Repeats every day or every few days"
            case .weekly:
                return "Repeats on specific days of the week"
            case .monthly:
                return "Repeats monthly on a specific day"
            case .yearly:
                return "Repeats yearly on the same date"
            case .custom:
                return "Custom recurrence pattern"
            }
        }
    }

    // MARK: - Initializers

    /// Creates a recurrence rule with full configuration
    init(
        id: UUID = UUID(),
        frequency: Frequency,
        interval: Int = 1,
        daysOfWeek: Set<Int>? = nil,
        dayOfMonth: Int? = nil,
        endDate: Date? = nil,
        repeatMode: RepeatMode = .fromOriginalDate,
        timeZone: TimeZone = TimeZone.current
    ) {
        self.id = id
        self.frequency = frequency
        self.interval = max(1, interval) // Ensure interval is at least 1
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
        self.endDate = endDate
        self.repeatMode = repeatMode
        self.timeZoneIdentifier = timeZone.identifier
    }

    // MARK: - Factory Methods

    /// Creates a daily recurrence rule
    static func daily(interval: Int = 1, endDate: Date? = nil) -> RecurrenceRule {
        return RecurrenceRule(
            frequency: .daily,
            interval: interval,
            endDate: endDate
        )
    }

    /// Creates a weekly recurrence rule for specific days
    static func weekly(daysOfWeek: Set<Int>, interval: Int = 1, endDate: Date? = nil) -> RecurrenceRule {
        return RecurrenceRule(
            frequency: .weekly,
            interval: interval,
            daysOfWeek: daysOfWeek,
            endDate: endDate
        )
    }

    /// Creates a monthly recurrence rule
    static func monthly(dayOfMonth: Int, interval: Int = 1, endDate: Date? = nil) -> RecurrenceRule {
        return RecurrenceRule(
            frequency: .monthly,
            interval: interval,
            dayOfMonth: dayOfMonth,
            endDate: endDate
        )
    }

    /// Creates a yearly recurrence rule
    static func yearly(interval: Int = 1, endDate: Date? = nil) -> RecurrenceRule {
        return RecurrenceRule(
            frequency: .yearly,
            interval: interval,
            endDate: endDate
        )
    }

    /// Creates an hourly recurrence rule
    static func hourly(interval: Int = 1, endDate: Date? = nil) -> RecurrenceRule {
        return RecurrenceRule(
            frequency: .hourly,
            interval: interval,
            endDate: endDate
        )
    }

    /// Creates a minutely recurrence rule
    static func minutely(interval: Int = 1, endDate: Date? = nil) -> RecurrenceRule {
        return RecurrenceRule(
            frequency: .minutely,
            interval: interval,
            endDate: endDate
        )
    }

    // MARK: - Date Calculations

    /// Encapsulates all parameters needed for recurrence calculation
    /// Enables unified algorithm without frequency-specific branching
    private struct RecurrenceCalculationContext {
        let frequency: Frequency
        let interval: Int
        let daysOfWeek: Set<Int>?
        let dayOfMonth: Int?
        let calendar: Calendar
        let baseDate: Date

        /// Maps frequency to Calendar component for unified advancement
        var calendarComponent: Calendar.Component {
            switch frequency {
            case .minutely: return .minute
            case .hourly: return .hour
            case .daily: return .day
            case .weekly: return .weekOfYear
            case .monthly: return .month
            case .yearly: return .year
            case .custom: return .day  // Custom treated as daily intervals
            }
        }

        /// Determines if post-advancement modifiers are needed
        var requiresModifiers: Bool {
            daysOfWeek != nil || dayOfMonth != nil
        }
    }

    /// Calculates the next occurrence date after the given date
    /// UNIFIED ENGINE: All frequencies flow through single algorithm
    func nextOccurrence(after date: Date) -> Date? {
        // Use rule's stored timezone for all calculations
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        // Step 1: Create calculation context
        let context = RecurrenceCalculationContext(
            frequency: frequency,
            interval: interval,
            daysOfWeek: daysOfWeek,
            dayOfMonth: dayOfMonth,
            calendar: calendar,
            baseDate: date
        )

        // Step 2: Advance by interval units (unified for all frequencies)
        guard var nextDate = advanceDateByInterval(context: context) else {
            return nil
        }

        // Step 3: Apply frequency-specific modifiers (weekday selection, day clamping)
        if context.requiresModifiers {
            nextDate = applyModifiers(to: nextDate, context: context)
        }

        // Step 4: Validate occurrence against termination conditions
        guard isValidOccurrence(nextDate) else {
            return nil
        }

        return nextDate
    }

    /// Generates a sequence of occurrence dates up to a limit
    func occurrences(from startDate: Date, limit: Int = 50) -> [Date] {
        var occurrences: [Date] = []
        var currentDate = startDate

        for _ in 0..<limit {
            guard let nextDate = nextOccurrence(after: currentDate) else {
                break
            }

            occurrences.append(nextDate)
            currentDate = nextDate

            // Stop if we've reached the end date
            if let endDate = endDate, nextDate >= endDate {
                break
            }
        }

        return occurrences
    }

    /// Checks if a given date matches this recurrence pattern
    /// UNIFIED: Uses component-based matching without frequency branching
    func matches(date: Date, relativeTo baseDate: Date) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = timeZone

        // Calculate difference in appropriate units using unified component mapping
        let component = RecurrenceCalculationContext(
            frequency: frequency,
            interval: interval,
            daysOfWeek: daysOfWeek,
            dayOfMonth: dayOfMonth,
            calendar: calendar,
            baseDate: baseDate
        ).calendarComponent

        // Extract unit difference
        let unitsBetween: Int?
        switch component {
        case .minute:
            unitsBetween = calendar.dateComponents([.minute], from: baseDate, to: date).minute
        case .hour:
            unitsBetween = calendar.dateComponents([.hour], from: baseDate, to: date).hour
        case .day:
            unitsBetween = calendar.dateComponents([.day], from: baseDate, to: date).day
        case .weekOfYear:
            unitsBetween = calendar.dateComponents([.weekOfYear], from: baseDate, to: date).weekOfYear
        case .month:
            unitsBetween = calendar.dateComponents([.month], from: baseDate, to: date).month
        case .year:
            unitsBetween = calendar.dateComponents([.year], from: baseDate, to: date).year
        default:
            return false
        }

        guard let units = unitsBetween, units >= 0 else { return false }

        // Check interval alignment
        guard units % interval == 0 else { return false }

        // Apply frequency-specific constraints
        switch frequency {
        case .weekly:
            guard let daysOfWeek = daysOfWeek else { return true }
            let weekday = calendar.component(.weekday, from: date)
            return daysOfWeek.contains(weekday)

        case .monthly, .yearly:
            let day = calendar.component(.day, from: date)
            let expectedDay = dayOfMonth ?? calendar.component(.day, from: baseDate)
            // Handle month-end clamping
            let lastDayOfMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 31
            return day == min(expectedDay, lastDayOfMonth)

        default:
            return true
        }
    }

    // MARK: - Unified Calculation Engine

    /// Advances date by interval units (single entry point for all frequencies)
    private func advanceDateByInterval(context: RecurrenceCalculationContext) -> Date? {
        return context.calendar.date(
            byAdding: context.calendarComponent,
            value: context.interval,
            to: context.baseDate
        )
    }

    /// Applies frequency-specific modifiers after advancement
    private func applyModifiers(to date: Date, context: RecurrenceCalculationContext) -> Date {
        switch context.frequency {
        case .weekly:
            return applyWeekdayModifier(to: date, context: context)
        case .monthly, .yearly:
            return applyMonthDayModifier(to: date, context: context)
        default:
            return date  // Daily needs no modifiers
        }
    }

    /// Selects next valid weekday for weekly recurrence
    /// Handles: multiple weekdays, week boundaries, chronological ordering
    private func applyWeekdayModifier(to date: Date, context: RecurrenceCalculationContext) -> Date {
        guard let daysOfWeek = context.daysOfWeek, !daysOfWeek.isEmpty else {
            return date  // No specific days = simple weekly
        }

        let currentWeekday = context.calendar.component(.weekday, from: context.baseDate)
        let sortedDays = daysOfWeek.sorted()

        // Find next day in current week
        if let nextDay = sortedDays.first(where: { $0 > currentWeekday }) {
            let daysToAdd = nextDay - currentWeekday
            return context.calendar.date(byAdding: .day, value: daysToAdd, to: context.baseDate) ?? date
        }

        // Wrap to next interval week, first scheduled day
        let weeksToAdd = context.interval
        let daysToAdd = 7 * weeksToAdd + (sortedDays.first! - currentWeekday)
        return context.calendar.date(byAdding: .day, value: daysToAdd, to: context.baseDate) ?? date
    }

    /// Clamps day-of-month to valid range
    /// Handles: Feb 30→28, Apr 31→30, leap year transitions
    private func applyMonthDayModifier(to date: Date, context: RecurrenceCalculationContext) -> Date {
        let targetDay = context.dayOfMonth ?? context.calendar.component(.day, from: context.baseDate)

        var components = context.calendar.dateComponents([.year, .month], from: date)
        components.day = targetDay

        // Try exact day first
        if let targetDate = context.calendar.date(from: components),
           context.calendar.component(.day, from: targetDate) == targetDay {
            return targetDate
        }

        // Edge case: target day doesn't exist in month (Feb 30, Apr 31)
        // Fall back to last day of month (spec requirement lines 63-67)
        let range = context.calendar.range(of: .day, in: .month, for: date)
        components.day = range?.upperBound.advanced(by: -1)
        return context.calendar.date(from: components) ?? date
    }

    /// Validates occurrence against termination conditions
    private func isValidOccurrence(_ date: Date) -> Bool {
        // Check end date constraint
        if let endDate = endDate, date > endDate {
            return false
        }

        return true
    }

    // MARK: - Validation

    var isValid: Bool {
        // Basic validation rules
        guard interval > 0 else { return false }

        switch frequency {
        case .minutely:
            // 1-1440 minutes (up to 24 hours)
            return interval >= 1 && interval <= 1440

        case .hourly:
            // 1-24 hours
            return interval >= 1 && interval <= 24

        case .weekly:
            if let daysOfWeek = daysOfWeek {
                return !daysOfWeek.isEmpty && daysOfWeek.allSatisfy { $0 >= 1 && $0 <= 7 }
            }
            return true

        case .monthly:
            if let dayOfMonth = dayOfMonth {
                return dayOfMonth >= 1 && dayOfMonth <= 31
            }
            return true

        default:
            return true
        }
    }

    // MARK: - Display Properties

    var displayDescription: String {
        var baseDescription: String
        switch frequency {
        case .minutely:
            baseDescription = interval == 1 ? "Every minute" : "Every \(interval) minutes"
        case .hourly:
            baseDescription = interval == 1 ? "Hourly" : "Every \(interval) hours"
        case .daily:
            baseDescription = interval == 1 ? "Daily" : "Every \(interval) days"
        case .weekly:
            if let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty {
                let dayNames = daysOfWeek.sorted().map { Calendar.current.shortWeekdaySymbols[$0 - 1] }
                let prefix = interval == 1 ? "Weekly on" : "Every \(interval) weeks on"
                baseDescription = "\(prefix) \(dayNames.joined(separator: ", "))"
            } else {
                baseDescription = interval == 1 ? "Weekly" : "Every \(interval) weeks"
            }
        case .monthly:
            if let dayOfMonth = dayOfMonth {
                let ordinal = ordinalSuffix(for: dayOfMonth)
                let prefix = interval == 1 ? "Monthly on the" : "Every \(interval) months on the"
                baseDescription = "\(prefix) \(ordinal)"
            } else {
                baseDescription = interval == 1 ? "Monthly" : "Every \(interval) months"
            }
        case .yearly:
            baseDescription = interval == 1 ? "Yearly" : "Every \(interval) years"
        case .custom:
            baseDescription = "Custom pattern"
        }

        // Add repeat mode suffix if fromCompletion
        if repeatMode == .fromCompletionDate {
            return "\(baseDescription) after completion"
        }
        return baseDescription
    }

    /// Returns ordinal string (1st, 2nd, 3rd, 4th, etc.)
    private func ordinalSuffix(for day: Int) -> String {
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return "\(day)\(suffix)"
    }

    /// Natural language description for display at top of picker
    var naturalLanguageDescription: String {
        return displayDescription
    }
}

// MARK: - Common Patterns

extension RecurrenceRule {

    /// Common recurrence patterns for quick selection
    static var commonPatterns: [RecurrenceRule] {
        return [
            .daily(),
            .weekly(daysOfWeek: [2, 3, 4, 5, 6]), // Weekdays
            .weekly(daysOfWeek: [1, 7]), // Weekends
            .monthly(dayOfMonth: 1),
            .yearly()
        ]
    }

    /// Weekdays only pattern
    static var weekdays: RecurrenceRule {
        .weekly(daysOfWeek: [2, 3, 4, 5, 6]) // Monday through Friday
    }

    /// Weekends only pattern
    static var weekends: RecurrenceRule {
        .weekly(daysOfWeek: [1, 7]) // Saturday and Sunday
    }
}