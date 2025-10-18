//
//  TaskDueDateTests.swift
//  DaisyDosTests
//
//  Created by Claude Code on 10/17/25.
//

import XCTest
import SwiftData
@testable import DaisyDos

/// Comprehensive test suite for Task due date functionality
/// Tests model logic, computed properties, business rules, and edge cases
@MainActor
final class TaskDueDateTests: XCTestCase {

    var modelContext: ModelContext!
    var taskManager: TaskManager!
    var calendar: Calendar!

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()

        // Create in-memory model container for testing
        let schema = Schema([Task.self, Tag.self, TaskAttachment.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: configuration)

        modelContext = container.mainContext
        taskManager = TaskManager(modelContext: modelContext)
        calendar = Calendar.current
    }

    @MainActor
    override func tearDownWithError() throws {
        modelContext = nil
        taskManager = nil
        calendar = nil
        try super.tearDownWithError()
    }

    // MARK: - Task Creation with Due Date Tests

    func testCreateTaskWithDueDate() throws {
        // Given
        let title = "Task with due date"
        let dueDate = calendar.date(byAdding: .day, value: 3, to: Date())!

        // When
        let result = taskManager.createTask(
            title: title,
            taskDescription: "",
            priority: .medium,
            dueDate: dueDate
        )

        // Then
        switch result {
        case .success(let task):
            XCTAssertEqual(task.title, title)
            XCTAssertNotNil(task.dueDate)
            XCTAssertEqual(task.dueDate, dueDate)
        case .failure(let error):
            XCTFail("Task creation failed: \(error)")
        }
    }

    func testCreateTaskWithoutDueDate() throws {
        // Given
        let title = "Task without due date"

        // When
        let result = taskManager.createTask(
            title: title,
            taskDescription: "",
            priority: .medium,
            dueDate: nil
        )

        // Then
        switch result {
        case .success(let task):
            XCTAssertEqual(task.title, title)
            XCTAssertNil(task.dueDate)
        case .failure(let error):
            XCTFail("Task creation failed: \(error)")
        }
    }

    func testCreateTaskWithPastDueDate() throws {
        // Given
        let title = "Task with past due date"
        let pastDate = calendar.date(byAdding: .day, value: -5, to: Date())!

        // When
        let result = taskManager.createTask(
            title: title,
            dueDate: pastDate
        )

        // Then - Should allow past due dates (user might be catching up on overdue tasks)
        switch result {
        case .success(let task):
            XCTAssertEqual(task.dueDate, pastDate)
            XCTAssertTrue(task.hasOverdueStatus, "Task with past due date should be marked as overdue")
        case .failure(let error):
            XCTFail("Task creation failed: \(error)")
        }
    }

    // MARK: - Due Date Computed Properties Tests

    func testHasOverdueStatus_WithOverdueDate() throws {
        // Given - Task with due date 3 days in the past
        let pastDate = calendar.date(byAdding: .day, value: -3, to: Date())!
        let task = Task(title: "Overdue task", dueDate: pastDate)

        // Then
        XCTAssertTrue(task.hasOverdueStatus, "Task with past due date should be overdue")
        XCTAssertFalse(task.isCompleted, "Incomplete task should show overdue status")
    }

    func testHasOverdueStatus_WithFutureDate() throws {
        // Given - Task with due date 3 days in the future
        let futureDate = calendar.date(byAdding: .day, value: 3, to: Date())!
        let task = Task(title: "Future task", dueDate: futureDate)

        // Then
        XCTAssertFalse(task.hasOverdueStatus, "Task with future due date should not be overdue")
    }

    func testHasOverdueStatus_WithNoDueDate() throws {
        // Given - Task without due date
        let task = Task(title: "No due date task")

        // Then
        XCTAssertFalse(task.hasOverdueStatus, "Task without due date should not be overdue")
    }

    func testHasOverdueStatus_CompletedTaskNotOverdue() throws {
        // Given - Completed task with past due date
        let pastDate = calendar.date(byAdding: .day, value: -3, to: Date())!
        let task = Task(title: "Completed overdue task", dueDate: pastDate)
        task.setCompleted(true)

        // Then
        XCTAssertFalse(task.hasOverdueStatus, "Completed tasks should not show as overdue")
    }

