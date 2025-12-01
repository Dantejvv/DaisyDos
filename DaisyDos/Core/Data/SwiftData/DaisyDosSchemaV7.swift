//
//  DaisyDosSchemaV7.swift
//  DaisyDos
//
//  Created by Claude Code
//  Schema V7 - Added Alert/Reminder support for Habits
//

import Foundation
import SwiftData

/// Schema V7 for DaisyDos - Added Alert/Reminder support for Habits
/// Adds alertTimeInterval property to Habit model
enum DaisyDosSchemaV7: VersionedSchema {
    static var versionIdentifier = Schema.Version(7, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Task.self,
            Habit.self,
            Tag.self,
            HabitCompletion.self,
            HabitStreak.self,
            HabitSkip.self,
            HabitSubtask.self,
            TaskLogEntry.self,
            TaskAttachment.self,
            HabitAttachment.self
        ]
    }
}
