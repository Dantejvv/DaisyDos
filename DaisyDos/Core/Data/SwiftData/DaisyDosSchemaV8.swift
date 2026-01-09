//
//  DaisyDosSchemaV8.swift
//  DaisyDos
//
//  Created by Claude Code
//  Schema V8 - Added PendingRecurrence for deferred task recreation
//

import Foundation
import SwiftData

/// Schema V8 for DaisyDos - Added PendingRecurrence model
/// Supports deferred recurring task creation (tasks appear at scheduled time, not immediately)
enum DaisyDosSchemaV8: VersionedSchema {
    static var versionIdentifier = Schema.Version(8, 0, 0)

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
            HabitAttachment.self,
            PendingRecurrence.self
        ]
    }
}
