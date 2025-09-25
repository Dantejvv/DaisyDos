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
    private let modelContext: ModelContext

    // Error handling
    var lastError: (any RecoverableError)?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Computed Properties for Filtered Data

    var allTasks: [Task] {
        let descriptor = FetchDescriptor<Task>(sortBy: [SortDescriptor(\.createdDate, order: .reverse)])
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

    var todaysTasks: [Task] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.createdDate >= today && task.createdDate < tomorrow
            },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
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
            try modelContext.save()
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
                    task.title.localizedStandardContains(trimmedQuery)
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