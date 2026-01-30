import Testing
import Foundation
import SwiftData
@testable import DaisyDos

/// Comprehensive tests for Task model
/// Tests cover task completion, subtask management, tags, due dates, and recurrence
@Suite("Task Model Tests")
struct TaskModelTests {

    // MARK: - Initialization Tests

    @Test("Task initializes with correct defaults")
    func testInitialization() {
        let task = Task(title: "Test Task")

        #expect(task.title == "Test Task")
        #expect(task.isCompleted == false)
        #expect(task.completedDate == nil)
        #expect((task.subtasks ?? []).isEmpty)
        #expect(task.priority == .none)
        #expect(task.dueDate == nil)
    }

    @Test("Task initializes with full parameters")
    func testFullInitialization() {
        let dueDate = Date()
        let rule = RecurrenceRule.daily()

        let task = Task(
            title: "Complex Task",
            taskDescription: "Details here",
            priority: .high,
            dueDate: dueDate,
            recurrenceRule: rule
        )

        #expect(task.title == "Complex Task")
        #expect(task.taskDescription == "Details here")
        #expect(task.priority == .high)
        #expect(task.dueDate == dueDate)
        #expect(task.recurrenceRule != nil)
    }

    // MARK: - Completion Tests

    @Test("Toggle completion works correctly")
    func testToggleCompletion() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let task = Task(title: "Test")
        context.insert(task)

        // Initially incomplete
        #expect(!task.isCompleted)

        // Toggle to complete
        task.toggleCompletion()
        #expect(task.isCompleted)
        #expect(task.completedDate != nil)

