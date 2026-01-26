//
//  PendingRecurrence.swift
//  DaisyDos
//
//  Created by Claude Code
//  Stores scheduled recurring task creation for deferred recreation
//

import Foundation
import SwiftData

/// Represents a scheduled recurring task creation that will be processed when its scheduled time arrives
/// Instead of creating recurring tasks immediately on completion, we store a PendingRecurrence
/// and create the actual task when the app is opened after the scheduled date
@Model
class PendingRecurrence {
    // MARK: - Core Properties

    var id: UUID = UUID()

    /// The date/time when this recurrence should become visible (the new task's due date)
    var scheduledDate: Date = Date()

    /// Reference to the completed task that triggered this recurrence
    var sourceTaskId: UUID = UUID()

    /// Cached task data for recreation (in case source task is deleted)
    var taskTitle: String = ""
    var taskDescription: String = ""
    var taskPriority: Priority = Priority.none

    /// The recurrence rule (stored as the new task's recurrence)
    var recurrenceRule: RecurrenceRule?

    /// Tags to copy (stored as tag IDs for lookup)
    var tagIds: [UUID]?

    /// Alert time for recurring task notifications (inherited from source task)
    var alertTimeHour: Int?
    var alertTimeMinute: Int?

    /// When this pending recurrence was created
    var createdDate: Date = Date()

    // MARK: - Initializers

    init(
        scheduledDate: Date,
        sourceTask: Task
    ) {
        self.id = UUID()
        self.scheduledDate = scheduledDate
        self.sourceTaskId = sourceTask.id
        self.taskTitle = sourceTask.title
        self.taskDescription = sourceTask.taskDescription
        self.taskPriority = sourceTask.priority
        self.recurrenceRule = sourceTask.recurrenceRule
        self.tagIds = sourceTask.tags?.map { $0.id }
        self.alertTimeHour = sourceTask.alertTimeHour // Inherit alert time
        self.alertTimeMinute = sourceTask.alertTimeMinute
        self.createdDate = Date()
    }

}

// MARK: - Equatable Conformance

extension PendingRecurrence: Equatable {
    static func == (lhs: PendingRecurrence, rhs: PendingRecurrence) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable Conformance

extension PendingRecurrence: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
