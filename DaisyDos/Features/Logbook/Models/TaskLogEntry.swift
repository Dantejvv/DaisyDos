//
//  TaskLogEntry.swift
//  DaisyDos
//
//  Created by Claude Code on 10/11/25.
//  Lightweight snapshot of completed task for archival (91-365 days)
//

import Foundation
import SwiftData

@Model
class TaskLogEntry {
    // MARK: - Core Properties (CloudKit-compatible: all have defaults)

    var id: UUID = UUID()
    var originalTaskId: UUID = UUID()  // Reference to original task
    var title: String = ""
    var taskDescription: String = ""

    // MARK: - Completion Metadata

    var completedDate: Date = Date()
    var createdDate: Date = Date()
    var dueDate: Date?

    // MARK: - Task Properties Snapshot

    var priority: Priority = Priority.none
    var wasOverdue: Bool = false
    var subtaskCount: Int = 0
    var completedSubtaskCount: Int = 0
    var wasSubtask: Bool = false  // Was this a subtask of another task?
    var parentTaskTitle: String?  // Title of parent task if this was a subtask

    // MARK: - Tag Snapshot (names only, no relationships)

    var tagNames: [String] = []

    // MARK: - Analytics Metadata

    /// Time from task creation to completion
    var completionDuration: TimeInterval?

    // MARK: - Initializers

    init(
        originalTaskId: UUID,
        title: String,
        taskDescription: String,
        completedDate: Date,
        createdDate: Date,
        dueDate: Date?,
        priority: Priority,
        wasOverdue: Bool,
        subtaskCount: Int,
        completedSubtaskCount: Int,
        wasSubtask: Bool,
        parentTaskTitle: String?,
        tagNames: [String],
        completionDuration: TimeInterval?
    ) {
        self.id = UUID()
        self.originalTaskId = originalTaskId
        self.title = title
        self.taskDescription = taskDescription
        self.completedDate = completedDate
        self.createdDate = createdDate
        self.dueDate = dueDate
        self.priority = priority
        self.wasOverdue = wasOverdue
        self.subtaskCount = subtaskCount
        self.completedSubtaskCount = completedSubtaskCount
        self.wasSubtask = wasSubtask
        self.parentTaskTitle = parentTaskTitle
        self.tagNames = tagNames
        self.completionDuration = completionDuration
    }

    /// Convenience initializer from Task
    convenience init(from task: Task) {
        let completedDate = task.completedDate ?? Date()
        let createdDate = task.createdDate

        // Calculate completion duration
        let duration = completedDate.timeIntervalSince(createdDate)

        // Check if task was overdue at completion time
        let wasOverdue: Bool = {
            guard let dueDate = task.dueDate else { return false }
            return completedDate > dueDate
        }()

        self.init(
            originalTaskId: task.id,
            title: task.title,
            taskDescription: task.taskDescription,
            completedDate: completedDate,
            createdDate: createdDate,
            dueDate: task.dueDate,
            priority: task.priority,
            wasOverdue: wasOverdue,
            subtaskCount: task.subtaskCount,
            completedSubtaskCount: task.completedSubtaskCount,
            wasSubtask: task.parentTask != nil,
            parentTaskTitle: task.parentTask?.title,
            tagNames: (task.tags ?? []).map { $0.name },
            completionDuration: duration
        )
    }

    // MARK: - Display Helpers

    var displayTitle: String {
        return title.isEmpty ? "Untitled Task" : title
    }

    var completionDurationFormatted: String {
        guard let duration = completionDuration else { return "N/A" }

        let days = Int(duration / 86400)
        let hours = Int((duration.truncatingRemainder(dividingBy: 86400)) / 3600)

        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            let minutes = Int(duration / 60)
            return "\(minutes)m"
        }
    }

    var formattedCompletedDate: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(completedDate) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(completedDate) {
            return "Yesterday"
        } else if Calendar.current.isDate(completedDate, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }
        return formatter.string(from: completedDate)
    }
}
