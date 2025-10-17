//
//  TaskManager+Subtasks.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - Subtask Completion Strategies

enum SubtaskCompletionStrategy: String, CaseIterable, Codable {
    case automatic = "automatic"
    case manual = "manual"
    case hybrid = "hybrid"

    var displayName: String {
        switch self {
        case .automatic:
            return "Automatic"
        case .manual:
            return "Manual"
        case .hybrid:
            return "Hybrid"
        }
    }

    var description: String {
        switch self {
        case .automatic:
            return "Parent completes when all subtasks are complete"
        case .manual:
            return "Parent completion is independent of subtasks"
        case .hybrid:
            return "Smart completion based on context"
        }
    }
}

// MARK: - Enhanced TaskManager Subtask Methods

extension TaskManager {

    // MARK: - Enhanced Completion Logic

    /// Toggle subtask completion with intelligent propagation
    func toggleSubtaskCompletion(
        _ subtask: Task,
        strategy: SubtaskCompletionStrategy = .hybrid,
        propagateToParent: Bool = true
    ) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "toggle subtask completion",
            entityType: "subtask"
        ) {
            let wasCompleted = subtask.isCompleted
            subtask.toggleCompletion()

            // Handle propagation based on strategy
            if propagateToParent {
                try handleCompletionPropagation(
                    for: subtask,
                    wasCompleted: wasCompleted,
                    strategy: strategy
                )
            }

            try modelContext.save()
        }
    }

    /// Enhanced subtask completion with custom completion logic
    func setSubtaskCompletion(
        _ subtask: Task,
        completed: Bool,
        strategy: SubtaskCompletionStrategy = .hybrid,
        propagateToChildren: Bool = true,
        propagateToParent: Bool = true
    ) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "set subtask completion",
            entityType: "subtask"
        ) {
            let wasCompleted = subtask.isCompleted
            subtask.setCompleted(completed)

            // Handle child propagation
            if propagateToChildren && completed {
                try completeAllSubtasks(of: subtask, strategy: strategy)
            }

            // Handle parent propagation
            if propagateToParent {
                try handleCompletionPropagation(
                    for: subtask,
                    wasCompleted: wasCompleted,
                    strategy: strategy
                )
            }

            try modelContext.save()
        }
    }

    /// Bulk complete multiple subtasks
    func bulkCompleteSubtasks(
        _ subtasks: [Task],
        of parent: Task,
        strategy: SubtaskCompletionStrategy = .hybrid
    ) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "bulk complete subtasks",
            entityType: "subtasks"
        ) {
            for subtask in subtasks {
                subtask.setCompleted(true)
            }

            // Check if all subtasks are now complete and handle parent
            if strategy != .manual {
                try updateParentCompletionStatus(parent, strategy: strategy)
            }

            try modelContext.save()
        }
    }

    /// Smart completion analysis for a task hierarchy
    func analyzeCompletionStatus(_ task: Task) -> SubtaskCompletionAnalysis {
        let analysis = SubtaskCompletionAnalysis(
            task: task,
            totalSubtasks: task.subtaskCount,
            completedSubtasks: task.completedSubtaskCount,
            partiallyCompleteSubtasks: 0, // No nested subtasks, so no partial completion at subtask level
            canAutoComplete: canAutoCompleteTask(task),
            shouldPropagateUp: shouldPropagateToParent(task),
            blockedSubtasks: findBlockedSubtasks(task)
        )

        return analysis
    }

    // MARK: - Private Completion Logic

    private func handleCompletionPropagation(
        for subtask: Task,
        wasCompleted: Bool,
        strategy: SubtaskCompletionStrategy
    ) throws {
        guard let parent = subtask.parentTask else { return }

        switch strategy {
        case .automatic:
            try updateParentCompletionStatus(parent, strategy: strategy)

        case .manual:
            // No automatic propagation in manual mode
            break

        case .hybrid:
            // Smart decision based on context
            if shouldPropagateToParent(subtask) {
                try updateParentCompletionStatus(parent, strategy: strategy)
            }
        }
    }

    private func updateParentCompletionStatus(
        _ parent: Task,
        strategy: SubtaskCompletionStrategy
    ) throws {
        let allSubtasksComplete = parent.subtasks.allSatisfy(\.isCompleted)
        let anySubtaskIncomplete = parent.subtasks.contains { !$0.isCompleted }

        switch strategy {
        case .automatic:
            if allSubtasksComplete && !parent.isCompleted {
                parent.setCompleted(true)
            } else if anySubtaskIncomplete && parent.isCompleted {
                parent.setCompleted(false)
            }

        case .hybrid:
            // More intelligent logic for hybrid mode
            if allSubtasksComplete && !parent.isCompleted && shouldAutoCompleteParent(parent) {
                parent.setCompleted(true)
            } else if anySubtaskIncomplete && parent.isCompleted {
                // Always uncomplete parent if subtasks are incomplete
                parent.setCompleted(false)
            }

        case .manual:
            // Only uncomplete parent if it was completed and now has incomplete subtasks
            if anySubtaskIncomplete && parent.isCompleted {
                parent.setCompleted(false)
            }
        }

        // No recursive propagation - only one level of subtasks allowed
    }

    private func completeAllSubtasks(
        of task: Task,
        strategy: SubtaskCompletionStrategy
    ) throws {
        for subtask in task.subtasks where !subtask.isCompleted {
            subtask.setCompleted(true)
            // No recursion - subtasks cannot have subtasks
        }
    }

    private func shouldPropagateToParent(_ subtask: Task) -> Bool {
        guard let parent = subtask.parentTask else { return false }

        // Don't propagate if parent has many subtasks and only one changed
        if parent.subtaskCount > 10 && parent.completedSubtaskCount < parent.subtaskCount - 1 {
            return false
        }

        // Don't propagate if this is a low-priority subtask and parent is high priority
        if subtask.priority == .low && parent.priority == .high {
            return false
        }

        return true
    }

    private func shouldAutoCompleteParent(_ parent: Task) -> Bool {
        // Don't auto-complete if parent has its own content/description
        if !parent.taskDescription.isEmpty {
            return false
        }

        // Don't auto-complete if parent has attachments
        if !parent.attachments.isEmpty {
            return false
        }

        // Auto-complete if parent seems to be just a container
        return parent.subtaskCount > 0
    }

    private func canAutoCompleteTask(_ task: Task) -> Bool {
        return task.hasSubtasks && task.subtasks.allSatisfy(\.isCompleted)
    }

    private func findBlockedSubtasks(_ task: Task) -> [Task] {
        return task.subtasks.filter { subtask in
            // A subtask is "blocked" if it has dependencies or constraints
            // For now, we'll consider subtasks with start dates in the future as blocked
            if let startDate = subtask.startDate, startDate > Date() {
                return true
            }
            return false
        }
    }

    // MARK: - Safe Wrapper Methods

    /// Toggle subtask completion safely
    func toggleSubtaskCompletionSafely(
        _ subtask: Task,
        strategy: SubtaskCompletionStrategy = .hybrid
    ) -> Bool {
        switch toggleSubtaskCompletion(subtask, strategy: strategy) {
        case .success:
            return true
        case .failure(let error):
            lastError = error.wrapped
            return false
        }
    }

    /// Set subtask completion safely
    func setSubtaskCompletionSafely(
        _ subtask: Task,
        completed: Bool,
        strategy: SubtaskCompletionStrategy = .hybrid
    ) -> Bool {
        switch setSubtaskCompletion(subtask, completed: completed, strategy: strategy) {
        case .success:
            return true
        case .failure(let error):
            lastError = error.wrapped
            return false
        }
    }

    /// Bulk complete subtasks safely
    func bulkCompleteSubtasksSafely(
        _ subtasks: [Task],
        of parent: Task,
        strategy: SubtaskCompletionStrategy = .hybrid
    ) -> Bool {
        switch bulkCompleteSubtasks(subtasks, of: parent, strategy: strategy) {
        case .success:
            return true
        case .failure(let error):
            lastError = error.wrapped
            return false
        }
    }
}

