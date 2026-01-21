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

}
