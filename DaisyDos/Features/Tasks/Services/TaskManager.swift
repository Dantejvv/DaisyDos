//
//  TaskManager.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - Notification Names

extension Notification.Name {
    static let taskDidChange = Notification.Name("taskDidChange")
    static let taskWasDeleted = Notification.Name("taskWasDeleted")
    static let taskWasCompleted = Notification.Name("taskWasCompleted")
}

@Observable
class TaskManager: EntityManagerProtocol {
    typealias Entity = Task

    internal let modelContext: ModelContext

    // Recurrence scheduler for deferred task creation (excluded from observation)
    @ObservationIgnored
    private var _recurrenceScheduler: RecurrenceScheduler?
    private var recurrenceScheduler: RecurrenceScheduler {
        if _recurrenceScheduler == nil {
            _recurrenceScheduler = RecurrenceScheduler(modelContext: modelContext)
        }
        return _recurrenceScheduler!
    }

    // Error handling
    var lastError: (any RecoverableError)?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Notification Helpers

    /// Notify that a task has changed and needs notification rescheduling
    private func notifyTaskChanged(_ task: Task) {
        NotificationCenter.default.post(
            name: .taskDidChange,
            object: nil,
            userInfo: ["taskId": task.id.uuidString]
        )
    }

    /// Notify that a task was completed
    private func notifyTaskCompleted(_ task: Task) {
        NotificationCenter.default.post(
            name: .taskWasCompleted,
            object: nil,
            userInfo: ["taskId": task.id.uuidString]
        )

        // Schedule deferred recurring instance creation (task appears at scheduled time, not immediately)
        if task.hasRecurrence {
            scheduleRecurringInstanceIfNeeded(for: task)
        }
    }

    // MARK: - Computed Properties for Filtered Data

    var allTasks: [Task] {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var completedTasks: [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.isCompleted == true
            },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var pendingTasks: [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.isCompleted == false
            },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - CRUD Operations

    func createTask(title: String) -> Result<Task, AnyRecoverableError> {
        let result = ErrorTransformer.safely(
            operation: "create task",
            entityType: "task"
        ) {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DaisyDosError.validationFailed("title")
            }

            let task = Task(title: title.trimmingCharacters(in: .whitespacesAndNewlines))
            modelContext.insert(task)
            try modelContext.save()
            return task
        }

        // Notify after successful creation for notification scheduling
        if case .success(let task) = result {
            notifyTaskChanged(task)
        }

        return result
    }

    /// Enhanced task creation with full parameter support - atomic batch save
    /// All properties are saved in a single transaction for data integrity
    func createTask(
        title: String,
        taskDescription: String = "",
        priority: Priority = .medium,
        dueDate: Date? = nil,
        recurrenceRule: RecurrenceRule? = nil,
        tags: [Tag] = [],
        reminderDate: Date? = nil,
        alertTimeHour: Int? = nil,
        alertTimeMinute: Int? = nil,
        subtaskTitles: [(title: String, order: Int)] = [],
        attachmentURLs: [URL] = []
    ) -> Result<Task, AnyRecoverableError> {
        let result = ErrorTransformer.safely(
            operation: "create enhanced task",
            entityType: "task"
        ) {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DaisyDosError.validationFailed("title")
            }

            // Validate recurrence rule
            if let recurrenceRule = recurrenceRule, !recurrenceRule.isValid {
                throw DaisyDosError.invalidRecurrence
            }

            let task = Task(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                taskDescription: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                priority: priority,
                dueDate: dueDate,
                recurrenceRule: recurrenceRule,
                reminderDate: reminderDate,
                alertTimeHour: alertTimeHour,
                alertTimeMinute: alertTimeMinute
            )

            modelContext.insert(task)

            // Add tags (up to 5)
            for tag in tags.prefix(5) {
                _ = task.addTag(tag)
            }

            // Create and add subtasks
            for (subtaskTitle, order) in subtaskTitles {
                let trimmedTitle = subtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedTitle.isEmpty else { continue }

                let subtask = Subtask(title: trimmedTitle, subtaskOrder: order)
                subtask.createdDate = task.createdDate

                modelContext.insert(subtask)
                _ = task.addSubtask(subtask)
            }

            // Add attachments
            for fileURL in attachmentURLs {
                // Try to access security-scoped resource if needed
                let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
                defer {
                    if didStartAccessing {
                        fileURL.stopAccessingSecurityScopedResource()
                    }
                }

                // Read file data
                guard let fileData = try? Data(contentsOf: fileURL) else { continue }
                let fileName = fileURL.lastPathComponent
                let fileSize = Int64(fileData.count)

                // Skip files that are too large
                guard fileSize <= TaskAttachment.maxFileSize else { continue }

                // Detect MIME type
                let mimeType: String
                if let uti = UTType(filenameExtension: fileURL.pathExtension),
                   let mime = uti.preferredMIMEType {
                    mimeType = mime
                } else {
                    mimeType = "application/octet-stream"
                }

                let attachment = TaskAttachment(
                    fileName: fileName,
                    fileSize: fileSize,
                    mimeType: mimeType,
                    fileData: fileData,
                    thumbnailData: nil
                )

                if task.attachments == nil { task.attachments = [] }
                task.attachments!.append(attachment)
            }

            // Single atomic save for all data
            try modelContext.save()
            return task
        }

