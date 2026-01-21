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
    var createdDate: Date = Date()

    // MARK: - Relationships

    @Relationship(inverse: \Habit.skips)
    var habit: Habit?

    // MARK: - Initializers

    init(habit: Habit, skippedDate: Date) {
        self.id = UUID()
        self.habit = habit
        self.skippedDate = skippedDate
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
}
