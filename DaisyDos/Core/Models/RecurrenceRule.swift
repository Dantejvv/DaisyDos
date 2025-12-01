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
    let maxOccurrences: Int?
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
            case .daily:
                return "Every \(interval)d"
            case .weekly:
                return "Every \(interval)w"
            case .monthly:
                return "Every \(interval)m"
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
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case yearly = "yearly"
        case custom = "custom"

        var displayName: String {
            switch self {
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
        maxOccurrences: Int? = nil,
        repeatMode: RepeatMode = .fromOriginalDate,
        timeZone: TimeZone = TimeZone.current
    ) {
        self.id = id
        self.frequency = frequency
        self.interval = max(1, interval) // Ensure interval is at least 1
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
        self.endDate = endDate
        self.maxOccurrences = maxOccurrences
        self.repeatMode = repeatMode
        self.timeZoneIdentifier = timeZone.identifier
    }

    // MARK: - Factory Methods

    /// Creates a daily recurrence rule
    static func daily(interval: Int = 1, endDate: Date? = nil) -> RecurrenceRule {
        RecurrenceRule(frequency: .daily, interval: interval, endDate: endDate)
    }

    /// Creates a weekly recurrence rule for specific days
    static func weekly(daysOfWeek: Set<Int>, interval: Int = 1, endDate: Date? = nil) -> RecurrenceRule {
        RecurrenceRule(
            frequency: .weekly,
            interval: interval,
            daysOfWeek: daysOfWeek,
            endDate: endDate
        )
    }

    /// Creates a monthly recurrence rule
    static func monthly(dayOfMonth: Int, interval: Int = 1, endDate: Date? = nil) -> RecurrenceRule {
        RecurrenceRule(
            frequency: .monthly,
            interval: interval,
            dayOfMonth: dayOfMonth,
            endDate: endDate
        )
    }

    /// Creates a yearly recurrence rule
    static func yearly(interval: Int = 1, endDate: Date? = nil) -> RecurrenceRule {
        RecurrenceRule(frequency: .yearly, interval: interval, endDate: endDate)
    }

    // MARK: - Date Calculations

    /// Calculates the next occurrence date after the given date
    func nextOccurrence(after date: Date) -> Date? {
        let calendar = Calendar.current
        var nextDate: Date?

        switch frequency {
        case .daily:
            nextDate = calculateNextDailyOccurrence(after: date, calendar: calendar)
        case .weekly:
            nextDate = calculateNextWeeklyOccurrence(after: date, calendar: calendar)
        case .monthly:
            nextDate = calculateNextMonthlyOccurrence(after: date, calendar: calendar)
        case .yearly:
            nextDate = calculateNextYearlyOccurrence(after: date, calendar: calendar)
        case .custom:
            nextDate = calculateNextCustomOccurrence(after: date, calendar: calendar)
        }

        // Check if we've exceeded the end date or max occurrences
        if let nextDate = nextDate {
            if let endDate = endDate, nextDate > endDate {
                return nil
            }
            // Note: maxOccurrences would need additional state tracking to implement fully
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
    func matches(date: Date, relativeTo baseDate: Date) -> Bool {
        let calendar = Calendar.current

        switch frequency {
        case .daily:
            let daysBetween = calendar.dateComponents([.day], from: baseDate, to: date).day ?? 0
            return daysBetween >= 0 && daysBetween % interval == 0

        case .weekly:
            guard let daysOfWeek = daysOfWeek else { return false }
            let weekday = calendar.component(.weekday, from: date)
            let weeksBetween = calendar.dateComponents([.weekOfYear], from: baseDate, to: date).weekOfYear ?? 0
            return weeksBetween >= 0 && weeksBetween % interval == 0 && daysOfWeek.contains(weekday)

        case .monthly:
            let monthsBetween = calendar.dateComponents([.month], from: baseDate, to: date).month ?? 0
            let day = calendar.component(.day, from: date)
            return monthsBetween >= 0 && monthsBetween % interval == 0 && day == (dayOfMonth ?? calendar.component(.day, from: baseDate))

        case .yearly:
            let yearsBetween = calendar.dateComponents([.year], from: baseDate, to: date).year ?? 0
            let baseComponents = calendar.dateComponents([.month, .day], from: baseDate)
            let dateComponents = calendar.dateComponents([.month, .day], from: date)
            return yearsBetween >= 0 && yearsBetween % interval == 0 &&
                   baseComponents.month == dateComponents.month &&
                   baseComponents.day == dateComponents.day

        case .custom:
            // Custom logic would need additional parameters
            return false
        }
    }

    // MARK: - Private Helper Methods

    private func calculateNextDailyOccurrence(after date: Date, calendar: Calendar) -> Date? {
        return calendar.date(byAdding: .day, value: interval, to: date)
    }

    private func calculateNextWeeklyOccurrence(after date: Date, calendar: Calendar) -> Date? {
        guard let daysOfWeek = daysOfWeek, !daysOfWeek.isEmpty else {
            // If no specific days, default to weekly on same day
            return calendar.date(byAdding: .weekOfYear, value: interval, to: date)
        }

        let currentWeekday = calendar.component(.weekday, from: date)
        let sortedDays = daysOfWeek.sorted()

        // Find the next day in the current week
        if let nextDay = sortedDays.first(where: { $0 > currentWeekday }) {
            let daysToAdd = nextDay - currentWeekday
            return calendar.date(byAdding: .day, value: daysToAdd, to: date)
        }

        // Move to next interval week, first day
        let weeksToAdd = interval
        let daysToAdd = 7 * weeksToAdd + (sortedDays.first! - currentWeekday)
        return calendar.date(byAdding: .day, value: daysToAdd, to: date)
    }

    private func calculateNextMonthlyOccurrence(after date: Date, calendar: Calendar) -> Date? {
        let targetDay = dayOfMonth ?? calendar.component(.day, from: date)

        // Try adding interval months
        guard let nextMonth = calendar.date(byAdding: .month, value: interval, to: date) else {
            return nil
        }

        // Adjust to target day of month
        var components = calendar.dateComponents([.year, .month], from: nextMonth)
        components.day = targetDay

        let targetDate = calendar.date(from: components)

        // Handle cases where target day doesn't exist in the month (e.g., Feb 30)
        if let targetDate = targetDate, calendar.component(.day, from: targetDate) == targetDay {
            return targetDate
        } else {
            // Fall back to last day of month
            let range = calendar.range(of: .day, in: .month, for: nextMonth)
            components.day = range?.upperBound.advanced(by: -1)
            return calendar.date(from: components)
        }
    }

    private func calculateNextYearlyOccurrence(after date: Date, calendar: Calendar) -> Date? {
        return calendar.date(byAdding: .year, value: interval, to: date)
    }

    private func calculateNextCustomOccurrence(after date: Date, calendar: Calendar) -> Date? {
        // Custom recurrence would need additional implementation based on specific patterns
        // For now, return nil to indicate unsupported
        return nil
    }

    // MARK: - Validation

    var isValid: Bool {
        // Basic validation rules
        guard interval > 0 else { return false }

        switch frequency {
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
        let baseDescription: String
        switch frequency {
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