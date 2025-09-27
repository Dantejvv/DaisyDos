//
//  Task+Transferable.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Custom UTType for Task

extension UTType {
    static let daisyTask = UTType(exportedAs: "com.daisydos.task")
}

// MARK: - Task Transferable Implementation

extension Task: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        // Text representation for external apps
        ProxyRepresentation(exporting: \.title) { title in
            Task(title: title)
        }
    }
}

// MARK: - Drag Data for Subtask Operations

struct SubtaskDragData: Codable, Transferable {
    let taskId: UUID
    let title: String
    let currentParentId: UUID?
    let nestingLevel: Int

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .daisySubtaskData)
    }
}

extension UTType {
    static let daisySubtaskData = UTType(exportedAs: "com.daisydos.subtask-data")
}

// MARK: - Drag Operation Types

enum SubtaskDragOperation {
    case reorder(from: Int, to: Int)
    case reparent(task: Task, newParent: Task?)
    case nestingLevelChange(task: Task, newLevel: Int)
}

// MARK: - Drag & Drop Validation

extension Task {
    /// Validates if a task can be moved to a new parent without creating circular references
    func canBeMovedTo(newParent: Task?) -> Bool {
        // Allow moving to root (no parent)
        guard let newParent = newParent else { return true }

        // Cannot move to self
        if newParent.id == self.id { return false }

        // Cannot move to one of our descendants (circular reference)
        return !newParent.hasAncestorForDrag(self)
    }

    /// Validates if the nesting level would be acceptable
    func canBeMovedToNestingLevel(_ level: Int, maxDepth: Int = 10) -> Bool {
        let wouldExceedDepth = level + subtaskDepth > maxDepth
        return !wouldExceedDepth
    }

    /// Gets the maximum depth of subtasks under this task
    var subtaskDepth: Int {
        guard hasSubtasks else { return 0 }

        let maxChildDepth = subtasks.map(\.subtaskDepth).max() ?? 0
        return maxChildDepth + 1
    }

    /// Checks if this task has the given task as an ancestor (for drag validation)
    func hasAncestorForDrag(_ potentialAncestor: Task) -> Bool {
        var current = self.parentTask
        while let parent = current {
            if parent.id == potentialAncestor.id {
                return true
            }
            current = parent.parentTask
        }
        return false
    }
}

// MARK: - Drag Preview Configuration

struct TaskDragPreview: View {
    let task: Task
    let nestingLevel: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .daisySuccess : .daisyTextSecondary)

            Text(task.title)
                .font(.body)
                .lineLimit(1)

            if task.hasSubtasks {
                Text("(\(task.subtaskCount))")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.daisyTask, lineWidth: 1)
        )
        .shadow(radius: 4)
    }
}

// MARK: - Drop Handling

struct SubtaskDropHandler {
    let parentTask: Task
    let taskManager: TaskManager

    func canAcceptDrop(of draggedTasks: [Task]) -> Bool {
        guard let draggedTask = draggedTasks.first else { return false }

        // Basic validation
        return draggedTask.canBeMovedTo(newParent: parentTask) &&
               draggedTask.canBeMovedToNestingLevel(parentTask.nestingLevel + 1)
    }

    func performDrop(of draggedTasks: [Task], at index: Int? = nil) -> Bool {
        guard let draggedTask = draggedTasks.first,
              canAcceptDrop(of: draggedTasks) else {
            return false
        }

        // Move the task to the new parent
        let result = taskManager.moveSubtask(draggedTask, to: parentTask)

        switch result {
        case .success:
            // If an index was specified, reorder within the parent's subtasks
            if let index = index {
                reorderSubtask(draggedTask, to: index)
            }
            return true
        case .failure:
            return false
        }
    }

    private func reorderSubtask(_ subtask: Task, to index: Int) {
        // This would be implemented as part of enhanced TaskManager functionality
        // For now, we'll rely on the natural sorting in SubtaskListView
    }
}

extension Task {
    /// Helper property to get nesting level
    var nestingLevel: Int {
        var level = 0
        var current = self.parentTask
        while current != nil {
            level += 1
            current = current?.parentTask
        }
        return level
    }
}