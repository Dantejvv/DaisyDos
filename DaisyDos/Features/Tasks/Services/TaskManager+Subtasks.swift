//
//  TaskManager+Subtasks.swift
//  DaisyDos
//
//  Subtask toggle operations for TaskManager
//

import Foundation
import SwiftData

// MARK: - TaskManager Subtask Methods

extension TaskManager {

    // MARK: - Subtask Toggle

    /// Toggles subtask completion state
    /// - Parameter subtask: The subtask to toggle
    /// - Returns: Result with success or error
    @discardableResult
    func toggleSubtask(_ subtask: Subtask) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "toggle subtask",
            entityType: "subtask"
        ) {
            subtask.toggleCompletion()
            try modelContext.save()
        }
    }
}
