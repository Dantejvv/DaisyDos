//
//  HabitSkip.swift
//  DaisyDos
//
//  Created by Claude Code on 9/30/25.
//

import Foundation
import SwiftData

@Model
class HabitSkip {

    // MARK: - Properties (CloudKit-compatible: all have defaults)

    var id: UUID = UUID()
    var skippedDate: Date = Date()
    var reason: String?
    var createdDate: Date = Date()

    // MARK: - Relationships

    @Relationship(inverse: \Habit.skips)
    var habit: Habit?

    // MARK: - Initializers

    init(habit: Habit, skippedDate: Date, reason: String? = nil) {
        self.id = UUID()
        self.habit = habit
        self.skippedDate = skippedDate
        self.reason = reason
        self.createdDate = Date()
    }

    // MARK: - Computed Properties

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: skippedDate)
    }

    var isToday: Bool {
        Calendar.current.isDate(skippedDate, inSameDayAs: Date())
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(skippedDate, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isThisMonth: Bool {
        Calendar.current.isDate(skippedDate, equalTo: Date(), toGranularity: .month)
    }

    var hasReason: Bool {
        return reason?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var reasonDisplay: String {
        return reason?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "No reason given"
    }

    // MARK: - Business Logic

    /// Check if this skip was justified (has a reason)
    func wasJustified() -> Bool {
        return hasReason
    }

    /// Get skip frequency for the habit in the past 30 days
    func skipFrequencyInPast30Days() -> Double {
        guard let habit = habit else { return 0.0 }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) else {
            return 0.0
        }

        let skips = habit.skips?.filter { skip in
            skip.skippedDate >= startDate && skip.skippedDate <= endDate
        } ?? []

        // Calculate total days due in the period
        let totalDueDays: Int
        if let recurrenceRule = habit.recurrenceRule {
            let occurrences = recurrenceRule.occurrences(from: startDate, limit: 31)
            totalDueDays = occurrences.filter { $0 <= endDate }.count
        } else {
            // Flexible habit - every day is due
            totalDueDays = 30
        }

        guard totalDueDays > 0 else { return 0.0 }

        return Double(skips.count) / Double(totalDueDays)
    }

    /// Determine the impact of this skip on the habit
    func skipImpact() -> SkipImpact {
        let frequency = skipFrequencyInPast30Days()
        let justified = wasJustified()

        switch (frequency, justified) {
        case (let freq, true) where freq < 0.1: // Less than 10% skip rate with reason
            return .occasional
        case (let freq, false) where freq < 0.1: // Less than 10% skip rate without reason
            return .rare
        case (let freq, true) where freq < 0.3: // 10-30% skip rate with reason
            return .concerning
        case (let freq, false) where freq < 0.3: // 10-30% skip rate without reason
            return .worrying
        case (_, true): // High skip rate with reason
            return .problematic
        case (_, false): // High skip rate without reason
            return .alarming
        }
    }
}

// MARK: - Skip Impact

extension HabitSkip {
    enum SkipImpact {
        case occasional  // Low frequency, with reason
        case rare        // Low frequency, no reason
        case concerning  // Medium frequency, with reason
        case worrying    // Medium frequency, no reason
        case problematic // High frequency, with reason
        case alarming    // High frequency, no reason

        var displayMessage: String {
            switch self {
            case .occasional:
                return "Occasional skip - that's okay! 👍"
            case .rare:
                return "Rare skip - keep it up! ✨"
            case .concerning:
                return "Skipping more often lately 🤔"
            case .worrying:
                return "Consider adding reasons for skips 💭"
            case .problematic:
                return "High skip rate - review your goals 🎯"
            case .alarming:
                return "Too many skips - need adjustment? ⚠️"
            }
        }

        var color: String {
            switch self {
            case .occasional, .rare:
                return "daisySuccess"
            case .concerning:
                return "yellow"
            case .worrying:
                return "orange"
            case .problematic, .alarming:
                return "daisyError"
            }
        }

        var severity: Int {
            switch self {
            case .rare: return 1
            case .occasional: return 2
            case .concerning: return 3
            case .worrying: return 4
            case .problematic: return 5
            case .alarming: return 6
            }
        }
    }
}