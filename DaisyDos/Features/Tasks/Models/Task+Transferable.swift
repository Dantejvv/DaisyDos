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

            let currentIndex = parent.subtasks?.firstIndex(of: task) ?? -1
            return SubtaskMoveData(
                taskId: task.id,
                parentTaskId: parent.id,
                currentIndex: currentIndex
            )
        } importing: { (moveData: SubtaskMoveData) in
            // This should not be used for importing - drop handler manages moves
            Task(title: "Moving...")
        }

        // External apps - text representation
        ProxyRepresentation(exporting: \.title) { title in
            Task(title: title)
        }
    }
}