// MARK: - Completion Analysis

struct SubtaskCompletionAnalysis {
    let task: Task
    let totalSubtasks: Int
    let completedSubtasks: Int
    let partiallyCompleteSubtasks: Int
    let canAutoComplete: Bool
    let shouldPropagateUp: Bool
    let blockedSubtasks: [Task]

    var completionPercentage: Double {
        guard totalSubtasks > 0 else { return 0 }
        return Double(completedSubtasks) / Double(totalSubtasks)
    }

    var isFullyComplete: Bool {
        totalSubtasks > 0 && completedSubtasks == totalSubtasks
    }

    var isPartiallyComplete: Bool {
        completedSubtasks > 0 && completedSubtasks < totalSubtasks
    }

    var hasBlockedSubtasks: Bool {
        !blockedSubtasks.isEmpty
    }

    var completionStatus: CompletionStatus {
        if isFullyComplete {
            return .complete
        } else if isPartiallyComplete {
            return .inProgress
        } else if hasBlockedSubtasks {
            return .blocked
        } else {
            return .notStarted
        }
    }

    enum CompletionStatus {
        case notStarted, inProgress, blocked, complete

        var description: String {
            switch self {
            case .notStarted: return "Not Started"
            case .inProgress: return "In Progress"
            case .blocked: return "Blocked"
            case .complete: return "Complete"
            }
        }

        var color: Color {
            switch self {
            case .notStarted: return .daisyTextSecondary
            case .inProgress: return .daisyTask
            case .blocked: return .daisyWarning
            case .complete: return .daisySuccess
            }
        }
    }
}

// MARK: - Completion State Management

extension TaskManager {
    /// Get completion strategy for a task (could be stored as a property in the future)
    func getCompletionStrategy(for task: Task) -> SubtaskCompletionStrategy {
        // For now, return hybrid as default
        // In the future, this could be a stored property on Task
        return .hybrid
    }

    /// Set completion strategy for a task
    func setCompletionStrategy(
        _ strategy: SubtaskCompletionStrategy,
        for task: Task
    ) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "set completion strategy",
            entityType: "task"
        ) {
            // In the future, this would update a stored property on Task
            // For now, we'll just validate the strategy is supported
            _ = strategy // Placeholder

            try modelContext.save()
        }
    }
}