//
//  DaisyDosSchemaV2.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import Foundation
import SwiftData

/// Schema V2 for DaisyDos - Enhanced Task and Habit Models
/// Adds TaskAttachment support, priority levels, due dates, subtasks, recurrence, and habit priorities
enum DaisyDosSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Task.self, Habit.self, Tag.self, TaskAttachment.self, HabitCompletion.self, HabitStreak.self, HabitSkip.self]
    }

}