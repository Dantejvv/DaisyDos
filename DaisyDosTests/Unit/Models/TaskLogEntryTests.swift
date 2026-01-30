import Testing
import SwiftData
import Foundation
@testable import DaisyDos

/// TaskLogEntry model tests - Snapshot creation and archival logic
@Suite("Task Log Entry Tests")
struct TaskLogEntryTests {

    // MARK: - Initialization Tests

    @Test("Create log entry from completed task")
    func testCreateFromTask() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let task = Task(
            title: "Test Task",
            taskDescription: "Test Description",
            priority: .high
        )
        task.setCompleted(true)
        context.insert(task)
        try context.save()

        let logEntry = TaskLogEntry(from: task)

        #expect(logEntry.originalTaskId == task.id)
        #expect(logEntry.title == "Test Task")
        #expect(logEntry.taskDescription == "Test Description")
        #expect(logEntry.priority == .high)
        #expect(logEntry.completedDate != nil)
        #expect(!logEntry.wasOverdue)
    }

    @Test("Log entry captures overdue status")
    func testLogEntryOverdueStatus() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let calendar = Calendar.current

        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        let task = Task(title: "Overdue Task")
        task.dueDate = yesterday
        task.setCompleted(true)
        context.insert(task)
        try context.save()

        let logEntry = TaskLogEntry(from: task)

        #expect(logEntry.wasOverdue)
        #expect(logEntry.dueDate == yesterday)
    }

    @Test("Log entry captures subtask counts")
    func testLogEntrySubtaskCounts() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let task = Task(title: "Parent Task")
        context.insert(task)

        let subtask1 = Subtask(title: "Subtask 1")
        let subtask2 = Subtask(title: "Subtask 2")
        let subtask3 = Subtask(title: "Subtask 3")

        context.insert(subtask1)
        context.insert(subtask2)
        context.insert(subtask3)

        _ = task.addSubtask(subtask1)
        _ = task.addSubtask(subtask2)
        _ = task.addSubtask(subtask3)

        // Complete some subtasks
        subtask1.setCompleted(true)
        subtask2.setCompleted(true)

        // Complete the task
        task.setCompleted(true)
        try context.save()

        let logEntry = TaskLogEntry(from: task)

        #expect(logEntry.subtaskCount == 3)
        #expect(logEntry.completedSubtaskCount == 2)
    }

    @Test("Log entry captures tag names")
    func testLogEntryTagNames() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let task = Task(title: "Task with Tags")
        let tag1 = Tag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")
        let tag2 = Tag(name: "Urgent", sfSymbolName: "exclamationmark", colorName: "red")

        context.insert(tag1)
        context.insert(tag2)
        _ = task.addTag(tag1)
        _ = task.addTag(tag2)

        task.setCompleted(true)
        context.insert(task)
        try context.save()

        let logEntry = TaskLogEntry(from: task)

        #expect(logEntry.tagNames.count == 2)
        #expect(logEntry.tagNames.contains("Work"))
        #expect(logEntry.tagNames.contains("Urgent"))
    }

    @Test("Log entry calculates completion duration")
    func testLogEntryCompletionDuration() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let calendar = Calendar.current

        let creationDate = calendar.date(byAdding: .hour, value: -5, to: Date())!

        let task = Task(title: "Timed Task")
        task.createdDate = creationDate
        task.setCompleted(true)
        context.insert(task)
        try context.save()

        let logEntry = TaskLogEntry(from: task)

        #expect(logEntry.completionDuration != nil)
        // Duration should be approximately 5 hours (18000 seconds), with some tolerance
        if let duration = logEntry.completionDuration {
            #expect(duration > 17900) // ~5 hours minus tolerance
            #expect(duration < 18100) // ~5 hours plus tolerance
        }
    }

    // MARK: - Display Helper Tests

    @Test("Display title shows title or Untitled")
    func testDisplayTitle() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let task1 = Task(title: "My Task")
        task1.setCompleted(true)
        context.insert(task1)

        let task2 = Task(title: "")
        task2.setCompleted(true)
        context.insert(task2)

        try context.save()

        let logEntry1 = TaskLogEntry(from: task1)
        let logEntry2 = TaskLogEntry(from: task2)

        #expect(logEntry1.displayTitle == "My Task")
        #expect(logEntry2.displayTitle == "Untitled Task")
    }

    @Test("Log entry persists correctly")
    func testLogEntryPersistence() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let task = Task(title: "Persist Me")
        task.setCompleted(true)
        context.insert(task)
        try context.save()

        let logEntry = TaskLogEntry(from: task)
        context.insert(logEntry)
        try context.save()

        // Fetch and verify
        let descriptor = FetchDescriptor<TaskLogEntry>()
        let fetchedEntries = try context.fetch(descriptor)

        #expect(fetchedEntries.count == 1)
        #expect(fetchedEntries.first?.title == "Persist Me")
        #expect(fetchedEntries.first?.originalTaskId == task.id)
    }
}
