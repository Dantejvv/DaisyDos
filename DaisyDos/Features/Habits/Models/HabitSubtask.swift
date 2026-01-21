//
//  HabitSubtask.swift
//  DaisyDos
//
//  Created by Claude Code
//

import Foundation
import SwiftData

@Model
class HabitSubtask {
    // CloudKit-compatible: all have defaults
    var id: UUID = UUID()
    var title: String = ""
    var isCompletedToday: Bool = false
    var createdDate: Date = Date()
    var modifiedDate: Date = Date()
    var lastCompletedDate: Date?

    /// Ordering property for subtask display
    var subtaskOrder: Int = 0

    /// Parent habit relationship
    @Relationship(inverse: \Habit.subtasks)
    var parentHabit: Habit?

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isCompletedToday = false
        let now = Date()
        self.createdDate = now
        self.modifiedDate = now
        self.lastCompletedDate = nil
    }

    // MARK: - Display Properties

    var displayTitle: String {
        return title.isEmpty ? "Untitled Subtask" : title
    }

    // MARK: - Completion Management

    func toggleCompletion() {
        setCompleted(!isCompletedToday)
    }

    func setCompleted(_ completed: Bool) {
        guard isCompletedToday != completed else { return }

        isCompletedToday = completed
        lastCompletedDate = completed ? Date() : nil
        modifiedDate = Date()
    }
}

// MARK: - Equatable Conformance

extension HabitSubtask: Equatable {
    static func == (lhs: HabitSubtask, rhs: HabitSubtask) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable Conformance

extension HabitSubtask: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - SubtaskDisplayable Conformance

/// Enables HabitSubtask to be displayed in unified SubtaskRow component
/// Maps isCompletedToday to isCompleted for protocol compatibility
extension HabitSubtask: SubtaskDisplayable {
    var isCompleted: Bool {
        get { isCompletedToday }
        set { isCompletedToday = newValue }
    }
}