    func testIsDueToday_WithTodayDate() throws {
        // Given - Task due today
        let today = Date()
        let task = Task(title: "Due today", dueDate: today)

        // Then
        XCTAssertTrue(task.isDueToday, "Task with today's date should be marked as due today")
    }

    func testIsDueToday_WithYesterdayDate() throws {
        // Given - Task due yesterday
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let task = Task(title: "Due yesterday", dueDate: yesterday)

        // Then
        XCTAssertFalse(task.isDueToday, "Task with yesterday's date should not be due today")
    }

    func testIsDueToday_WithTomorrowDate() throws {
        // Given - Task due tomorrow
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let task = Task(title: "Due tomorrow", dueDate: tomorrow)

        // Then
        XCTAssertFalse(task.isDueToday, "Task with tomorrow's date should not be due today")
    }

    func testIsDueSoon_WithinThreeDays() throws {
        // Given - Tasks due in 0-3 days
        let tests: [(days: Int, expected: Bool, label: String)] = [
            (0, true, "Today"),
            (1, true, "Tomorrow"),
            (2, true, "In 2 days"),
            (3, true, "In 3 days"),
            (4, false, "In 4 days"),
            (-1, false, "Yesterday")
        ]

        for test in tests {
            let dueDate = calendar.date(byAdding: .day, value: test.days, to: Date())!
            let task = Task(title: "Task due \(test.label)", dueDate: dueDate)

            // Then
            XCTAssertEqual(
                task.isDueSoon,
                test.expected,
                "Task due \(test.label) should\(test.expected ? "" : " not") be due soon"
            )
        }
    }

    func testIsDueSoon_CompletedTask() throws {
        // Given - Completed task due tomorrow
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let task = Task(title: "Completed task", dueDate: tomorrow)
        task.setCompleted(true)

        // Then
        XCTAssertFalse(task.isDueSoon, "Completed tasks should not be marked as due soon")
    }

    // MARK: - Due Date Display Text Tests

    func testDueDateDisplayText_Today() throws {
        // Given - Task due today
        let today = Date()
        let task = Task(title: "Due today", dueDate: today)

        // Then
        XCTAssertEqual(task.dueDateDisplayText, "Today")
    }

    func testDueDateDisplayText_Tomorrow() throws {
        // Given - Task due tomorrow
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        let task = Task(title: "Due tomorrow", dueDate: tomorrow)

        // Then
        XCTAssertEqual(task.dueDateDisplayText, "Tomorrow")
    }

    func testDueDateDisplayText_ThisYear() throws {
        // Given - Task due later this year
        let futureDate = calendar.date(byAdding: .month, value: 2, to: Date())!
        let task = Task(title: "Due in 2 months", dueDate: futureDate)

        // Then
        XCTAssertNotNil(task.dueDateDisplayText)
        XCTAssertFalse(task.dueDateDisplayText!.contains(","), "Should use short format without year")
    }

    func testDueDateDisplayText_NextYear() throws {
        // Given - Task due next year
        let nextYear = calendar.date(byAdding: .year, value: 1, to: Date())!
        let task = Task(title: "Due next year", dueDate: nextYear)

        // Then
        XCTAssertNotNil(task.dueDateDisplayText)
        XCTAssertTrue(task.dueDateDisplayText!.contains(","), "Should include year in format")
    }

    func testDueDateDisplayText_NoDueDate() throws {
        // Given - Task without due date
        let task = Task(title: "No due date")

        // Then
        XCTAssertNil(task.dueDateDisplayText, "Task without due date should return nil")
    }

    // MARK: - Due Date Update Tests

    func testUpdateTaskDueDate() throws {
        // Given - Task with initial due date
        let initialDate = calendar.date(byAdding: .day, value: 3, to: Date())!
        let result = taskManager.createTask(title: "Task to update", dueDate: initialDate)

        guard case .success(let task) = result else {
            XCTFail("Failed to create task")
            return
        }

        // When - Update due date
        let newDate = calendar.date(byAdding: .day, value: 7, to: Date())!
        let updateResult = taskManager.updateTask(task, dueDate: newDate)

        // Then
        switch updateResult {
        case .success:
            XCTAssertEqual(task.dueDate, newDate, "Due date should be updated")
        case .failure(let error):
            XCTFail("Update failed: \(error)")
        }
    }

