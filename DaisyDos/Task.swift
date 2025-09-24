//
//  Task.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData

@Model
class Task {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdDate: Date

    @Relationship(deleteRule: .nullify, inverse: \Tag.tasks)
    var tags: [Tag] = []

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.createdDate = Date()
    }

    var tagCount: Int {
        tags.count
    }

    func canAddTag() -> Bool {
        return tagCount < 3
    }

    func addTag(_ tag: Tag) -> Bool {
        guard canAddTag() else { return false }
        if !tags.contains(tag) {
            tags.append(tag)
            return true
        }
        return false
    }

    func removeTag(_ tag: Tag) {
        tags.removeAll { $0 == tag }
    }

    func toggleCompletion() {
        isCompleted.toggle()
    }

    var hasOverdueStatus: Bool {
        // For basic implementation, we'll always return false since we don't have due dates yet
        return false
    }
}