//
//  Task+Transferable.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Custom UTTypes

extension UTType {
    static let daisyTask = UTType(exportedAs: "com.daisydos.task")
    static let daisySubtaskMove = UTType(exportedAs: "com.daisydos.subtask-move")
}

// MARK: - Internal Drag Data for Move Operations

struct SubtaskMoveData: Codable, Transferable {
    let taskId: UUID
    let parentTaskId: UUID  // Required - must match drop target parent
    let currentIndex: Int   // Position in current parent's subtask array

    init(taskId: UUID, parentTaskId: UUID, currentIndex: Int) {
        self.taskId = taskId
        self.parentTaskId = parentTaskId
        self.currentIndex = currentIndex
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .daisySubtaskMove)
    }
}

// MARK: - Task Transferable Implementation

extension Task: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        // For internal operations, use a proxy to SubtaskMoveData
        ProxyRepresentation { task in
            guard let parent = task.parentTask else {
                // Root tasks cannot be reordered via this mechanism
                return SubtaskMoveData(taskId: task.id, parentTaskId: UUID(), currentIndex: -1)
            }

            let currentIndex = parent.subtasks.firstIndex(of: task) ?? -1
            return SubtaskMoveData(
                taskId: task.id,
                parentTaskId: parent.id,
                currentIndex: currentIndex
            )
        } importing: { moveData in
            // This should not be used for importing - drop handler manages moves
            Task(title: "Moving...")
        }

        // External apps - text representation
        ProxyRepresentation(exporting: \.title) { title in
            Task(title: title)
        }
    }
}

// MARK: - Drag & Drop Validation

extension Task {
    /// Validates if a task can be moved to a new parent
    /// With one-level subtasks, we only need to ensure the new parent is not a subtask itself
    func canBeMovedTo(newParent: Task?) -> Bool {
        // Allow moving to root (no parent)
        guard let newParent = newParent else { return true }

        // Cannot move to self
        if newParent.id == self.id { return false }

        // New parent must be a root task (not already a subtask)
        return newParent.parentTask == nil
    }
}

// MARK: - Drag Preview Configuration

struct TaskDragPreview: View {
    let task: Task

    var body: some View {
        HStack(spacing: 8) {
            // Reordering indicator
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.daisyTask)
                .font(.caption)

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

            Text("reordering")
                .font(.caption2)
                .foregroundColor(.daisyTask)
                .italic()

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.daisyTask, lineWidth: 2) // Thicker border for better visibility
        )
        .shadow(color: .daisyTask.opacity(0.3), radius: 8, x: 0, y: 4) // Colored shadow
    }
}