    func testRemoveDueDateFromTask() throws {
        // Given - Task with due date
        let initialDate = calendar.date(byAdding: .day, value: 3, to: Date())!
        let task = Task(title: "Task with due date", dueDate: initialDate)
        modelContext.insert(task)

        // When - Set due date to nil
        task.dueDate = nil
        task.modifiedDate = Date()

        // Then
        XCTAssertNil(task.dueDate, "Due date should be removed")
        XCTAssertFalse(task.hasOverdueStatus, "Task without due date should not be overdue")
        XCTAssertFalse(task.isDueToday, "Task without due date should not be due today")
        XCTAssertFalse(task.isDueSoon, "Task without due date should not be due soon")
    }

    // MARK: - Subtask Due Date Inheritance Tests

    func testSubtaskInheritsDueDate() throws {
        // Given - Parent task with due date
        let parentDueDate = calendar.date(byAdding: .day, value: 5, to: Date())!
        let parent = Task(title: "Parent task", dueDate: parentDueDate)
        modelContext.insert(parent)

        // When - Create subtask
        let subtask = parent.createSubtask(title: "Subtask", taskDescription: "", priority: .none)

        // Then
        XCTAssertEqual(subtask.dueDate, parentDueDate, "Subtask should inherit parent's due date")
    }

    func testSubtaskCanHaveDifferentDueDate() throws {
        // Given - Parent with due date and subtask with different due date
        let parentDueDate = calendar.date(byAdding: .day, value: 5, to: Date())!
        let parent = Task(title: "Parent task", dueDate: parentDueDate)
        modelContext.insert(parent)

        let subtask = parent.createSubtask(title: "Subtask")
        let subtaskDueDate = calendar.date(byAdding: .day, value: 2, to: Date())!
        subtask.dueDate = subtaskDueDate

        // Then
        XCTAssertEqual(subtask.dueDate, subtaskDueDate)
        XCTAssertNotEqual(subtask.dueDate, parent.dueDate)
    }

    // MARK: - Due Date with Recurrence Tests

    func testRecurringTaskNextOccurrence() throws {
        // Given - Daily recurring task
        let initialDueDate = calendar.date(byAdding: .day, value: 1, to: Date())!
        let recurrenceRule = RecurrenceRule.daily()
        let task = Task(
            title: "Daily task",
            dueDate: initialDueDate,
            recurrenceRule: recurrenceRule
        )

        // When
        let nextDate = task.nextRecurrence()

        // Then
        XCTAssertNotNil(nextDate, "Recurring task should have next occurrence")

        let expectedNext = calendar.date(byAdding: .day, value: 1, to: initialDueDate)!
        XCTAssertEqual(
            calendar.compare(nextDate!, to: expectedNext, toGranularity: .day),
            .orderedSame,
            "Next occurrence should be 1 day after initial due date"
        )
    }

    func testCreateRecurringInstance() throws {
        // Given - Weekly recurring task
        let initialDueDate = Date()
        let recurrenceRule = RecurrenceRule.weekly(daysOfWeek: [2, 4, 6]) // Mon, Wed, Fri
        let task = Task(
            title: "Weekly meeting",
            taskDescription: "Team sync",
            priority: .high,
            dueDate: initialDueDate,
            recurrenceRule: recurrenceRule
        )

        // When
        guard let newInstance = task.createRecurringInstance() else {
            XCTFail("Failed to create recurring instance")
            return
        }

        // Then
        XCTAssertEqual(newInstance.title, task.title, "Title should match")
        XCTAssertEqual(newInstance.taskDescription, task.taskDescription, "Description should match")
        XCTAssertEqual(newInstance.priority, task.priority, "Priority should match")
        XCTAssertEqual(newInstance.recurrenceRule, task.recurrenceRule, "Recurrence rule should match")
        XCTAssertNotEqual(newInstance.dueDate, task.dueDate, "Due date should be updated to next occurrence")
        XCTAssertFalse(newInstance.isCompleted, "New instance should not be completed")
    }

    // MARK: - TaskManager Filtering Tests

