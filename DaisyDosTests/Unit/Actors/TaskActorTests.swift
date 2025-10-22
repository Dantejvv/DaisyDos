//
//  TaskActorTests.swift
//  DaisyDosTests
//
//  Created by Claude Code on 10/21/25.
//  Phase 1: Proof of concept for ModelActor pattern with parallel test execution
//

import Testing
import SwiftData
import Foundation
@testable import DaisyDos

/// Test suite validating TaskDataActor provides thread-safe, isolated data operations
/// Pattern: Struct + Local Container for perfect test isolation
@Suite("Task Data Actor - CRUD Operations", .serialized)
struct TaskActorTests {

    // MARK: - Create Operations

    @Test("Create task with actor isolation")
    func createTaskWithActor() async throws {
        // Given - Create isolated container
        let container = try TestHelpers.createActorTestContainer()
        let actor = TaskDataActor(modelContainer: container)

        // When - Actor operations are naturally async
        let task = try await actor.createTask(
            title: "Test Task",
            taskDescription: "Test Description",
            priority: .high
        )

        // Then - Verify in isolation
        #expect(task.title == "Test Task")
        #expect(task.taskDescription == "Test Description")
        #expect(task.priority == .high)
        #expect(!task.isCompleted)

        let count = try await actor.taskCount()
        #expect(count == 1)
    }

    @Test("Create task with due date through actor")
    func createTaskWithDueDate() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let actor = TaskDataActor(modelContainer: container)

        let dueDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!

        let task = try await actor.createTask(
            title: "Task with due date",
            dueDate: dueDate
        )

        #expect(task.dueDate != nil)
        #expect(task.dueDate == dueDate)
    }

    @Test("Create task validation - empty title throws error")
    func createTaskValidation() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let actor = TaskDataActor(modelContainer: container)

        // Verify empty title is rejected
        do {
            _ = try await actor.createTask(title: "")
            #expect(Bool(false), "Should throw validation error for empty title")
        } catch let error as DaisyDosError {
            // Expected error
            #expect(error == .validationFailed("title"))
        }
    }

    // MARK: - Update Operations

    @Test("Update task through actor")
    func updateTaskWithActor() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let actor = TaskDataActor(modelContainer: container)

        // Create task
        let task = try await actor.createTask(title: "Original Title")
        #expect(task.title == "Original Title")

        // Update through actor
        try await actor.updateTask(
            task,
            title: "Updated Title",
            priority: .low
        )

        // Fetch fresh to verify
        let fetched = try await actor.fetchTask(by: task.id)
        #expect(fetched?.title == "Updated Title")
        #expect(fetched?.priority == .low)
    }

    @Test("Update task with due date")
    func updateTaskDueDate() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let actor = TaskDataActor(modelContainer: container)

        let task = try await actor.createTask(title: "Task")
        #expect(task.dueDate == nil)

        let newDueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        try await actor.updateTask(task, dueDate: newDueDate)

        let fetched = try await actor.fetchTask(by: task.id)
        #expect(fetched?.dueDate == newDueDate)
    }

    // MARK: - Delete Operations

    @Test("Delete task through actor")
    func deleteTaskWithActor() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let actor = TaskDataActor(modelContainer: container)

        let task = try await actor.createTask(title: "To Delete")
        #expect(try await actor.taskCount() == 1)

        try await actor.deleteTask(task)
        #expect(try await actor.taskCount() == 0)

        let fetched = try await actor.fetchTask(by: task.id)
        #expect(fetched == nil)
    }

    // MARK: - Completion Operations

    @Test("Toggle task completion through actor")
    func toggleCompletion() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let actor = TaskDataActor(modelContainer: container)

        let task = try await actor.createTask(title: "Task to complete")
        #expect(!task.isCompleted)

        try await actor.toggleTaskCompletion(task)
        #expect(task.isCompleted)

        try await actor.toggleTaskCompletion(task)
        #expect(!task.isCompleted)
    }

    // MARK: - Query Operations

    @Test("Fetch all tasks through actor")
    func fetchAllTasks() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let actor = TaskDataActor(modelContainer: container)

        // Create multiple tasks
        _ = try await actor.createTask(title: "Task 1")
        _ = try await actor.createTask(title: "Task 2")
        _ = try await actor.createTask(title: "Task 3")

        let tasks = try await actor.fetchAllTasks()
        #expect(tasks.count == 3)
    }

    @Test("Fetch pending tasks through actor")
    func fetchPendingTasks() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let actor = TaskDataActor(modelContainer: container)

        let task1 = try await actor.createTask(title: "Pending 1")
        let task2 = try await actor.createTask(title: "Pending 2")
        let task3 = try await actor.createTask(title: "To Complete")

        // Complete one task
        try await actor.toggleTaskCompletion(task3)

        let pending = try await actor.fetchPendingTasks()
        #expect(pending.count == 2)
        #expect(pending.contains { $0.id == task1.id })
        #expect(pending.contains { $0.id == task2.id })
    }

    @Test("Fetch overdue tasks through actor")
    func fetchOverdueTasks() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let actor = TaskDataActor(modelContainer: container)

        let pastDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
        let futureDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!

        let overdueTask = try await actor.createTask(title: "Overdue", dueDate: pastDate)
        _ = try await actor.createTask(title: "Future", dueDate: futureDate)
        _ = try await actor.createTask(title: "No date")

        let overdue = try await actor.fetchOverdueTasks()
        #expect(overdue.count == 1)
        #expect(overdue.first?.id == overdueTask.id)
    }

    // MARK: - Parallel Execution Test (The Key Innovation!)

    @Test("Parallel task creation is thread-safe")
    func parallelTaskCreation() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let actor = TaskDataActor(modelContainer: container)

        // Create 10 tasks in parallel - this would CRASH without actor isolation!
        try await withThrowingTaskGroup(of: Task.self) { group in
            for i in 1...10 {
                group.addTask {
                    try await actor.createTask(title: "Task \(i)")
                }
            }

            // Wait for all to complete
            var tasks: [Task] = []
            for try await task in group {
                tasks.append(task)
            }

            #expect(tasks.count == 10)
        }

        let finalCount = try await actor.taskCount()
        #expect(finalCount == 10)
    }

    @Test("Duplicate task through actor")
    func duplicateTask() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let actor = TaskDataActor(modelContainer: container)

        let futureDueDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let original = try await actor.createTask(
            title: "Original Task",
            taskDescription: "Description",
            priority: .high,
            dueDate: futureDueDate
        )

        let duplicate = try await actor.duplicateTask(original)

        #expect(duplicate.id != original.id)
        #expect(duplicate.title == original.title)
        #expect(duplicate.taskDescription == original.taskDescription)
        #expect(duplicate.priority == original.priority)
        #expect(duplicate.dueDate == original.dueDate)
        #expect(!duplicate.isCompleted)

        let count = try await actor.taskCount()
        #expect(count == 2)
    }
}
