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
        #expect(!logEntry.wasSubtask)
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

    @Test("Log entry captures subtask relationships")
    func testLogEntrySubtaskRelationships() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let parent = Task(title: "Parent Task")
        let subtask = Task(title: "Subtask")
        parent.subtasks = [subtask]

        subtask.setCompleted(true)
        context.insert(parent)
        context.insert(subtask)
        try context.save()

        let logEntry = TaskLogEntry(from: subtask)

        #expect(logEntry.wasSubtask)
        #expect(logEntry.parentTaskTitle == "Parent Task")
    }

    @Test("Log entry captures subtask counts")
    func testLogEntrySubtaskCounts() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let parent = Task(title: "Parent")
        let subtask1 = Task(title: "Subtask 1")
        let subtask2 = Task(title: "Subtask 2")
        let subtask3 = Task(title: "Subtask 3")

        parent.subtasks = [subtask1, subtask2, subtask3]

        subtask1.setCompleted(true)
        subtask2.setCompleted(true)
        // Note: Completing parent completes all subtasks
        parent.setCompleted(true)

        context.insert(parent)
        try context.save()

        let logEntry = TaskLogEntry(from: parent)

        #expect(logEntry.subtaskCount == 3)
        // After parent completion, all subtasks are completed
        #expect(logEntry.completedSubtaskCount == 3)
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

    @Test("Completion duration formatted")
    func testCompletionDurationFormatted() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        // Task with no duration
        let logEntry1 = TaskLogEntry(
            originalTaskId: UUID(),
            title: "No Duration",
            taskDescription: "",
            completedDate: Date(),
            createdDate: Date(),
            dueDate: nil,
            priority: .medium,
            wasOverdue: false,
            subtaskCount: 0,
            completedSubtaskCount: 0,
            wasSubtask: false,
            parentTaskTitle: nil,
            tagNames: [],
            completionDuration: nil
        )

        // Task with duration
        let logEntry2 = TaskLogEntry(
            originalTaskId: UUID(),
            title: "With Duration",
            taskDescription: "",
            completedDate: Date(),
            createdDate: Date(),
            dueDate: nil,
            priority: .medium,
            wasOverdue: false,
            subtaskCount: 0,
            completedSubtaskCount: 0,
            wasSubtask: false,
            parentTaskTitle: nil,
            tagNames: [],
            completionDuration: 3661 // 1 hour, 1 minute, 1 second
        )

        context.insert(logEntry1)
        context.insert(logEntry2)
        try context.save()

        #expect(logEntry1.completionDurationFormatted == "N/A")
        #expect(logEntry2.completionDurationFormatted.contains("1h") || logEntry2.completionDurationFormatted.contains("hour"))
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
