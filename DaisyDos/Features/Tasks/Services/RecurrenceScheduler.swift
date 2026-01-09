//
//  RecurrenceScheduler.swift
//  DaisyDos
//
//  Created by Claude Code
//  Manages deferred recurring task creation
//

import Foundation
import SwiftData

// MARK: - Notification Names

extension Notification.Name {
    static let pendingRecurrenceCreated = Notification.Name("pendingRecurrenceCreated")
}

/// Manages the scheduling and processing of deferred recurring task creation
/// When a recurring task is completed, instead of immediately creating the next instance,
/// we create a PendingRecurrence that will be processed when the scheduled time arrives
@Observable
class RecurrenceScheduler {
    internal let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Scheduling

    /// Schedules a new recurring task instance to be created at the specified date
    /// Called when a recurring task is completed instead of creating the new task immediately
    func schedulePendingRecurrence(for task: Task) -> Result<PendingRecurrence, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "schedule pending recurrence",
            entityType: "pending recurrence"
        ) {
            guard let recurrenceRule = task.recurrenceRule else {
                throw DaisyDosError.invalidRecurrence
            }

            // Check if maxOccurrences limit has been reached
            if let maxOccurrences = recurrenceRule.maxOccurrences,
               task.occurrenceIndex >= maxOccurrences {
                throw DaisyDosError.validationFailed("Maximum occurrences reached")
            }

            // Calculate the next occurrence date
            guard let nextDate = task.nextRecurrence() else {
                throw DaisyDosError.validationFailed("No next occurrence available")
            }

            // Check recreateIfIncomplete flag
            if !task.isCompleted && !recurrenceRule.recreateIfIncomplete {
                throw DaisyDosError.validationFailed("Task not completed and recreateIfIncomplete is false")
            }

            // Create the pending recurrence
            let pendingRecurrence = PendingRecurrence(
                scheduledDate: nextDate,
                sourceTask: task
            )

            modelContext.insert(pendingRecurrence)
            try modelContext.save()

            #if DEBUG
            print("Scheduled pending recurrence for '\(task.title)' at \(nextDate.formatted())")
            #endif

            // Notify that a pending recurrence was created
            NotificationCenter.default.post(
                name: .pendingRecurrenceCreated,
                object: nil,
                userInfo: ["pendingRecurrenceId": pendingRecurrence.id.uuidString]
            )

            return pendingRecurrence
        }
    }

    // MARK: - Processing

    /// Processes all pending recurrences that are ready (scheduled time has passed)
    /// Should be called when the app comes to foreground
    func processPendingRecurrences() -> Result<[Task], AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "process pending recurrences",
            entityType: "task"
        ) {
            let now = Date()

            // Fetch all pending recurrences that are ready
            let descriptor = FetchDescriptor<PendingRecurrence>(
                predicate: #Predicate<PendingRecurrence> { pendingRecurrence in
                    pendingRecurrence.scheduledDate <= now
                }
            )

            let readyRecurrences = try modelContext.fetch(descriptor)

            guard !readyRecurrences.isEmpty else {
                #if DEBUG
                print("No pending recurrences ready for processing")
                #endif
                return []
            }

            #if DEBUG
            print("Processing \(readyRecurrences.count) pending recurrence(s)")
            #endif

            var createdTasks: [Task] = []

            for pendingRecurrence in readyRecurrences {
                if let newTask = createTaskFromPendingRecurrence(pendingRecurrence) {
                    createdTasks.append(newTask)
                }

                // Delete the processed pending recurrence
                modelContext.delete(pendingRecurrence)
            }

            try modelContext.save()

            // Notify about each created task for notification scheduling
            for task in createdTasks {
                NotificationCenter.default.post(
                    name: .taskDidChange,
                    object: nil,
                    userInfo: ["taskId": task.id.uuidString]
                )
            }

            return createdTasks
        }
    }

    /// Creates a task from a pending recurrence record
    private func createTaskFromPendingRecurrence(_ pendingRecurrence: PendingRecurrence) -> Task? {
        let newTask = Task(
            title: pendingRecurrence.taskTitle,
            taskDescription: pendingRecurrence.taskDescription,
            priority: pendingRecurrence.taskPriority,
            dueDate: pendingRecurrence.scheduledDate,
            recurrenceRule: pendingRecurrence.recurrenceRule,
            reminderDate: nil // Recurring instances don't inherit reminders
        )

        // Set occurrence index
        newTask.occurrenceIndex = pendingRecurrence.occurrenceIndex

        modelContext.insert(newTask)

        // Restore tags if available
        if let tagIds = pendingRecurrence.tagIds, !tagIds.isEmpty {
            restoreTagsForTask(newTask, tagIds: tagIds)
        }

        #if DEBUG
        print("Created task '\(newTask.title)' from pending recurrence (due: \(newTask.dueDate?.formatted() ?? "none"))")
        #endif

        return newTask
    }

    /// Restores tags from tag IDs
    private func restoreTagsForTask(_ task: Task, tagIds: [UUID]) {
        let descriptor = FetchDescriptor<Tag>()

        guard let allTags = try? modelContext.fetch(descriptor) else { return }

        for tagId in tagIds {
            if let tag = allTags.first(where: { $0.id == tagId }) {
                _ = task.addTag(tag)
            }
        }
    }

    // MARK: - Queries

    /// Returns all pending recurrences
    var allPendingRecurrences: [PendingRecurrence] {
        let descriptor = FetchDescriptor<PendingRecurrence>(
            sortBy: [SortDescriptor(\.scheduledDate, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Returns pending recurrences that are ready to be processed
    var readyPendingRecurrences: [PendingRecurrence] {
        let now = Date()
        let descriptor = FetchDescriptor<PendingRecurrence>(
            predicate: #Predicate<PendingRecurrence> { pendingRecurrence in
                pendingRecurrence.scheduledDate <= now
            },
            sortBy: [SortDescriptor(\.scheduledDate, order: .forward)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Returns the count of pending recurrences
    var pendingCount: Int {
        allPendingRecurrences.count
    }

    /// Returns the count of ready pending recurrences
    var readyCount: Int {
        readyPendingRecurrences.count
    }

    // MARK: - Cancellation

    /// Cancels a pending recurrence (e.g., if user removes recurrence from original task)
    func cancelPendingRecurrence(for sourceTaskId: UUID) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "cancel pending recurrence",
            entityType: "pending recurrence"
        ) {
            let descriptor = FetchDescriptor<PendingRecurrence>(
                predicate: #Predicate<PendingRecurrence> { pendingRecurrence in
                    pendingRecurrence.sourceTaskId == sourceTaskId
                }
            )

            let pendingRecurrences = try modelContext.fetch(descriptor)

            for pendingRecurrence in pendingRecurrences {
                modelContext.delete(pendingRecurrence)
            }

            if !pendingRecurrences.isEmpty {
                try modelContext.save()

                #if DEBUG
                print("Cancelled \(pendingRecurrences.count) pending recurrence(s) for task \(sourceTaskId)")
                #endif
            }
        }
    }

    /// Cancels all pending recurrences (useful for testing or reset scenarios)
    func cancelAllPendingRecurrences() -> Result<Int, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "cancel all pending recurrences",
            entityType: "pending recurrence"
        ) {
            let descriptor = FetchDescriptor<PendingRecurrence>()
            let allPending = try modelContext.fetch(descriptor)
            let count = allPending.count

            for pendingRecurrence in allPending {
                modelContext.delete(pendingRecurrence)
            }

            if count > 0 {
                try modelContext.save()

                #if DEBUG
                print("Cancelled all \(count) pending recurrence(s)")
                #endif
            }

            return count
        }
    }
}
