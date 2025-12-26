import Testing
import Foundation
import SwiftData
@testable import DaisyDos

/// Comprehensive tests for Task model - Focus on completion propagation and subtask relationships
/// Tests cover complex cascade logic for parent-child task relationships
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
        #expect(task.parentTask == nil)
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

    // MARK: - Completion Propagation Tests

    @Test("Completing parent completes all subtasks")
    func testCompleteParentCompletesSubtasks() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let parent = Task(title: "Parent")
        let subtask1 = Task(title: "Subtask 1")
        let subtask2 = Task(title: "Subtask 2")

        parent.subtasks = (parent.subtasks ?? []) + [subtask1]
        parent.subtasks = (parent.subtasks ?? []) + [subtask2]

        context.insert(parent)

        // Complete parent
        parent.setCompleted(true)

        // Verify all subtasks are completed
        #expect(parent.isCompleted)
        #expect(subtask1.isCompleted)
        #expect(subtask2.isCompleted)
    }

    @Test("Completing parent inherits completion date to subtasks")
    func testCompleteParentInheritsCompletionDate() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let parent = Task(title: "Parent")
        let subtask = Task(title: "Subtask")

        parent.subtasks = (parent.subtasks ?? []) + [subtask]
        context.insert(parent)

        // Complete parent
        parent.setCompleted(true)

        // Verify subtask inherits parent's completion date
        #expect(subtask.completedDate == parent.completedDate)
    }

    @Test("Uncompleting parent uncompletes all subtasks")
    func testUncompleteParentUncompletesSubtasks() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let parent = Task(title: "Parent")
        let subtask1 = Task(title: "Subtask 1")
        let subtask2 = Task(title: "Subtask 2")

        parent.subtasks = (parent.subtasks ?? []) + [subtask1]
        parent.subtasks = (parent.subtasks ?? []) + [subtask2]

        context.insert(parent)

        // Complete parent (which completes subtasks)
        parent.setCompleted(true)
        #expect(subtask1.isCompleted)
        #expect(subtask2.isCompleted)

        // Uncomplete parent
        parent.setCompleted(false)

        // Verify all subtasks are uncompleted
        #expect(!parent.isCompleted)
        #expect(!subtask1.isCompleted)
        #expect(!subtask2.isCompleted)
    }

    @Test("Uncompleting subtask uncompletes parent")
    func testUncompleteSubtaskUncompletesParent() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let parent = Task(title: "Parent")
        let subtask1 = Task(title: "Subtask 1")

        parent.subtasks = (parent.subtasks ?? []) + [subtask1]

        context.insert(parent)

        // Complete parent
        parent.setCompleted(true)
        #expect(parent.isCompleted)
        #expect(subtask1.isCompleted)

        // Uncomplete subtask
        subtask1.setCompleted(false)

        // Parent should be uncompleted (propagates up)
        #expect(!parent.isCompleted)
        #expect(!subtask1.isCompleted)
    }

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

    // MARK: - Subtask Relationship Tests

    @Test("Task can have multiple subtasks")
    func testMultipleSubtasks() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let parent = Task(title: "Parent")
        let subtask1 = Task(title: "Subtask 1")
        let subtask2 = Task(title: "Subtask 2")
        let subtask3 = Task(title: "Subtask 3")

        parent.subtasks = (parent.subtasks ?? []) + [subtask1]
        parent.subtasks = (parent.subtasks ?? []) + [subtask2]
        parent.subtasks = (parent.subtasks ?? []) + [subtask3]

        context.insert(parent)

        #expect((parent.subtasks ?? []).count == 3)
        #expect(parent.subtaskCount == 3)
    }

    @Test("Subtask has correct parent reference")
    func testSubtaskParentReference() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let parent = Task(title: "Parent")
        let subtask = Task(title: "Subtask")

        parent.subtasks = (parent.subtasks ?? []) + [subtask]
        context.insert(parent)

        #expect(subtask.parentTask == parent)
        #expect(parent.parentTask == nil)
    }

    @Test("Task with mixed completion states")
    func testMixedCompletionStates() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let parent = Task(title: "Parent")
        let subtask1 = Task(title: "Subtask 1")
        let subtask2 = Task(title: "Subtask 2")
        let subtask3 = Task(title: "Subtask 3")

        parent.subtasks = (parent.subtasks ?? []) + [subtask1]
        parent.subtasks = (parent.subtasks ?? []) + [subtask2]
        parent.subtasks = (parent.subtasks ?? []) + [subtask3]

        context.insert(parent)

        // Complete some subtasks manually
        subtask1.setCompleted(true)
        subtask2.setCompleted(true)

        // Parent not complete, mixed subtask states
        #expect(!parent.isCompleted)
        #expect(subtask1.isCompleted)
        #expect(subtask2.isCompleted)
        #expect(!subtask3.isCompleted)

        #expect(parent.completedSubtaskCount == 2)
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

    // MARK: - Subtask Progress Tests

    @Test("completedSubtaskCount calculates correctly")
    func testCompletedSubtaskCount() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let parent = Task(title: "Parent")
        let subtask1 = Task(title: "Subtask 1")
        let subtask2 = Task(title: "Subtask 2")
        let subtask3 = Task(title: "Subtask 3")

        parent.subtasks = (parent.subtasks ?? []) + [subtask1]
        parent.subtasks = (parent.subtasks ?? []) + [subtask2]
        parent.subtasks = (parent.subtasks ?? []) + [subtask3]

        context.insert(parent)

        #expect(parent.completedSubtaskCount == 0)

        subtask1.setCompleted(true)
        #expect(parent.completedSubtaskCount == 1)

        subtask2.setCompleted(true)
        #expect(parent.completedSubtaskCount == 2)

        subtask3.setCompleted(true)
        #expect(parent.completedSubtaskCount == 3)
    }

    @Test("hasSubtasks property works correctly")
    func testHasSubtasks() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let parent = Task(title: "Parent")
        context.insert(parent)

        #expect(!parent.hasSubtasks)

        let subtask = Task(title: "Subtask")
        parent.subtasks = (parent.subtasks ?? []) + [subtask]

        #expect(parent.hasSubtasks)
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

    @Test("Task without parent works independently")
    func testTaskWithoutParent() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let task = Task(title: "Test")
        context.insert(task)

        #expect(task.parentTask == nil)

        // Should complete independently
        task.setCompleted(true)
        #expect(task.isCompleted)
    }
}
