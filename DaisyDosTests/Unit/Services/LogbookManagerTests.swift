import Testing
import SwiftData
import Foundation
@testable import DaisyDos

/// LogbookManager service tests - Housekeeping, archival, and retention policy
@Suite("Logbook Manager Tests")
struct LogbookManagerTests {

    // MARK: - Housekeeping Tests

    @Test("Perform housekeeping with no data")
    func testHousekeepingEmpty() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = LogbookManager(modelContext: context)

        let result = manager.performHousekeeping()

        guard case .success(let stats) = result else {
            Issue.record("Housekeeping failed")
            return
        }

        #expect(stats.tasksDeleted == 0)
        #expect(stats.tasksArchived == 0)
        #expect(stats.logsDeleted == 0)
    }

    @Test("Housekeeping deletes old completed tasks (365+ days)")
    func testHousekeepingDeleteOldTasks() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = LogbookManager(modelContext: context)
        let calendar = Calendar.current

        // Create task completed 400 days ago
        let oldDate = calendar.date(byAdding: .day, value: -400, to: Date())!
        let oldTask = Task(title: "Very Old Task")
        oldTask.setCompleted(true)
        oldTask.completedDate = oldDate
        context.insert(oldTask)
        try context.save()

        let result = manager.performHousekeeping()

        guard case .success(let stats) = result else {
            Issue.record("Housekeeping failed")
            return
        }

        #expect(stats.tasksDeleted == 1)

        let descriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(descriptor)
        #expect(tasks.isEmpty)
    }

    @Test("Housekeeping archives tasks (91-364 days)")
    func testHousekeepingArchiveTasks() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = LogbookManager(modelContext: context)
        let calendar = Calendar.current

        // Create task completed 100 days ago
        let archiveDate = calendar.date(byAdding: .day, value: -100, to: Date())!
        let task = Task(title: "Old Task")
        task.setCompleted(true)
        task.completedDate = archiveDate
        context.insert(task)
        try context.save()

        let result = manager.performHousekeeping()

        guard case .success(let stats) = result else {
            Issue.record("Housekeeping failed")
            return
        }

        #expect(stats.tasksArchived == 1)

        // Original task should be deleted
        let taskDescriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(taskDescriptor)
        #expect(tasks.isEmpty)

        // TaskLogEntry should exist
        let logDescriptor = FetchDescriptor<TaskLogEntry>()
        let logEntries = try context.fetch(logDescriptor)
        #expect(logEntries.count == 1)
    }

    @Test("Housekeeping preserves recent tasks (0-90 days)")
    func testHousekeepingPreservesRecentTasks() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = LogbookManager(modelContext: context)
        let calendar = Calendar.current

        // Create recent completed task
        let recentDate = calendar.date(byAdding: .day, value: -30, to: Date())!
        let recentTask = Task(title: "Recent Task")
        recentTask.setCompleted(true)
        recentTask.completedDate = recentDate
        context.insert(recentTask)
        try context.save()

        let result = manager.performHousekeeping()

        guard case .success(let stats) = result else {
            Issue.record("Housekeeping failed")
            return
        }

        #expect(stats.tasksArchived == 0)
        #expect(stats.tasksDeleted == 0)

        let descriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(descriptor)
        #expect(tasks.count == 1)
    }

    @Test("Housekeeping deletes old log entries (365+ days)")
    func testHousekeepingDeleteOldLogEntries() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = LogbookManager(modelContext: context)
        let calendar = Calendar.current

        // Create old log entry
        let oldDate = calendar.date(byAdding: .day, value: -400, to: Date())!
        let logEntry = TaskLogEntry(
            originalTaskId: UUID(),
            title: "Old Entry",
            taskDescription: "",
            completedDate: oldDate,
            createdDate: calendar.date(byAdding: .day, value: -405, to: oldDate)!,
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
        context.insert(logEntry)
        try context.save()

        let result = manager.performHousekeeping()

        guard case .success(let stats) = result else {
            Issue.record("Housekeeping failed")
            return
        }

        #expect(stats.logsDeleted == 1)

        let descriptor = FetchDescriptor<TaskLogEntry>()
        let logEntries = try context.fetch(descriptor)
        #expect(logEntries.isEmpty)
    }

    @Test("Housekeeping mixed scenario")
    func testHousekeepingMixedScenario() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = LogbookManager(modelContext: context)
        let calendar = Calendar.current

        // Recent task (should be preserved)
        let recent = Task(title: "Recent")
        recent.setCompleted(true)
        recent.completedDate = calendar.date(byAdding: .day, value: -30, to: Date())
        context.insert(recent)

        // Archive candidate task (91-364 days)
        let archiveTask = Task(title: "Archive Me")
        archiveTask.setCompleted(true)
        archiveTask.completedDate = calendar.date(byAdding: .day, value: -150, to: Date())
        context.insert(archiveTask)

        // Old task (365+ days, should be deleted)
        let oldTask = Task(title: "Delete Me")
        oldTask.setCompleted(true)
        oldTask.completedDate = calendar.date(byAdding: .day, value: -400, to: Date())
        context.insert(oldTask)

        try context.save()

        let result = manager.performHousekeeping()

        guard case .success(let stats) = result else {
            Issue.record("Housekeeping failed")
            return
        }

        #expect(stats.tasksDeleted == 1)
        #expect(stats.tasksArchived == 1)

        // Should have 1 task (recent) and 1 log entry (archived)
        let taskDescriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(taskDescriptor)
        #expect(tasks.count == 1)

        let logDescriptor = FetchDescriptor<TaskLogEntry>()
        let logEntries = try context.fetch(logDescriptor)
        #expect(logEntries.count == 1)
    }

    // MARK: - Query Tests

    @Test("Recent completions filters correctly")
    func testRecentCompletions() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = LogbookManager(modelContext: context)
        let calendar = Calendar.current

        // Create tasks at different completion dates
        let recent = Task(title: "Recent")
        recent.setCompleted(true)
        recent.completedDate = calendar.date(byAdding: .day, value: -10, to: Date())
        context.insert(recent)

        let old = Task(title: "Old")
        old.setCompleted(true)
        old.completedDate = calendar.date(byAdding: .day, value: -100, to: Date())
        context.insert(old)

        let notCompleted = Task(title: "Not Completed")
        context.insert(notCompleted)

        try context.save()

        let results = manager.recentCompletions(days: 30)

        #expect(results.count == 1)
        #expect(results.first?.title == "Recent")
    }

    @Test("Archived completions filters by date range")
    func testArchivedCompletions() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = LogbookManager(modelContext: context)
        let calendar = Calendar.current

        let startDate = calendar.date(byAdding: .day, value: -200, to: Date())!
        let endDate = calendar.date(byAdding: .day, value: -100, to: Date())!

        // Create log entry within range
        let inRange = TaskLogEntry(
            originalTaskId: UUID(),
            title: "In Range",
            taskDescription: "",
            completedDate: calendar.date(byAdding: .day, value: -150, to: Date())!,
            createdDate: calendar.date(byAdding: .day, value: -160, to: Date())!,
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
        context.insert(inRange)

        // Create log entry outside range
        let outOfRange = TaskLogEntry(
            originalTaskId: UUID(),
            title: "Out of Range",
            taskDescription: "",
            completedDate: calendar.date(byAdding: .day, value: -50, to: Date())!,
            createdDate: calendar.date(byAdding: .day, value: -60, to: Date())!,
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
        context.insert(outOfRange)

        try context.save()

        let results = manager.archivedCompletions(from: startDate, to: endDate)

        #expect(results.count == 1)
        #expect(results.first?.title == "In Range")
    }

    @Test("Search completions by title and description")
    func testSearchCompletions() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = LogbookManager(modelContext: context)
        let calendar = Calendar.current

        let task1 = Task(title: "Buy groceries", taskDescription: "Weekly shopping")
        task1.setCompleted(true)
        task1.completedDate = calendar.date(byAdding: .day, value: -5, to: Date())
        context.insert(task1)

        let task2 = Task(title: "Exercise", taskDescription: "Morning run")
        task2.setCompleted(true)
        task2.completedDate = calendar.date(byAdding: .day, value: -10, to: Date())
        context.insert(task2)

        let task3 = Task(title: "Buy flowers", taskDescription: "For anniversary")
        task3.setCompleted(true)
        task3.completedDate = calendar.date(byAdding: .day, value: -15, to: Date())
        context.insert(task3)

        try context.save()

        let results = manager.searchCompletions(query: "buy", days: 90)

        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.title.localizedStandardContains("Buy") || $0.taskDescription.localizedStandardContains("buy") })
    }
}
