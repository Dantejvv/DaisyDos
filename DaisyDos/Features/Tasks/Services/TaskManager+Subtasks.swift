//
//  TaskManager+Subtasks.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import Foundation
import SwiftData

// MARK: - TaskManager Subtask Methods

extension TaskManager {

    // MARK: - Simple Subtask Toggle (for Detail Views)

    /// Toggles subtask completion without parent propagation
    ///
    /// Use this method in detail views where parent completion is managed separately.
    /// The parent task will complete all subtasks when explicitly marked complete.
    ///
    /// - Parameter subtask: The subtask to toggle
    /// - Returns: Result with success or error
    ///
    /// **Design Decision**: Removed automatic parent propagation for simpler UX
    /// - Individual subtask toggles don't affect parent
    /// - Parent completion cascades down to all subtasks (see toggleTaskCompletion)
    /// - Users maintain explicit control over parent task state
    @discardableResult
    func toggleSubtask(_ subtask: Task) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "toggle subtask",
            entityType: "subtask"
        ) {
            guard subtask.parentTask != nil else {
                throw DaisyDosError.validationFailed("Task is not a subtask")
            }

            subtask.isCompleted.toggle()
            subtask.modifiedDate = Date()

            if subtask.isCompleted {
                subtask.completedDate = Date()
            } else {
                subtask.completedDate = nil
            }

            try modelContext.save()
        }
    }
}
