//
//  DaisyDosSchemaV3.swift
//  DaisyDos
//
//  Created by Claude Code on 10/1/25.
//

import Foundation
import SwiftData

/// Schema V3 for DaisyDos - Added Tag Description Field
/// Adds tagDescription property to Tag model
enum DaisyDosSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Task.self, Habit.self, Tag.self, HabitCompletion.self, HabitStreak.self, HabitSkip.self]
    }

}
