//
//  TaskDataActor.swift
//  DaisyDos
//
//  Created by Claude Code on 10/21/25.
//  Phase 1: ModelActor pattern implementation for thread-safe SwiftData operations
//

import Foundation
import SwiftData

/// Thread-safe actor for Task data operations
/// Uses @ModelActor to provide isolated ModelContext access, enabling parallel test execution
/// and eliminating mainContext threading conflicts
@ModelActor
actor TaskDataActor {

    // MARK: - CRUD Operations

    /// Creates a new task with the specified properties
    /// - Parameters:
    ///   - title: Task title (required, non-empty)
    ///   - taskDescription: Optional task description
    ///   - priority: Task priority level (default: .medium)
    ///   - dueDate: Optional due date
    ///   - recurrenceRule: Optional recurrence pattern
    /// - Returns: Created Task instance
    /// - Throws: DaisyDosError.validationFailed if title is empty or recurrence rule is invalid
    func createTask(
        title: String,
        taskDescription: String = "",
        priority: Priority = .medium,
        dueDate: Date? = nil,
        recurrenceRule: RecurrenceRule? = nil
    ) throws -> Task {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw DaisyDosError.validationFailed("title")
        }

        // Validate recurrence rule if provided
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

    /// Updates an existing task with new values
    /// - Parameters:
    ///   - task: Task to update
    ///   - title: New title (optional)
    ///   - taskDescription: New description (optional)
    ///   - priority: New priority (optional)
    ///   - dueDate: New due date (optional, pass nil to clear)
    /// - Throws: DaisyDosError.validationFailed if title is empty
    func updateTask(
        _ task: Task,
        title: String? = nil,
        taskDescription: String? = nil,
        priority: Priority? = nil,
        dueDate: Date? = nil
    ) throws {
        var hasChanges = false

        if let title = title {
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw DaisyDosError.validationFailed("title")
            }
            task.title = trimmed
            hasChanges = true
        }

        if let desc = taskDescription {
            task.taskDescription = desc.trimmingCharacters(in: .whitespacesAndNewlines)
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

        if hasChanges {
            task.modifiedDate = Date()
            try modelContext.save()
        }
    }

    /// Deletes a task from the database
    /// - Parameter task: Task to delete
    /// - Throws: SwiftData errors if deletion fails
    func deleteTask(_ task: Task) throws {
        modelContext.delete(task)
        try modelContext.save()
    }

    /// Toggles the completion status of a task
    /// - Parameter task: Task to toggle
    /// - Throws: SwiftData errors if save fails
    func toggleTaskCompletion(_ task: Task) throws {
        task.toggleCompletion()
        try modelContext.save()
    }

    /// Duplicates an existing task
    /// - Parameter task: Task to duplicate
    /// - Returns: New task instance with copied properties
    /// - Throws: SwiftData errors if save fails
    func duplicateTask(_ task: Task) throws -> Task {
        let duplicate = Task(
            title: task.title,
            taskDescription: task.taskDescription,
            priority: task.priority,
            dueDate: task.dueDate != nil && task.dueDate! > Date() ? task.dueDate : nil,
            recurrenceRule: task.recurrenceRule
        )

        // Copy tags
        for tag in task.tags {
            _ = duplicate.addTag(tag)
        }

        modelContext.insert(duplicate)
        try modelContext.save()
        return duplicate
    }

    // MARK: - Query Operations

    /// Fetches all root tasks (tasks without a parent)
    /// - Returns: Array of tasks sorted by creation date (newest first)
    /// - Throws: SwiftData fetch errors
    func fetchAllTasks() throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { $0.parentTask == nil },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches a specific task by ID
    /// - Parameter id: UUID of the task
    /// - Returns: Task if found, nil otherwise
    /// - Throws: SwiftData fetch errors
    func fetchTask(by id: UUID) throws -> Task? {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Returns the total count of all tasks
    /// - Returns: Number of tasks in the database
    /// - Throws: SwiftData fetch errors
    func taskCount() throws -> Int {
        try modelContext.fetchCount(FetchDescriptor<Task>())
    }

    /// Fetches pending (incomplete) tasks
    /// - Returns: Array of incomplete tasks
    /// - Throws: SwiftData fetch errors
    func fetchPendingTasks() throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { $0.isCompleted == false },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches completed tasks
    /// - Returns: Array of completed tasks
    /// - Throws: SwiftData fetch errors
    func fetchCompletedTasks() throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { $0.isCompleted == true && $0.parentTask == nil },
            sortBy: [SortDescriptor(\.createdDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches overdue tasks
    /// - Returns: Array of overdue incomplete tasks
    /// - Throws: SwiftData fetch errors
    func fetchOverdueTasks() throws -> [Task] {
        let now = Date()
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.isCompleted == false &&
                task.dueDate != nil &&
                task.dueDate! < now
            },
            sortBy: [SortDescriptor(\.dueDate, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetches tasks due today
    /// - Returns: Array of tasks due today
    /// - Throws: SwiftData fetch errors
    func fetchTasksDueToday() throws -> [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { task in
                task.isCompleted == false &&
                task.dueDate != nil &&
                task.dueDate! >= today &&
                task.dueDate! < tomorrow
            },
            sortBy: [SortDescriptor(\.dueDate, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Tag Operations

    /// Adds a tag to a task
    /// - Parameters:
    ///   - tag: Tag to add
    ///   - task: Task to add tag to
    /// - Returns: True if tag was added, false if limit reached
    /// - Throws: SwiftData errors if save fails
    @discardableResult
    func addTag(_ tag: Tag, to task: Task) throws -> Bool {
        let success = task.addTag(tag)
        if success {
            try modelContext.save()
        }
        return success
    }

    /// Removes a tag from a task
    /// - Parameters:
    ///   - tag: Tag to remove
    ///   - task: Task to remove tag from
    /// - Throws: SwiftData errors if save fails
    func removeTag(_ tag: Tag, from task: Task) throws {
        task.removeTag(tag)
        try modelContext.save()
    }
}
