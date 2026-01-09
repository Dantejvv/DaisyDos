//
//  HabitCompletion.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import Foundation
import SwiftData

@Model
class HabitCompletion {

    // MARK: - Properties (CloudKit-compatible: all have defaults)

    var id: UUID = UUID()
    var completedDate: Date = Date()
    var notes: String = ""
    var duration: TimeInterval?
    var createdDate: Date = Date()

    // MARK: - Relationships

    @Relationship(inverse: \Habit.completionEntries)
    var habit: Habit?

    // MARK: - Initializers

    init(habit: Habit, completedDate: Date, notes: String = "", duration: TimeInterval? = nil) {
        self.id = UUID()
        self.habit = habit
        self.completedDate = completedDate
        self.notes = notes
        self.duration = duration
        self.createdDate = Date()
    }

    // MARK: - Computed Properties

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: completedDate)
    }

    var isToday: Bool {
        Calendar.current.isDate(completedDate, inSameDayAs: Date())
    }

    var isThisWeek: Bool {
        Calendar.current.isDate(completedDate, equalTo: Date(), toGranularity: .weekOfYear)
    }

    var isThisMonth: Bool {
        Calendar.current.isDate(completedDate, equalTo: Date(), toGranularity: .month)
    }

    var formattedDuration: String? {
        guard let duration = duration else { return nil }

        let minutes = Int(duration / 60)
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    // MARK: - Business Logic

    /// Check if this completion was made on time based on habit's recurrence rule
    func wasCompletedOnTime() -> Bool {
        guard let habit = habit else { return false }
        return habit.isDueOn(date: completedDate)
    }

    /// Get the streak position (how many days in a row including this one)
    func streakPosition() -> Int {
        guard let habit = habit else { return 0 }

        let calendar = Calendar.current
        let completions = (habit.completionEntries ?? [])
            .sorted { $0.completedDate < $1.completedDate }

        guard let thisIndex = completions.firstIndex(where: { $0.id == self.id }) else {
            return 0
        }

        var position = 1
        var currentIndex = thisIndex

        // Count backwards to find consecutive days
        while currentIndex > 0 {
            let currentCompletion = completions[currentIndex]
            let previousCompletion = completions[currentIndex - 1]

            let daysBetween = calendar.dateComponents([.day],
                from: previousCompletion.completedDate,
                to: currentCompletion.completedDate).day ?? 0

            if daysBetween == 1 {
                position += 1
                currentIndex -= 1
            } else {
                break
            }
        }

        return position
    }

    /// Calculate how this completion affected the overall habit progress
    func progressImpact() -> ProgressImpact {
        guard let habit = habit else { return .none }

        let streakPos = streakPosition()
        let wasOnTime = wasCompletedOnTime()

        switch (streakPos, wasOnTime) {
        case (let pos, true) where pos > habit.longestStreak:
            return .newRecord
        case (let pos, true) where pos > 7:
            return .weekStreak
        case (_, true):
            return .onTrack
        case (_, false):
            return .catchingUp
        }
    }
}

// MARK: - Progress Impact

extension HabitCompletion {
    enum ProgressImpact {
        case newRecord
        case weekStreak
        case onTrack
        case catchingUp
        case none

        var displayMessage: String {
            switch self {
            case .newRecord:
                return "New personal record! 🎉"
            case .weekStreak:
                return "Week streak achieved! 🔥"
            case .onTrack:
                return "Staying on track! 👍"
            case .catchingUp:
                return "Catching up! 💪"
            case .none:
                return ""
            }
        }

        var color: String {
            switch self {
            case .newRecord:
                return "daisySuccess"
            case .weekStreak:
                return "orange"
            case .onTrack:
                return "daisyTask"
            case .catchingUp:
                return "yellow"
            case .none:
                return "daisyTextSecondary"
            }
        }
    }
}

// MARK: - Analytics Extensions

extension HabitCompletion {

    /// Get completion time of day (morning, afternoon, evening, night)
    var timeOfDay: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: createdDate)
        switch hour {
        case 5..<12:
            return .morning
        case 12..<17:
            return .afternoon
        case 17..<21:
            return .evening
        default:
            return .night
        }
    }

    enum TimeOfDay: String, CaseIterable {
        case morning = "morning"
        case afternoon = "afternoon"
        case evening = "evening"
        case night = "night"

        var displayName: String {
            rawValue.capitalized
        }

        var emoji: String {
            switch self {
            case .morning: return "🌅"
            case .afternoon: return "☀️"
            case .evening: return "🌇"
            case .night: return "🌙"
            }
        }
    }
}