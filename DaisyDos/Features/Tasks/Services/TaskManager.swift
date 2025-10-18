//
//  TaskManager.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData

@Observable
class TaskManager {
    internal let modelContext: ModelContext

    // Error handling
    var lastError: (any RecoverableError)?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Computed Properties for Filtered Data

    var allTasks: [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.parentTask == nil
            },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var completedTasks: [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.isCompleted == true && task.parentTask == nil
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

    var todaysTasks: [Task] {
        // Show all incomplete tasks as "today's tasks" for now
        // In Phase 2, this will be enhanced with due dates
        return pendingTasks
    }

    // MARK: - CRUD Operations

    func createTask(title: String) -> Result<Task, AnyRecoverableError> {
        return ErrorTransformer.safely(
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
    }

    /// Enhanced task creation with full parameter support
    func createTask(
        title: String,
        taskDescription: String = "",
        priority: Priority = .medium,
        dueDate: Date? = nil,
        recurrenceRule: RecurrenceRule? = nil
    ) -> Result<Task, AnyRecoverableError> {
        return ErrorTransformer.safely(
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
                recurrenceRule: recurrenceRule
            )

            modelContext.insert(task)
            try modelContext.save()
            return task
        }
    }

    func updateTask(_ task: Task, title: String? = nil, isCompleted: Bool? = nil) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "update task",
            entityType: "task"
        ) {
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
                task.setCompleted(isCompleted)
                hasChanges = true
            }