        // Notify after successful creation for notification scheduling
        if case .success(let task) = result {
            notifyTaskChanged(task)
        }

        return result
    }

    func updateTask(_ task: Task, title: String? = nil, isCompleted: Bool? = nil) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "update task",
            entityType: "task"
        ) {
            var wasCompleted = task.isCompleted

            if let title = title {
                let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedTitle.isEmpty else {
                    throw DaisyDosError.validationFailed("title")
                }
                task.title = trimmedTitle
            }
            if let isCompleted = isCompleted {
                task.isCompleted = isCompleted
            }
            task.modifiedDate = Date()
            try modelContext.save()

            // Notify about changes
            if task.isCompleted && !wasCompleted {
                notifyTaskCompleted(task)
            } else {
                notifyTaskChanged(task)
            }
        }
    }

    /// Enhanced task update with all supported properties
    func updateTask(
        _ task: Task,
        title: String? = nil,
        taskDescription: String? = nil,
        priority: Priority? = nil,
        dueDate: Date? = nil,
        recurrenceRule: RecurrenceRule? = nil,
        isCompleted: Bool? = nil
    ) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "update enhanced task",
            entityType: "task"
        ) {
            var hasChanges = false

            if let title = title {
                let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedTitle.isEmpty else {
                    throw DaisyDosError.validationFailed("title")
                }
                task.title = trimmedTitle
                hasChanges = true
            }

            if let taskDescription = taskDescription {
                task.taskDescription = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                hasChanges = true
            }

            if let priority = priority {
                task.priority = priority
                hasChanges = true
            }

            if let dueDate = dueDate {
                task.dueDate = dueDate
                hasChanges = true
            }

            if let recurrenceRule = recurrenceRule {
                guard recurrenceRule.isValid else {
                    throw DaisyDosError.invalidRecurrence
                }
                task.recurrenceRule = recurrenceRule
                hasChanges = true
            }

            if let isCompleted = isCompleted {
                let wasCompleted = task.isCompleted
                task.setCompleted(isCompleted)
                hasChanges = true

                // Notify if task was just completed
                if isCompleted && !wasCompleted {
                    task.modifiedDate = Date()
                    try modelContext.save()
                    notifyTaskCompleted(task)
                    return // Early return after completion notification
                }
            }

            if hasChanges {
                task.modifiedDate = Date()
                try modelContext.save()
                notifyTaskChanged(task)
            }
        }
    }

    func toggleTaskCompletion(_ task: Task) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "toggle task completion",
            entityType: "task"
        ) {
            let wasCompleted = task.isCompleted
            task.toggleCompletion()
            try modelContext.save()

            if task.isCompleted && !wasCompleted {
                // Task was just completed - cancel notifications
                notifyTaskCompleted(task)
            } else if !task.isCompleted && wasCompleted {
                // Task was uncompleted (undo) - reschedule notifications
                notifyTaskChanged(task)
            }
        }
    }

    /// Recover a completed task by marking it incomplete
    func recoverTask(_ task: Task) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "recover task",
            entityType: "task"
        ) {
            guard task.isCompleted else {
                throw DaisyDosError.validationFailed("Only completed tasks can be recovered")
            }

            task.setCompleted(false)
            task.modifiedDate = Date()
            try modelContext.save()
        }
    }

    func deleteTask(_ task: Task) -> Result<Void, AnyRecoverableError> {
        let taskId = task.id.uuidString // Capture before deletion
        return ErrorTransformer.safely(
            operation: "delete task",
            entityType: "task"
        ) {
            modelContext.delete(task)
            try modelContext.save()

            // Notify that task was deleted to cleanup notifications
            NotificationCenter.default.post(
                name: .taskWasDeleted,
                object: nil,
                userInfo: ["taskId": taskId]
            )
        }
    }

    func deleteTasks(_ tasks: [Task]) -> Result<Void, AnyRecoverableError> {
        let taskIds = tasks.map { $0.id.uuidString } // Capture before deletion
        return ErrorTransformer.safely(
            operation: "delete tasks",
            entityType: "task"
        ) {
            guard !tasks.isEmpty else {
                throw DaisyDosError.validationFailed("task selection")
            }

            for task in tasks {
                modelContext.delete(task)
            }
            try modelContext.save()

            // Notify that tasks were deleted to cleanup notifications
            for taskId in taskIds {
                NotificationCenter.default.post(
                    name: .taskWasDeleted,
                    object: nil,
                    userInfo: ["taskId": taskId]
                )
            }
        }
    }

    // MARK: - Tag Management

    func addTag(_ tag: Tag, to task: Task) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "add tag to task",
            entityType: "task"
        ) {
            guard task.canAddTag() else {
                throw DaisyDosError.tagLimitExceeded
            }

            let success = task.addTag(tag)
            guard success else {
                throw DaisyDosError.duplicateEntity("tag assignment")
            }

            try modelContext.save()
        }
    }

    func removeTag(_ tag: Tag, from task: Task) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "remove tag from task",
            entityType: "task"
        ) {
            task.removeTag(tag)
            try modelContext.save()
        }
    }

    // MARK: - Search and Filtering

    func searchTasks(query: String) -> Result<[Task], AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "search tasks",
            entityType: "task"
        ) {
            let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedQuery.isEmpty else {
                return allTasks
            }

            // Manual filtering because taskDescription is a computed property
            // and can't be used in #Predicate
            return allTasks.filter { task in
                task.title.localizedStandardContains(trimmedQuery) ||
                task.taskDescription.localizedStandardContains(trimmedQuery)
            }
        }
    }

    // MARK: - Subtask Management

    func createSubtask(
        for parentTask: Task,
        title: String
    ) -> Result<Subtask, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "create subtask",
            entityType: "subtask"
        ) {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DaisyDosError.validationFailed("title")
            }

            let subtask = Subtask(title: title.trimmingCharacters(in: .whitespacesAndNewlines))
            subtask.createdDate = parentTask.createdDate

            modelContext.insert(subtask)
            _ = parentTask.addSubtask(subtask)

            try modelContext.save()
            return subtask
        }
    }

    func deleteSubtask(_ subtask: Subtask, from parentTask: Task) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "delete subtask",
            entityType: "subtask"
        ) {
            parentTask.removeSubtask(subtask)
            modelContext.delete(subtask)
            try modelContext.save()
        }
    }

    func updateSubtaskTitle(_ subtask: Subtask, title: String) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "update subtask title",
            entityType: "subtask"
        ) {
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw DaisyDosError.validationFailed("title")
            }
            subtask.updateTitle(trimmed)
            try modelContext.save()
        }
    }

    // MARK: - Helper Methods

    // MARK: - Recurrence Management

    /// Schedules a pending recurrence for deferred task creation
    /// The new task will appear when the app is opened after the scheduled date
    /// Note: All recurring tasks now use "only create after completion" behavior
    private func scheduleRecurringInstanceIfNeeded(for task: Task) {
        guard task.recurrenceRule != nil else { return }

        // Only schedule if task was completed
        guard task.isCompleted else {
            #if DEBUG
            print("⏭️ Skipping recurring instance: task not completed")
            #endif
            return
        }

        // Check if next occurrence exists (respects endDate)
        guard task.nextRecurrence() != nil else {
            #if DEBUG
            print("⏭️ No more occurrences for '\(task.title)' (endDate reached)")
            #endif
            return
        }

        // Schedule the pending recurrence
        let result = recurrenceScheduler.schedulePendingRecurrence(for: task)

        switch result {
        case .success(let pendingRecurrence):
            #if DEBUG
            print("📅 Scheduled recurring instance: '\(task.title)' will appear \(pendingRecurrence.scheduledDate.formatted())")
            #endif
        case .failure(let error):
            #if DEBUG
            print("❌ Failed to schedule recurring instance: \(error.userMessage)")
            #endif
        }
    }

    // MARK: - Task Duplication

    func duplicateTask(_ task: Task) -> Result<Task, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "duplicate task",
            entityType: "task"
        ) {
            let trimmedTitle = task.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else {
                throw DaisyDosError.validationFailed("title")
            }

            // Create new task with "(Copy)" suffix
            let duplicateTitle = "\(trimmedTitle) (Copy)"

            // Adjust due date if it's in the past
            let duplicateDueDate: Date?
            if let dueDate = task.dueDate {
                duplicateDueDate = dueDate > Date() ? dueDate : nil
            } else {
                duplicateDueDate = nil
            }

            let duplicateTask = Task(
                title: duplicateTitle,
                taskDescription: task.taskDescription,
                priority: task.priority,
                dueDate: duplicateDueDate,
                recurrenceRule: task.recurrenceRule
            )

            modelContext.insert(duplicateTask)

            // Copy tags
            for tag in (task.tags ?? []) {
                _ = duplicateTask.addTag(tag)
            }

            // Copy subtasks
            for subtask in (task.subtasks ?? []) {
                let duplicateSubtask = Subtask(title: subtask.title, subtaskOrder: subtask.subtaskOrder)
                modelContext.insert(duplicateSubtask)
                _ = duplicateTask.addSubtask(duplicateSubtask)
            }

            // Copy attachments
            for attachment in (task.attachments ?? []) {
                let duplicateAttachment = TaskAttachment(
                    fileName: attachment.fileName,
                    fileSize: attachment.fileSize,
                    mimeType: attachment.mimeType,
                    fileData: attachment.fileData,
                    thumbnailData: attachment.thumbnailData
                )
                if duplicateTask.attachments == nil {
                    duplicateTask.attachments = []
                }
                duplicateTask.attachments?.append(duplicateAttachment)
                modelContext.insert(duplicateAttachment)
            }

            try modelContext.save()
            return duplicateTask
        }
    }

    /// Duplicate a task and handle errors internally
    func duplicateTaskSafely(_ task: Task) -> Task? {
        switch duplicateTask(task) {
        case .success(let duplicatedTask):
            return duplicatedTask
        case .failure(let error):
            lastError = error.wrapped
            return nil
        }
    }

    // MARK: - Statistics

    var taskCount: Int {
        allTasks.count
    }

    var completedTaskCount: Int {
        completedTasks.count
    }

    var pendingTaskCount: Int {
        pendingTasks.count
    }

    var completionRate: Double {
        guard taskCount > 0 else { return 0.0 }
        return Double(completedTaskCount) / Double(taskCount)
    }

    // MARK: - Convenience Methods (Non-throwing for UI)

    /// Create a task and handle errors internally
    @discardableResult
    func createTaskSafely(title: String) -> Task? {
        switch createTask(title: title) {
        case .success(let task):
            return task
        case .failure(let error):
            lastError = error.wrapped
            return nil
        }
    }

    /// Toggle task completion and handle errors internally
    func toggleTaskCompletionSafely(_ task: Task) -> Bool {
        switch toggleTaskCompletion(task) {
        case .success:
            return true
        case .failure(let error):
            lastError = error.wrapped
            return false
        }
    }

    /// Recover a completed task and handle errors internally
    func recoverTaskSafely(_ task: Task) -> Bool {
        switch recoverTask(task) {
        case .success:
            return true
        case .failure(let error):
            lastError = error.wrapped
            return false
        }
    }

    /// Delete a task and handle errors internally
    func deleteTaskSafely(_ task: Task) -> Bool {
        switch deleteTask(task) {
        case .success:
            return true
        case .failure(let error):
            lastError = error.wrapped
            return false
        }
    }

    /// Add tag to task and handle errors internally
    func addTagSafely(_ tag: Tag, to task: Task) -> Bool {
        switch addTag(tag, to: task) {
        case .success:
            return true
        case .failure(let error):
            lastError = error.wrapped
            return false
        }
    }

    /// Remove tag from task and handle errors internally
    func removeTagSafely(_ tag: Tag, from task: Task) -> Bool {
        switch removeTag(tag, from: task) {
        case .success:
            return true
        case .failure(let error):
            lastError = error.wrapped
            return false
        }
    }

    /// Search tasks and handle errors internally
    func searchTasksSafely(query: String) -> [Task] {
        switch searchTasks(query: query) {
        case .success(let tasks):
            return tasks
        case .failure(let error):
            lastError = error.wrapped
            return []
        }
    }
}