        // Toggle back to incomplete
        task.toggleCompletion()
        #expect(!task.isCompleted)
        #expect(task.completedDate == nil)
    }

    @Test("Completing already completed task does nothing")
    func testCompleteAlreadyCompleted() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let task = Task(title: "Test")
        context.insert(task)

        // Complete task
        task.setCompleted(true)
        let firstCompletionDate = task.completedDate

        // Try to complete again
        task.setCompleted(true)

        // Should still be completed with same date
        #expect(task.isCompleted)
        #expect(task.completedDate == firstCompletionDate)
    }

    // MARK: - Subtask Tests

    @Test("Task can have multiple subtasks")
    func testMultipleSubtasks() async throws {
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

        #expect((task.subtasks ?? []).count == 3)
        #expect(task.subtaskCount == 3)
    }

    @Test("Subtask has correct parent reference")
    func testSubtaskParentReference() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let task = Task(title: "Parent Task")
        context.insert(task)

        let subtask = Subtask(title: "Subtask")
        context.insert(subtask)
        _ = task.addSubtask(subtask)

        #expect(subtask.parentTask?.id == task.id)
    }

    @Test("Subtask completion is independent of task completion")
    func testSubtaskIndependentCompletion() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let task = Task(title: "Parent Task")
        context.insert(task)

        let subtask1 = Subtask(title: "Subtask 1")
        let subtask2 = Subtask(title: "Subtask 2")
        context.insert(subtask1)
        context.insert(subtask2)
        _ = task.addSubtask(subtask1)
        _ = task.addSubtask(subtask2)

        // Complete subtasks independently
        subtask1.setCompleted(true)

        // Parent task is not affected
        #expect(!task.isCompleted)
        #expect(subtask1.isCompleted)
        #expect(!subtask2.isCompleted)

        // Task completion doesn't cascade to subtasks
        task.setCompleted(true)
        #expect(task.isCompleted)
        // Subtasks retain their individual completion states
        #expect(subtask1.isCompleted)
        #expect(!subtask2.isCompleted)
    }

    @Test("completedSubtaskCount calculates correctly")
    func testCompletedSubtaskCount() async throws {
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

        #expect(task.completedSubtaskCount == 0)

        subtask1.setCompleted(true)
        #expect(task.completedSubtaskCount == 1)

        subtask2.setCompleted(true)
        #expect(task.completedSubtaskCount == 2)

        subtask3.setCompleted(true)
        #expect(task.completedSubtaskCount == 3)
    }

    @Test("hasSubtasks property works correctly")
    func testHasSubtasks() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let task = Task(title: "Parent Task")
        context.insert(task)

        #expect(!task.hasSubtasks)

        let subtask = Subtask(title: "Subtask")
        context.insert(subtask)
        _ = task.addSubtask(subtask)

        #expect(task.hasSubtasks)
    }

    @Test("Subtask ordering works correctly")
    func testSubtaskOrdering() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let task = Task(title: "Parent Task")
        context.insert(task)

        let subtask1 = Subtask(title: "First")
        let subtask2 = Subtask(title: "Second")
        let subtask3 = Subtask(title: "Third")

        context.insert(subtask1)
        context.insert(subtask2)
        context.insert(subtask3)

        _ = task.addSubtask(subtask1)
        _ = task.addSubtask(subtask2)
        _ = task.addSubtask(subtask3)

        let ordered = task.orderedSubtasks
        #expect(ordered.count == 3)
        #expect(ordered[0].subtaskOrder < ordered[1].subtaskOrder)
        #expect(ordered[1].subtaskOrder < ordered[2].subtaskOrder)
    }

    // MARK: - Tag Management Tests

    @Test("Task enforces 5-tag limit")
    func testTagLimit() {
        let task = Task(title: "Test")

        #expect(task.canAddTag())

        let tag1 = Tag(name: "Tag1", sfSymbolName: "star", colorName: "blue")
        let tag2 = Tag(name: "Tag2", sfSymbolName: "heart", colorName: "red")
        let tag3 = Tag(name: "Tag3", sfSymbolName: "leaf", colorName: "green")
        let tag4 = Tag(name: "Tag4", sfSymbolName: "sun.max", colorName: "yellow")
        let tag5 = Tag(name: "Tag5", sfSymbolName: "moon", colorName: "purple")

        _ = task.addTag(tag1)
        _ = task.addTag(tag2)
        _ = task.addTag(tag3)
        _ = task.addTag(tag4)
        _ = task.addTag(tag5)

        #expect((task.tags ?? []).count == 5)
        #expect(!task.canAddTag())

        let tag6 = Tag(name: "Tag6", sfSymbolName: "cloud", colorName: "gray")
        let added = task.addTag(tag6)

        #expect(added == false)
        #expect((task.tags ?? []).count == 5)
    }

    @Test("Task prevents duplicate tags")
    func testDuplicateTags() {
        let task = Task(title: "Test")
        let tag = Tag(name: "Tag1", sfSymbolName: "star", colorName: "blue")

        let added1 = task.addTag(tag)
        #expect(added1 == true)
        #expect((task.tags ?? []).count == 1)

        let added2 = task.addTag(tag)
        #expect(added2 == false)
        #expect((task.tags ?? []).count == 1)
    }

    // MARK: - Due Date Tests

    @Test("isDueToday detects task due today")
    func testIsDueToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let task = Task(title: "Test", dueDate: today)
        #expect(task.isDueToday)

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        task.dueDate = tomorrow
        #expect(!task.isDueToday)
    }

    @Test("isDueSoon detects task due within 7 days")
    func testIsDueSoon() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Due in 3 days
        let threeDays = calendar.date(byAdding: .day, value: 3, to: today)!
        let task = Task(title: "Test", dueDate: threeDays)
        #expect(task.isDueSoon)

        // Due in 10 days
        let tenDays = calendar.date(byAdding: .day, value: 10, to: today)!
        task.dueDate = tenDays
        #expect(!task.isDueSoon)
    }

    @Test("hasOverdueStatus detects overdue tasks")
    func testHasOverdueStatus() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!

        let task = Task(title: "Test", dueDate: yesterday)
        #expect(task.hasOverdueStatus)

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        task.dueDate = tomorrow
        #expect(!task.hasOverdueStatus)

        // Completed tasks are not overdue
        task.dueDate = yesterday
        task.setCompleted(true)
        #expect(!task.hasOverdueStatus)
    }

    // MARK: - Priority Tests

    @Test("Task priority is settable", arguments: [Priority.none, Priority.low, Priority.medium, Priority.high])
    func testPriority(priority: Priority) {
        let task = Task(title: "Test", priority: priority)
        #expect(task.priority == priority)
    }

    // MARK: - Recurrence Tests

    @Test("Task with recurrence rule stores correctly")
    func testRecurrenceRule() {
        let rule = RecurrenceRule.daily(interval: 2)
        let task = Task(title: "Test", recurrenceRule: rule)

        #expect(task.recurrenceRule != nil)
        #expect(task.recurrenceRule?.frequency == .daily)
        #expect(task.recurrenceRule?.interval == 2)
    }

    // MARK: - Completion Date Tests

    @Test("Completion date is set when completing")
    func testCompletionDateSet() {
        let task = Task(title: "Test")

        #expect(task.completedDate == nil)

        task.setCompleted(true)

        #expect(task.completedDate != nil)
        #expect(task.isCompleted)
    }

    @Test("Completion date is cleared when uncompleting")
    func testCompletionDateCleared() {
        let task = Task(title: "Test")

        task.setCompleted(true)
        #expect(task.completedDate != nil)

        task.setCompleted(false)
        #expect(task.completedDate == nil)
    }

    // MARK: - Edge Case Tests

    @Test("Empty subtask list doesn't break completion")
    func testEmptySubtaskCompletion() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let task = Task(title: "Test")
        context.insert(task)

        // Should work fine with no subtasks
        task.setCompleted(true)
        #expect(task.isCompleted)

        task.setCompleted(false)
        #expect(!task.isCompleted)
    }
}