            if hasChanges {
                task.modifiedDate = Date()
                try modelContext.save()
            }
        }
    }

    func toggleTaskCompletion(_ task: Task) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "toggle task completion",
            entityType: "task"
        ) {
            task.toggleCompletion()
            try modelContext.save()
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
        return ErrorTransformer.safely(
            operation: "delete task",
            entityType: "task"
        ) {
            modelContext.delete(task)
            try modelContext.save()
        }
    }

    func deleteTasks(_ tasks: [Task]) -> Result<Void, AnyRecoverableError> {
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

            let descriptor = FetchDescriptor<Task>(
                predicate: #Predicate<Task> { task in
                    task.parentTask == nil && (
                        task.title.localizedStandardContains(trimmedQuery) ||
                        task.taskDescription.localizedStandardContains(trimmedQuery)
                    )
                },
                sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
            )
            return try modelContext.fetch(descriptor)
        }
    }

    func tasksWithTag(_ tag: Tag) -> [Task] {
        // For now, fetch all tasks and filter in memory since @Predicate with contains is complex
        return allTasks.filter { task in
            task.tags.contains { $0.id == tag.id }
        }
    }

    // MARK: - Enhanced Filtering and Sorting

    func tasksByPriority(_ priority: Priority) -> [Task] {
        return allTasks.filter { $0.priority == priority }
    }

    func overdueTasks() -> [Task] {
        return allTasks.filter { $0.hasOverdueStatus }
    }

    func tasksDueToday() -> [Task] {
        return allTasks.filter { $0.isDueToday }
    }

    func tasksDueSoon() -> [Task] {
        return allTasks.filter { $0.isDueSoon }
    }

    func tasksWithDueDates() -> [Task] {
        return allTasks.filter { $0.dueDate != nil }
    }

    func tasksWithRecurrence() -> [Task] {
        return allTasks.filter { $0.hasRecurrence }
    }

    func rootTasks() -> [Task] {
        return allTasks.filter { $0.isRootTask }
    }

    // MARK: - Subtask Management

    func createSubtask(
        for parentTask: Task,
        title: String,
        taskDescription: String = "",
        priority: Priority = .none
    ) -> Result<Task, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "create subtask",
            entityType: "task"
        ) {
            guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw DaisyDosError.validationFailed("title")
            }

            // Prevent subtasks of subtasks - only one level allowed
            guard parentTask.parentTask == nil else {
                throw DaisyDosError.circularReference
            }

            let subtask = parentTask.createSubtask(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                taskDescription: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                priority: priority
            )

            modelContext.insert(subtask)
            try modelContext.save()
            return subtask
        }
    }

    func moveSubtask(
        _ subtask: Task,
        to newParent: Task?
    ) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "move subtask",
            entityType: "task"
        ) {
            // Remove from current parent
            if let currentParent = subtask.parentTask {
                currentParent.removeSubtask(subtask)
            }

            // Add to new parent
            if let newParent = newParent {
                guard newParent.addSubtask(subtask) else {
                    throw DaisyDosError.circularReference
                }
            }

            try modelContext.save()
        }
    }

    /// Moves a subtask up one position in its parent's subtask list
    func moveSubtaskUp(_ subtask: Task) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "move subtask up",
            entityType: "task"
        ) {
            guard let parent = subtask.parentTask else {
                throw DaisyDosError.validationFailed("Subtask has no parent")
            }

            parent.moveSubtaskUp(subtask)
            try modelContext.save()
        }
    }

    /// Moves a subtask down one position in its parent's subtask list
    func moveSubtaskDown(_ subtask: Task) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "move subtask down",
            entityType: "task"
        ) {
            guard let parent = subtask.parentTask else {
                throw DaisyDosError.validationFailed("Subtask has no parent")
            }

            parent.moveSubtaskDown(subtask)
            try modelContext.save()
        }
    }

    // MARK: - Helper Methods

    // MARK: - Attachment Management

    func addAttachment(
        _ attachment: TaskAttachment,
        to task: Task
    ) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "add attachment",
            entityType: "task"
        ) {
            guard task.addAttachment(attachment) else {
                throw DaisyDosError.attachmentLimitExceeded
            }

            modelContext.insert(attachment)
            try modelContext.save()
        }
    }

    func removeAttachment(
        _ attachment: TaskAttachment,
        from task: Task
    ) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "remove attachment",
            entityType: "task"
        ) {
            task.removeAttachment(attachment)
            modelContext.delete(attachment)
            try modelContext.save()
        }
    }

    // MARK: - Recurrence Management

    func processRecurringTasks() -> Result<[Task], AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "process recurring tasks",
            entityType: "task"
        ) {
            let completedRecurringTasks = completedTasks.filter { $0.hasRecurrence }
            var newTasks: [Task] = []

            for completedTask in completedRecurringTasks {
                if let newTask = completedTask.createRecurringInstance() {
                    modelContext.insert(newTask)
                    newTasks.append(newTask)
                }
            }

            if !newTasks.isEmpty {
                try modelContext.save()
            }

            return newTasks
        }
    }

    // MARK: - Enhanced Today's Tasks

    var enhancedTodaysTasks: [Task] {
        let today = Date()
        let calendar = Calendar.current

        return allTasks.filter { task in
            guard !task.isCompleted else { return false }

            // Include if due today
            if let dueDate = task.dueDate, calendar.isDate(dueDate, inSameDayAs: today) {
                return true
            }

            // Include if overdue
            if task.hasOverdueStatus {
                return true
            }

            // Include if no due date
            if task.dueDate == nil {
                return true
            }

            return false
        }.sorted { first, second in
            // Sort by priority first, then by due date
            if first.priority != second.priority {
                return first.priority > second.priority
            }

            // Sort overdue tasks first
            if first.hasOverdueStatus != second.hasOverdueStatus {
                return first.hasOverdueStatus
            }

            // Sort by due date
            switch (first.dueDate, second.dueDate) {
            case (let date1?, let date2?):
                return date1 < date2
            case (nil, _?):
                return false // Tasks without due dates come after those with due dates
            case (_?, nil):
                return true
            case (nil, nil):
                return first.createdDate > second.createdDate // Most recent first for tasks without due dates
            }
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
            for tag in task.tags {
                _ = duplicateTask.addTag(tag)
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

    /// Update a task and handle errors internally
    func updateTaskSafely(_ task: Task, title: String? = nil, isCompleted: Bool? = nil) -> Bool {
        switch updateTask(task, title: title, isCompleted: isCompleted) {
        case .success:
            return true
        case .failure(let error):
            lastError = error.wrapped
            return false
        }
    }

    /// Enhanced update task with all properties and handle errors internally
    func updateTaskSafely(
        _ task: Task,
        title: String? = nil,
        taskDescription: String? = nil,
        priority: Priority? = nil,
        dueDate: Date? = nil,
        recurrenceRule: RecurrenceRule? = nil,
        isCompleted: Bool? = nil
    ) -> Bool {
        switch updateTask(
            task,
            title: title,
            taskDescription: taskDescription,
            priority: priority,
            dueDate: dueDate,
            recurrenceRule: recurrenceRule,
            isCompleted: isCompleted
        ) {
        case .success:
            return true
        case .failure(let error):
            lastError = error.wrapped
            return false
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