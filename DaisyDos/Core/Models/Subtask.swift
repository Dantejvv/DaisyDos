//
//  Subtask.swift
//  DaisyDos
//
//  Unified subtask model for both Tasks and Habits
//  Subtasks are simple checklist items with: title, completion state, and order
//

import Foundation
import SwiftData

/// A subtask belonging to either a Task or a Habit
///
/// Subtasks provide a simple checklist within a parent item.
/// For habits, subtask completion resets when the habit replenishes.
///
/// User interactions:
/// - Add subtask with title
/// - Delete subtask
/// - Reorder subtasks
/// - Edit subtask title inline
/// - Toggle completion
@Model
class Subtask {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var subtaskOrder: Int = 0
    var createdDate: Date = Date()
    var modifiedDate: Date = Date()

    // MARK: - Parent Relationships
    // A subtask belongs to either a Task OR a Habit, never both

    @Relationship(inverse: \Task.subtasks)
    var parentTask: Task?

    @Relationship(inverse: \Habit.subtasks)
    var parentHabit: Habit?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        subtaskOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.subtaskOrder = subtaskOrder
        self.createdDate = Date()
        self.modifiedDate = Date()
    }

    // MARK: - Methods

    /// Toggle the completion state
    func toggleCompletion() {
        isCompleted.toggle()
        modifiedDate = Date()
    }

    /// Set completion state explicitly
    func setCompleted(_ completed: Bool) {
        guard isCompleted != completed else { return }
        isCompleted = completed
        modifiedDate = Date()
    }

    /// Update the subtask title
    func updateTitle(_ newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != title else { return }
        title = trimmed
        modifiedDate = Date()
    }
}

// MARK: - Equatable & Hashable

extension Subtask: Equatable {
    static func == (lhs: Subtask, rhs: Subtask) -> Bool {
        lhs.id == rhs.id
    }
}

extension Subtask: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - SubtaskDisplayable Conformance

extension Subtask: SubtaskDisplayable {
    // Protocol requires: var title: String { get } - already exists
    // Protocol requires: var isCompleted: Bool { get } - already exists
}