    func testOverdueTasks() throws {
        // Given - Mix of overdue and future tasks
        let overdueDate = calendar.date(byAdding: .day, value: -2, to: Date())!
        let futureDate = calendar.date(byAdding: .day, value: 2, to: Date())!

        _ = taskManager.createTask(title: "Overdue 1", dueDate: overdueDate)
        _ = taskManager.createTask(title: "Overdue 2", dueDate: overdueDate)
        _ = taskManager.createTask(title: "Future", dueDate: futureDate)
        _ = taskManager.createTask(title: "No due date")

        // When
        let overdueTasks = taskManager.overdueTasks()

        // Then
        XCTAssertEqual(overdueTasks.count, 2, "Should return only overdue tasks")
        XCTAssertTrue(overdueTasks.allSatisfy { $0.hasOverdueStatus }, "All returned tasks should be overdue")
    }

    func testTasksDueToday() throws {
        // Given - Tasks with various due dates
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!

        _ = taskManager.createTask(title: "Due today 1", dueDate: today)
        _ = taskManager.createTask(title: "Due today 2", dueDate: today)
        _ = taskManager.createTask(title: "Due tomorrow", dueDate: tomorrow)

        // When
        let todayTasks = taskManager.tasksDueToday()

        // Then
        XCTAssertEqual(todayTasks.count, 2, "Should return only tasks due today")
        XCTAssertTrue(todayTasks.allSatisfy { $0.isDueToday }, "All returned tasks should be due today")
    }

    func testTasksDueSoon() throws {
        // Given - Tasks due in various time frames
        let today = Date()
        let twoDays = calendar.date(byAdding: .day, value: 2, to: Date())!
        let fiveDays = calendar.date(byAdding: .day, value: 5, to: Date())!

        _ = taskManager.createTask(title: "Due today", dueDate: today)
        _ = taskManager.createTask(title: "Due in 2 days", dueDate: twoDays)
        _ = taskManager.createTask(title: "Due in 5 days", dueDate: fiveDays)

        // When
        let soonTasks = taskManager.tasksDueSoon()

        // Then
        XCTAssertEqual(soonTasks.count, 2, "Should return tasks due within 3 days")
        XCTAssertTrue(soonTasks.allSatisfy { $0.isDueSoon }, "All returned tasks should be due soon")
    }

    func testTasksWithDueDates() throws {
        // Given - Mix of tasks with and without due dates
        let dueDate = calendar.date(byAdding: .day, value: 3, to: Date())!

        _ = taskManager.createTask(title: "With due date 1", dueDate: dueDate)
        _ = taskManager.createTask(title: "With due date 2", dueDate: dueDate)
        _ = taskManager.createTask(title: "Without due date")

        // When
        let tasksWithDates = taskManager.tasksWithDueDates()

        // Then
        XCTAssertEqual(tasksWithDates.count, 2, "Should return only tasks with due dates")
        XCTAssertTrue(tasksWithDates.allSatisfy { $0.dueDate != nil }, "All returned tasks should have due dates")
    }

    // MARK: - Enhanced Today's Tasks Tests

    func testEnhancedTodaysTasks_IncludesOverdue() throws {
        // Given - Overdue task
        let overdueDate = calendar.date(byAdding: .day, value: -3, to: Date())!
        _ = taskManager.createTask(title: "Overdue task", dueDate: overdueDate)

        // When
        let todaysTasks = taskManager.enhancedTodaysTasks

        // Then
        XCTAssertEqual(todaysTasks.count, 1, "Should include overdue tasks")
        XCTAssertTrue(todaysTasks[0].hasOverdueStatus, "Task should be overdue")
    }

    func testEnhancedTodaysTasks_IncludesDueToday() throws {
        // Given - Task due today
        _ = taskManager.createTask(title: "Due today", dueDate: Date())

        // When
        let todaysTasks = taskManager.enhancedTodaysTasks

        // Then
        XCTAssertEqual(todaysTasks.count, 1, "Should include tasks due today")
        XCTAssertTrue(todaysTasks[0].isDueToday, "Task should be due today")
    }

    func testEnhancedTodaysTasks_IncludesNoDueDate() throws {
        // Given - Task without due date
        _ = taskManager.createTask(title: "No due date")

        // When
        let todaysTasks = taskManager.enhancedTodaysTasks

        // Then
        XCTAssertEqual(todaysTasks.count, 1, "Should include tasks without due dates")
        XCTAssertNil(todaysTasks[0].dueDate, "Task should have no due date")
    }

