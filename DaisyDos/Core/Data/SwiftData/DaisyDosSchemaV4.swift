//
//  DaisyDosSchemaV4.swift
//  DaisyDos
//
//  Created by Claude Code on 10/11/25.
//  Schema V4 - Added Logbook Models (TaskLogEntry, CompletionAggregate)
//

import Foundation
import SwiftData

/// Schema V4 for DaisyDos - Added Logbook Support
/// Adds TaskLogEntry for archived completions (simple history tracking, no analytics)
enum DaisyDosSchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            Task.self,
            Habit.self,
            Tag.self,
            HabitCompletion.self,
            HabitStreak.self,
            HabitSkip.self,
            TaskLogEntry.self  // NEW - Archived completion snapshots
        ]
    }
}
