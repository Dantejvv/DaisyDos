import Testing
import Foundation
import SwiftData
@testable import DaisyDos

/// Tests for TaskManager service - CRUD operations, filtering, search, and task management
@Suite("TaskManager Tests")
struct TaskManagerTests {

    // MARK: - CRUD Operations Tests

    @Test("Create task with title only")
    func testCreateTaskSimple() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        let result = manager.createTask(title: "New Task")

        guard case .success(let task) = result else {
            Issue.record("Failed to create task")
            return
        }

        #expect(task.title == "New Task")
        #expect(!task.isCompleted)
    }

    @Test("Create task with full parameters")
    func testCreateTaskFull() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        let dueDate = Date()
        let rule = RecurrenceRule.daily()

        let result = manager.createTask(
            title: "Complex Task",
            taskDescription: "Details",
            priority: .high,
            dueDate: dueDate,
            recurrenceRule: rule
        )

        guard case .success(let task) = result else {
            Issue.record("Failed to create task")
            return
        }

        #expect(task.title == "Complex Task")
        #expect(task.taskDescription == "Details")
        #expect(task.priority == .high)
        #expect(task.dueDate == dueDate)
        #expect(task.recurrenceRule != nil)
    }

    @Test("Update task title")
    func testUpdateTaskTitle() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        guard case .success(let task) = manager.createTask(title: "Original") else {
            Issue.record("Failed to create task")
            return
        }

        let result = manager.updateTask(task, title: "Updated")

        guard case .success = result else {
            Issue.record("Failed to update task")
            return
        }

        #expect(task.title == "Updated")
    }

    @Test("Toggle task completion")
    func testToggleCompletion() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        guard case .success(let task) = manager.createTask(title: "Test") else {
            Issue.record("Failed to create task")
            return
        }

        // Initially incomplete
        #expect(!task.isCompleted)

        // Toggle to complete
        let result1 = manager.toggleTaskCompletion(task)
        guard case .success = result1 else {
            Issue.record("Failed to toggle completion")
            return
        }
        #expect(task.isCompleted)

        // Toggle back
        let result2 = manager.toggleTaskCompletion(task)
        guard case .success = result2 else {
            Issue.record("Failed to toggle completion back")
            return
        }
        #expect(!task.isCompleted)
    }

    @Test("Delete task")
    func testDeleteTask() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        guard case .success(let task) = manager.createTask(title: "To Delete") else {
            Issue.record("Failed to create task")
            return
        }

        let initialCount = manager.taskCount
        let result = manager.deleteTask(task)

        guard case .success = result else {
            Issue.record("Failed to delete task")
            return
        }

        #expect(manager.taskCount == initialCount - 1)
    }

    @Test("Delete multiple tasks")
    func testDeleteMultipleTasks() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        // Create 3 tasks
        guard case .success(let task1) = manager.createTask(title: "Task 1"),
              case .success(let task2) = manager.createTask(title: "Task 2"),
              case .success(let task3) = manager.createTask(title: "Task 3") else {
            Issue.record("Failed to create tasks")
            return
        }

        let initialCount = manager.taskCount
        let result = manager.deleteTasks([task1, task2, task3])

        guard case .success = result else {
            Issue.record("Failed to delete tasks")
            return
        }

        #expect(manager.taskCount == initialCount - 3)
    }

    // MARK: - Tag Management Tests

    @Test("Add tag to task")
    func testAddTag() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        guard case .success(let task) = manager.createTask(title: "Test") else {
            Issue.record("Failed to create task")
            return
        }

        let tag = Tag(name: "Important", sfSymbolName: "star", colorName: "yellow")
        context.insert(tag)

        let result = manager.addTag(tag, to: task)

        guard case .success = result else {
            Issue.record("Failed to add tag")
            return
        }

        #expect((task.tags ?? []).contains(tag))
    }

    @Test("Remove tag from task")
    func testRemoveTag() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        guard case .success(let task) = manager.createTask(title: "Test") else {
            Issue.record("Failed to create task")
            return
        }

        let tag = Tag(name: "Important", sfSymbolName: "star", colorName: "yellow")
        context.insert(tag)

        _ = manager.addTag(tag, to: task)
        #expect((task.tags ?? []).contains(tag))

        let result = manager.removeTag(tag, from: task)

        guard case .success = result else {
            Issue.record("Failed to remove tag")
            return
        }

        #expect(!(task.tags ?? []).contains(tag))
    }

    @Test("Enforce 5-tag limit")
    func testTagLimitEnforcement() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        guard case .success(let task) = manager.createTask(title: "Test") else {
            Issue.record("Failed to create task")
            return
        }

        // Add 5 tags
        let tag1 = Tag(name: "Tag1", sfSymbolName: "star", colorName: "blue")
        let tag2 = Tag(name: "Tag2", sfSymbolName: "heart", colorName: "red")
        let tag3 = Tag(name: "Tag3", sfSymbolName: "leaf", colorName: "green")
        let tag4 = Tag(name: "Tag4", sfSymbolName: "sun.max", colorName: "yellow")
        let tag5 = Tag(name: "Tag5", sfSymbolName: "moon", colorName: "purple")
        context.insert(tag1)
        context.insert(tag2)
        context.insert(tag3)
        context.insert(tag4)
        context.insert(tag5)

        _ = manager.addTag(tag1, to: task)
        _ = manager.addTag(tag2, to: task)
        _ = manager.addTag(tag3, to: task)
        _ = manager.addTag(tag4, to: task)
        _ = manager.addTag(tag5, to: task)

        #expect((task.tags ?? []).count == 5)

        // Try to add 6th tag
        let tag6 = Tag(name: "Tag6", sfSymbolName: "cloud", colorName: "gray")
        context.insert(tag6)

        let result = manager.addTag(tag6, to: task)

        // Should fail - verify it's a failure
        if case .failure = result {
            // Expected failure
        } else {
            Issue.record("Should have failed to add 6th tag")
        }

        #expect((task.tags ?? []).count == 5)
    }

    // MARK: - Search and Filter Tests

    @Test("Search tasks by title")
    func testSearchTasksByTitle() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        _ = manager.createTask(title: "Buy groceries")
        _ = manager.createTask(title: "Buy flowers")
        _ = manager.createTask(title: "Write code")

        let result = manager.searchTasks(query: "buy")

        guard case .success(let tasks) = result else {
            Issue.record("Failed to search tasks")
            return
        }

        #expect(tasks.count == 2)
        #expect(tasks.allSatisfy { $0.title.localizedStandardContains("buy") })
    }

    // MARK: - Subtask Management Tests

    @Test("Create subtask")
    func testCreateSubtask() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        guard case .success(let parent) = manager.createTask(title: "Parent") else {
            Issue.record("Failed to create parent")
            return
        }

        let result = manager.createSubtask(
            for: parent,
            title: "Subtask"
        )

        guard case .success(let subtask) = result else {
            Issue.record("Failed to create subtask")
            return
        }

        #expect(subtask.title == "Subtask")
        #expect((parent.subtasks ?? []).contains(subtask))
        #expect(subtask.parentTask == parent)
    }

    // MARK: - Task Duplication Tests

    @Test("Duplicate task creates new instance")
    func testDuplicateTask() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        guard case .success(let original) = manager.createTask(
            title: "Original Task",
            taskDescription: "Original description",
            priority: .high
        ) else {
            Issue.record("Failed to create original task")
            return
        }

        let result = manager.duplicateTask(original)

        guard case .success(let duplicate) = result else {
            Issue.record("Failed to duplicate task")
            return
        }

        #expect(duplicate.id != original.id)
        #expect(duplicate.title == "Original Task (Copy)") // Adds (Copy) suffix
        #expect(duplicate.taskDescription == original.taskDescription)
        #expect(duplicate.priority == original.priority)
        #expect(!duplicate.isCompleted) // Duplicates start incomplete
    }

    // MARK: - Computed Properties Tests

    @Test("Task count is accurate")
    func testTaskCount() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        #expect(manager.taskCount == 0)

        _ = manager.createTask(title: "Task 1")
        #expect(manager.taskCount == 1)

        _ = manager.createTask(title: "Task 2")
        #expect(manager.taskCount == 2)
    }

    @Test("Completed and pending task counts")
    func testCompletionCounts() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        guard case .success(let task1) = manager.createTask(title: "Task 1"),
              case .success(let task2) = manager.createTask(title: "Task 2"),
              case .success(let task3) = manager.createTask(title: "Task 3") else {
            Issue.record("Failed to create tasks")
            return
        }

        #expect(manager.completedTaskCount == 0)
        #expect(manager.pendingTaskCount == 3)

        task1.setCompleted(true)
        task2.setCompleted(true)

        #expect(manager.completedTaskCount == 2)
        #expect(manager.pendingTaskCount == 1)
    }

    @Test("Completion rate calculates correctly")
    func testCompletionRate() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        // No tasks = 0% completion
        #expect(manager.completionRate == 0.0)

        guard case .success(let task1) = manager.createTask(title: "Task 1"),
              case .success(let task2) = manager.createTask(title: "Task 2") else {
            Issue.record("Failed to create tasks")
            return
        }

        // 0 of 2 complete = 0%
        #expect(manager.completionRate == 0.0)

        task1.setCompleted(true)
        // 1 of 2 complete = 50%
        #expect(manager.completionRate == 0.5)

        task2.setCompleted(true)
        // 2 of 2 complete = 100%
        #expect(manager.completionRate == 1.0)
    }

    // MARK: - Safe API Tests

    @Test("Safe API returns nil on failure")
    func testSafeAPIFailure() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        // Create task safely with empty title should return nil
        let task = manager.createTaskSafely(title: "")

        #expect(task == nil)
    }

    @Test("Safe API returns value on success")
    func testSafeAPISuccess() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        let task = manager.createTaskSafely(title: "Valid Task")

        #expect(task != nil)
        #expect(task?.title == "Valid Task")
    }
}