    func testEnhancedTodaysTasks_ExcludesFutureTasks() throws {
        // Given - Task due in the future
        let futureDate = calendar.date(byAdding: .day, value: 5, to: Date())!
        _ = taskManager.createTask(title: "Future task", dueDate: futureDate)

        // When
        let todaysTasks = taskManager.enhancedTodaysTasks

        // Then
        XCTAssertEqual(todaysTasks.count, 0, "Should exclude future tasks")
    }

    func testEnhancedTodaysTasks_ExcludesCompleted() throws {
        // Given - Completed task due today
        let result = taskManager.createTask(title: "Completed task", dueDate: Date())
        guard case .success(let task) = result else {
            XCTFail("Failed to create task")
            return
        }
        task.setCompleted(true)

        // When
        let todaysTasks = taskManager.enhancedTodaysTasks

        // Then
        XCTAssertEqual(todaysTasks.count, 0, "Should exclude completed tasks")
    }

    func testEnhancedTodaysTasks_Sorting() throws {
        // Given - Tasks with different priorities and due dates
        let overdue = calendar.date(byAdding: .day, value: -2, to: Date())!
        let today = Date()

        let result1 = taskManager.createTask(title: "Low priority, overdue", priority: .low, dueDate: overdue)
        let result2 = taskManager.createTask(title: "High priority, today", priority: .high, dueDate: today)
        let result3 = taskManager.createTask(title: "Medium priority, no date", priority: .medium, dueDate: nil)

        guard case .success(_) = result1,
              case .success(_) = result2,
              case .success(_) = result3 else {
            XCTFail("Failed to create tasks")
            return
        }

        // When
        let todaysTasks = taskManager.enhancedTodaysTasks

        // Then
        XCTAssertEqual(todaysTasks.count, 3)
        // High priority should come first
        XCTAssertEqual(todaysTasks[0].priority, .high)
        // Then medium priority
        XCTAssertEqual(todaysTasks[1].priority, .medium)
        // Then low priority
        XCTAssertEqual(todaysTasks[2].priority, .low)
    }

    // MARK: - Edge Cases and Validation Tests

    func testDueDateAtMidnight() throws {
        // Given - Task due at midnight
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 0
        components.minute = 0
        components.second = 0
        let midnight = calendar.date(from: components)!

        let task = Task(title: "Midnight task", dueDate: midnight)

        // Then - Should still work correctly
        XCTAssertNotNil(task.dueDate)
        XCTAssertNotNil(task.dueDateDisplayText)
    }

    func testDuplicateTaskWithOverdueDueDate() throws {
        // Given - Task with overdue due date
        let pastDate = calendar.date(byAdding: .day, value: -5, to: Date())!
        let result = taskManager.createTask(title: "Overdue task", dueDate: pastDate)

        guard case .success(let task) = result else {
            XCTFail("Failed to create task")
            return
        }

        // When - Duplicate the task
        let duplicateResult = taskManager.duplicateTask(task)

        // Then - Duplicate should not have past due date
        switch duplicateResult {
        case .success(let duplicate):
            XCTAssertNil(duplicate.dueDate, "Duplicated task with past due date should have due date removed")
        case .failure(let error):
            XCTFail("Duplication failed: \(error)")
        }
    }

    func testDuplicateTaskWithFutureDueDate() throws {
        // Given - Task with future due date
        let futureDate = calendar.date(byAdding: .day, value: 5, to: Date())!
        let result = taskManager.createTask(title: "Future task", dueDate: futureDate)

        guard case .success(let task) = result else {
            XCTFail("Failed to create task")
            return
        }

        // When - Duplicate the task
        let duplicateResult = taskManager.duplicateTask(task)

        // Then - Duplicate should keep future due date
        switch duplicateResult {
        case .success(let duplicate):
            XCTAssertNotNil(duplicate.dueDate, "Duplicated task with future due date should keep due date")
            XCTAssertEqual(duplicate.dueDate, futureDate, "Due date should match original")
        case .failure(let error):
            XCTFail("Duplication failed: \(error)")
        }
    }
}
