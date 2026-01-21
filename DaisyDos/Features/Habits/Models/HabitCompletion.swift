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