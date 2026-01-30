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
/// Note: HabitSubtask replaced by Subtask in V9
enum DaisyDosSchemaV8: VersionedSchema {
    static var versionIdentifier = Schema.Version(8, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Task.self,
            Habit.self,
            Tag.self,
            HabitCompletion.self,
            HabitSkip.self,
            Subtask.self,  // Updated: Was HabitSubtask, now unified Subtask
            TaskLogEntry.self,
            TaskAttachment.self,
            HabitAttachment.self,
            PendingRecurrence.self
        ]
    }
}
