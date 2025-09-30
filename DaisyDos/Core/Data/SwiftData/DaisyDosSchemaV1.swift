//
//  DaisyDosSchemaV1.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData

enum DaisyDosSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [TaskV1.self, Habit.self, Tag.self, HabitCompletion.self, HabitStreak.self]
    }

    // MARK: - V1 Task Model (Original)

    @Model
    class TaskV1 {
        var id: UUID
        var title: String
        var isCompleted: Bool
        var createdDate: Date

        @Relationship(deleteRule: .nullify, inverse: \Tag.tasks)
        var tags: [Tag] = []

        init(
            id: UUID = UUID(),
            title: String,
            isCompleted: Bool = false,
            createdDate: Date = Date()
        ) {
            self.id = id
            self.title = title
            self.isCompleted = isCompleted
            self.createdDate = createdDate
        }
    }
}