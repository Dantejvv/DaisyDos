//
//  DaisyDosSchemaV9.swift
//  DaisyDos
//
//  Schema V9 - Unified Subtask model
//  Replaces self-referential Task subtasks and HabitSubtask with single Subtask entity
//

import Foundation
import SwiftData

/// Schema V9 for DaisyDos - Unified Subtask model
/// Subtasks now work identically for both Tasks and Habits
enum DaisyDosSchemaV9: VersionedSchema {
    static var versionIdentifier = Schema.Version(9, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Task.self,
            Habit.self,
            Tag.self,
            HabitCompletion.self,
            HabitSkip.self,
            Subtask.self,          // New unified subtask model
            TaskLogEntry.self,
            TaskAttachment.self,
            HabitAttachment.self,
            PendingRecurrence.self
            // Removed: HabitSubtask.self (replaced by Subtask)
        ]
    }
}
