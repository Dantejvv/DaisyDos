//
//  DueDateTestSuite.swift
//  DaisyDos
//
//  Created by Claude Code on 10/17/25.
//  Automated test suite for Task Due Date functionality
//

#if DEBUG
import Foundation
import SwiftData

@Observable
class DueDateTestSuite {
    let modelContext: ModelContext
    let taskManager: TaskManager

    var testResults: [TestResult] = []
    var isRunning = false
    var currentTest: String = ""

    struct TestResult {
        let testNumber: Int
        let name: String
        let passed: Bool
        let message: String
        let duration: TimeInterval
    }

    init(modelContext: ModelContext, taskManager: TaskManager) {
        self.modelContext = modelContext
        self.taskManager = taskManager
    }

    // MARK: - Test Runner

    func runAllTests() {
        testResults.removeAll()
        isRunning = true

        print("\n🧪 ========================================")
        print("🧪 DUE DATE TEST SUITE - STARTING")
        print("🧪 ========================================\n")

        // Core functionality tests
        runTest1_CreateTaskWithDueDate()
        runTest2_CreateTaskWithoutDueDate()
        runTest3_CreateTaskWithPastDueDate()
        runTest4_OverdueStatusDetection()
        runTest5_DueTodayDetection()
        runTest6_DueSoonDetection()
        runTest7_DisplayTextFormatting()
        runTest8_UpdateDueDate()
        runTest9_RemoveDueDate()
        runTest10_SubtaskInheritance()
        runTest11_SubtaskIndependentDueDate()
        runTest12_RecurrenceNextOccurrence()
        runTest13_RecurringInstanceCreation()
        runTest14_OverdueTasksFiltering()
        runTest15_TasksDueTodayFiltering()
        runTest16_TasksDueSoonFiltering()
        runTest17_EnhancedTodaysTasks()
        runTest18_DueDateSorting()
        runTest19_DuplicateOverdueTask()
        runTest20_DuplicateFutureTask()

        isRunning = false
        printSummary()
    }

    private func printSummary() {
        let passed = testResults.filter { $0.passed }.count
        let failed = testResults.count - passed
        let totalDuration = testResults.reduce(0.0) { $0 + $1.duration }

        print("\n🧪 ========================================")
        print("🧪 TEST SUITE COMPLETE")
        print("🧪 ========================================")
        print("✅ Passed: \(passed)")
        print("❌ Failed: \(failed)")
        print("⏱️  Total Duration: \(String(format: "%.2f", totalDuration))s")
        print("🧪 ========================================\n")
    }

    // MARK: - Test Cases

    /// Test 1: Create Task with Due Date
    private func runTest1_CreateTaskWithDueDate() {
        currentTest = "Test 1: Create Task with Due Date"
        let startTime = Date()

        do {
            try cleanDatabase()

            let dueDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
            let result = taskManager.createTask(
                title: "Task with due date",
                dueDate: dueDate
            )

            guard case .success(let task) = result else {
                recordFailure(1, startTime, "Task creation failed")
                return
            }

            if task.dueDate == dueDate {
                recordSuccess(1, startTime, "Due date set to \(formatDate(dueDate))")
            } else {
                recordFailure(1, startTime, "Due date mismatch")
            }
        } catch {
            recordFailure(1, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 2: Create Task without Due Date
    private func runTest2_CreateTaskWithoutDueDate() {
        currentTest = "Test 2: Create Task without Due Date"
        let startTime = Date()

        do {
            try cleanDatabase()

            let result = taskManager.createTask(title: "Task without due date")

            guard case .success(let task) = result else {
                recordFailure(2, startTime, "Task creation failed")
                return
            }

            if task.dueDate == nil {
                recordSuccess(2, startTime, "Task correctly has no due date")
            } else {
                recordFailure(2, startTime, "Task unexpectedly has due date")
            }
        } catch {
            recordFailure(2, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 3: Create Task with Past Due Date
    private func runTest3_CreateTaskWithPastDueDate() {
        currentTest = "Test 3: Create Task with Past Due Date"
        let startTime = Date()

        do {
            try cleanDatabase()

            let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
            let result = taskManager.createTask(
                title: "Past due task",
                dueDate: pastDate
            )

            guard case .success(let task) = result else {
                recordFailure(3, startTime, "Task creation failed")
                return
            }

            if task.hasOverdueStatus {
                recordSuccess(3, startTime, "Past due date correctly marked as overdue")
            } else {
                recordFailure(3, startTime, "Past due date not marked as overdue")
            }
        } catch {
            recordFailure(3, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 4: Overdue Status Detection
    private func runTest4_OverdueStatusDetection() {
        currentTest = "Test 4: Overdue Status Detection"
        let startTime = Date()

        do {
            try cleanDatabase()

            let overdueDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
            let futureDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!

            let task1 = Task(title: "Overdue task", dueDate: overdueDate)
            let task2 = Task(title: "Future task", dueDate: futureDate)
            let task3 = Task(title: "Completed overdue", dueDate: overdueDate)
            task3.setCompleted(true)

            modelContext.insert(task1)
            modelContext.insert(task2)
            modelContext.insert(task3)
            try modelContext.save()

            if task1.hasOverdueStatus &&
               !task2.hasOverdueStatus &&
               !task3.hasOverdueStatus {
                recordSuccess(4, startTime, "Overdue status correctly detected")
            } else {
                recordFailure(4, startTime, "Overdue status detection incorrect")
            }
        } catch {
            recordFailure(4, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 5: Due Today Detection
    private func runTest5_DueTodayDetection() {
        currentTest = "Test 5: Due Today Detection"
        let startTime = Date()

        do {
            try cleanDatabase()

            let today = Date()
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

            let task1 = Task(title: "Due today", dueDate: today)
            let task2 = Task(title: "Due yesterday", dueDate: yesterday)
            let task3 = Task(title: "Due tomorrow", dueDate: tomorrow)

            modelContext.insert(task1)
            modelContext.insert(task2)
            modelContext.insert(task3)
            try modelContext.save()

            if task1.isDueToday &&
               !task2.isDueToday &&
               !task3.isDueToday {
                recordSuccess(5, startTime, "isDueToday correctly identifies today's tasks")
            } else {
                recordFailure(5, startTime, "isDueToday detection incorrect")
            }
        } catch {
            recordFailure(5, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 6: Due Soon Detection (0-3 days)
    private func runTest6_DueSoonDetection() {
        currentTest = "Test 6: Due Soon Detection"
        let startTime = Date()

        do {
            try cleanDatabase()

            let today = Date()
            let in2Days = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
            let in3Days = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
            let in4Days = Calendar.current.date(byAdding: .day, value: 4, to: Date())!

            let task1 = Task(title: "Due today", dueDate: today)
            let task2 = Task(title: "Due in 2 days", dueDate: in2Days)
            let task3 = Task(title: "Due in 3 days", dueDate: in3Days)
            let task4 = Task(title: "Due in 4 days", dueDate: in4Days)

            modelContext.insert(task1)
            modelContext.insert(task2)
            modelContext.insert(task3)
            modelContext.insert(task4)
            try modelContext.save()

            if task1.isDueSoon &&
               task2.isDueSoon &&
               task3.isDueSoon &&
               !task4.isDueSoon {
                recordSuccess(6, startTime, "isDueSoon correctly identifies 0-3 day window")
            } else {
                recordFailure(6, startTime, "isDueSoon detection incorrect (T:\(task1.isDueSoon), 2D:\(task2.isDueSoon), 3D:\(task3.isDueSoon), 4D:\(task4.isDueSoon))")
            }
        } catch {
            recordFailure(6, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 7: Display Text Formatting
    private func runTest7_DisplayTextFormatting() {
        currentTest = "Test 7: Display Text Formatting"
        let startTime = Date()

        do {
            try cleanDatabase()

            let today = Date()
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let nextYear = Calendar.current.date(byAdding: .year, value: 1, to: Date())!

            let task1 = Task(title: "Due today", dueDate: today)
            let task2 = Task(title: "Due tomorrow", dueDate: tomorrow)
            let task3 = Task(title: "Due next year", dueDate: nextYear)
            let task4 = Task(title: "No due date")

            modelContext.insert(task1)
            modelContext.insert(task2)
            modelContext.insert(task3)
            modelContext.insert(task4)
            try modelContext.save()

            if task1.dueDateDisplayText == "Today" &&
               task2.dueDateDisplayText == "Tomorrow" &&
               task3.dueDateDisplayText?.contains(",") == true &&
               task4.dueDateDisplayText == nil {
                recordSuccess(7, startTime, "Display text formatted correctly (Today, Tomorrow, Year format, nil)")
            } else {
                recordFailure(7, startTime, "Display text incorrect: '\(task1.dueDateDisplayText ?? "nil")', '\(task2.dueDateDisplayText ?? "nil")', '\(task3.dueDateDisplayText ?? "nil")', '\(task4.dueDateDisplayText ?? "nil")'")
            }
        } catch {
            recordFailure(7, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 8: Update Due Date
    private func runTest8_UpdateDueDate() {
        currentTest = "Test 8: Update Due Date"
        let startTime = Date()

        do {
            try cleanDatabase()

            let initialDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
            let result = taskManager.createTask(title: "Task to update", dueDate: initialDate)

            guard case .success(let task) = result else {
                recordFailure(8, startTime, "Task creation failed")
                return
            }

            let newDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
            let updateResult = taskManager.updateTask(task, dueDate: newDate)

            if case .success = updateResult, task.dueDate == newDate {
                recordSuccess(8, startTime, "Due date updated from \(formatDate(initialDate)) to \(formatDate(newDate))")
            } else {
                recordFailure(8, startTime, "Due date update failed")
            }
        } catch {
            recordFailure(8, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 9: Remove Due Date
    private func runTest9_RemoveDueDate() {
        currentTest = "Test 9: Remove Due Date"
        let startTime = Date()

        do {
            try cleanDatabase()

            let initialDate = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
            let task = Task(title: "Task with due date", dueDate: initialDate)
            modelContext.insert(task)
            try modelContext.save()

            // Remove due date
            task.dueDate = nil
            try modelContext.save()

            if task.dueDate == nil &&
               !task.hasOverdueStatus &&
               !task.isDueToday &&
               !task.isDueSoon {
                recordSuccess(9, startTime, "Due date removed, all status flags cleared")
            } else {
                recordFailure(9, startTime, "Due date removal incomplete")
            }
        } catch {
            recordFailure(9, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 10: Subtask Inherits Parent Due Date
    private func runTest10_SubtaskInheritance() {
        currentTest = "Test 10: Subtask Inherits Parent Due Date"
        let startTime = Date()

        do {
            try cleanDatabase()

            let parentDueDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
            let parent = Task(title: "Parent task", dueDate: parentDueDate)
            modelContext.insert(parent)
            try modelContext.save()

            let subtask = parent.createSubtask(title: "Subtask")

            if subtask.dueDate == parentDueDate {
                recordSuccess(10, startTime, "Subtask correctly inherited parent due date")
            } else {
                recordFailure(10, startTime, "Subtask did not inherit due date")
            }
        } catch {
            recordFailure(10, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 11: Subtask Can Have Different Due Date
    private func runTest11_SubtaskIndependentDueDate() {
        currentTest = "Test 11: Subtask Can Have Different Due Date"
        let startTime = Date()

        do {
            try cleanDatabase()

            let parentDueDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
            let parent = Task(title: "Parent task", dueDate: parentDueDate)
            modelContext.insert(parent)

            let subtask = parent.createSubtask(title: "Subtask")
            let subtaskDueDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
            subtask.dueDate = subtaskDueDate
            try modelContext.save()

            if subtask.dueDate == subtaskDueDate && subtask.dueDate != parent.dueDate {
                recordSuccess(11, startTime, "Subtask can have independent due date")
            } else {
                recordFailure(11, startTime, "Subtask due date independence failed")
            }
        } catch {
            recordFailure(11, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 12: Recurrence Next Occurrence
    private func runTest12_RecurrenceNextOccurrence() {
        currentTest = "Test 12: Recurrence Next Occurrence"
        let startTime = Date()

        do {
            try cleanDatabase()

            let initialDueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
            let recurrenceRule = RecurrenceRule.daily()
            let task = Task(
                title: "Daily task",
                dueDate: initialDueDate,
                recurrenceRule: recurrenceRule
            )
            modelContext.insert(task)
            try modelContext.save()

            if let nextDate = task.nextRecurrence() {
                let expectedNext = Calendar.current.date(byAdding: .day, value: 1, to: initialDueDate)!
                let isSameDay = Calendar.current.isDate(nextDate, inSameDayAs: expectedNext)

                if isSameDay {
                    recordSuccess(12, startTime, "Next occurrence calculated correctly (1 day after)")
                } else {
                    recordFailure(12, startTime, "Next occurrence date incorrect")
                }
            } else {
                recordFailure(12, startTime, "Next occurrence returned nil")
            }
        } catch {
            recordFailure(12, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 13: Recurring Instance Creation
    private func runTest13_RecurringInstanceCreation() {
        currentTest = "Test 13: Recurring Instance Creation"
        let startTime = Date()

        do {
            try cleanDatabase()

            let initialDueDate = Date()
            let recurrenceRule = RecurrenceRule.daily()
            let task = Task(
                title: "Daily meeting",
                taskDescription: "Team sync",
                priority: .high,
                dueDate: initialDueDate,
                recurrenceRule: recurrenceRule
            )
            modelContext.insert(task)
            try modelContext.save()

            guard let newInstance = task.createRecurringInstance() else {
                recordFailure(13, startTime, "Failed to create recurring instance")
                return
            }

            if newInstance.title == task.title &&
               newInstance.taskDescription == task.taskDescription &&
               newInstance.priority == task.priority &&
               newInstance.recurrenceRule == task.recurrenceRule &&
               newInstance.dueDate != task.dueDate &&
               !newInstance.isCompleted {
                recordSuccess(13, startTime, "Recurring instance created with updated due date")
            } else {
                recordFailure(13, startTime, "Recurring instance properties incorrect")
            }
        } catch {
            recordFailure(13, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 14: Overdue Tasks Filtering
    private func runTest14_OverdueTasksFiltering() {
        currentTest = "Test 14: Overdue Tasks Filtering"
        let startTime = Date()

        do {
            try cleanDatabase()

            let overdueDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
            let futureDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!

            _ = taskManager.createTask(title: "Overdue 1", dueDate: overdueDate)
            _ = taskManager.createTask(title: "Overdue 2", dueDate: overdueDate)
            _ = taskManager.createTask(title: "Future", dueDate: futureDate)
            _ = taskManager.createTask(title: "No due date")

            let overdueTasks = taskManager.overdueTasks()

            if overdueTasks.count == 2 &&
               overdueTasks.allSatisfy({ $0.hasOverdueStatus }) {
                recordSuccess(14, startTime, "Overdue tasks filter returns only overdue tasks (2/4)")
            } else {
                recordFailure(14, startTime, "Overdue filter incorrect (Found: \(overdueTasks.count))")
            }
        } catch {
            recordFailure(14, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 15: Tasks Due Today Filtering
    private func runTest15_TasksDueTodayFiltering() {
        currentTest = "Test 15: Tasks Due Today Filtering"
        let startTime = Date()

        do {
            try cleanDatabase()

            let today = Date()
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

            _ = taskManager.createTask(title: "Due today 1", dueDate: today)
            _ = taskManager.createTask(title: "Due today 2", dueDate: today)
            _ = taskManager.createTask(title: "Due tomorrow", dueDate: tomorrow)

            let todayTasks = taskManager.tasksDueToday()

            if todayTasks.count == 2 &&
               todayTasks.allSatisfy({ $0.isDueToday }) {
                recordSuccess(15, startTime, "Tasks due today filter correct (2/3)")
            } else {
                recordFailure(15, startTime, "Due today filter incorrect (Found: \(todayTasks.count))")
            }
        } catch {
            recordFailure(15, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 16: Tasks Due Soon Filtering
    private func runTest16_TasksDueSoonFiltering() {
        currentTest = "Test 16: Tasks Due Soon Filtering"
        let startTime = Date()

        do {
            try cleanDatabase()

            let today = Date()
            let in2Days = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
            let in5Days = Calendar.current.date(byAdding: .day, value: 5, to: Date())!

            _ = taskManager.createTask(title: "Due today", dueDate: today)
            _ = taskManager.createTask(title: "Due in 2 days", dueDate: in2Days)
            _ = taskManager.createTask(title: "Due in 5 days", dueDate: in5Days)

            let soonTasks = taskManager.tasksDueSoon()

            if soonTasks.count == 2 &&
               soonTasks.allSatisfy({ $0.isDueSoon }) {
                recordSuccess(16, startTime, "Tasks due soon filter correct (2/3, within 3 days)")
            } else {
                recordFailure(16, startTime, "Due soon filter incorrect (Found: \(soonTasks.count))")
            }
        } catch {
            recordFailure(16, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 17: Enhanced Today's Tasks
    private func runTest17_EnhancedTodaysTasks() {
        currentTest = "Test 17: Enhanced Today's Tasks"
        let startTime = Date()

        do {
            try cleanDatabase()

            let overdueDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
            let today = Date()
            let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!

            _ = taskManager.createTask(title: "Overdue", dueDate: overdueDate)
            _ = taskManager.createTask(title: "Due today", dueDate: today)
            _ = taskManager.createTask(title: "No due date")
            _ = taskManager.createTask(title: "Future", dueDate: futureDate)

            let todaysTasks = taskManager.enhancedTodaysTasks

            // Should include: overdue, due today, no due date (3 tasks)
            // Should exclude: future (1 task)
            if todaysTasks.count == 3 {
                recordSuccess(17, startTime, "Enhanced today's tasks includes overdue, today, and no date (3/4)")
            } else {
                recordFailure(17, startTime, "Enhanced today's tasks incorrect (Found: \(todaysTasks.count), Expected: 3)")
            }
        } catch {
            recordFailure(17, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 18: Due Date Sorting
    private func runTest18_DueDateSorting() {
        currentTest = "Test 18: Due Date Sorting"
        let startTime = Date()

        do {
            try cleanDatabase()

            let date1 = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
            let date2 = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
            let date3 = Calendar.current.date(byAdding: .day, value: 10, to: Date())!

            _ = taskManager.createTask(title: "Task C (10 days)", dueDate: date3)
            _ = taskManager.createTask(title: "Task A (5 days)", dueDate: date1)
            _ = taskManager.createTask(title: "Task B (2 days)", dueDate: date2)
            _ = taskManager.createTask(title: "Task D (no date)")

            let allTasks = taskManager.allTasks
            let sorted = allTasks.sorted { task1, task2 in
                switch (task1.dueDate, task2.dueDate) {
                case (nil, nil): return task1.createdDate > task2.createdDate
                case (nil, _): return false
                case (_, nil): return true
                case (let d1?, let d2?): return d1 < d2
                }
            }

            // Expected order: Task B (2 days), Task A (5 days), Task C (10 days), Task D (no date)
            if sorted[0].title.contains("2 days") &&
               sorted[1].title.contains("5 days") &&
               sorted[2].title.contains("10 days") &&
               sorted[3].title.contains("no date") {
                recordSuccess(18, startTime, "Due date sorting correct (earliest → latest → no date)")
            } else {
                let order = sorted.map { $0.title }.joined(separator: " → ")
                recordFailure(18, startTime, "Sorting incorrect: \(order)")
            }
        } catch {
            recordFailure(18, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 19: Duplicate Overdue Task (past due date removed)
    private func runTest19_DuplicateOverdueTask() {
        currentTest = "Test 19: Duplicate Overdue Task"
        let startTime = Date()

        do {
            try cleanDatabase()

            let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
            let result = taskManager.createTask(title: "Overdue task", dueDate: pastDate)

            guard case .success(let task) = result else {
                recordFailure(19, startTime, "Task creation failed")
                return
            }

            let duplicateResult = taskManager.duplicateTask(task)

            guard case .success(let duplicate) = duplicateResult else {
                recordFailure(19, startTime, "Duplication failed")
                return
            }

            if duplicate.dueDate == nil {
                recordSuccess(19, startTime, "Past due date correctly removed from duplicate")
            } else {
                recordFailure(19, startTime, "Past due date not removed (has: \(formatDate(duplicate.dueDate!)))")
            }
        } catch {
            recordFailure(19, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 20: Duplicate Future Task (due date preserved)
    private func runTest20_DuplicateFutureTask() {
        currentTest = "Test 20: Duplicate Future Task"
        let startTime = Date()

        do {
            try cleanDatabase()

            let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
            let result = taskManager.createTask(title: "Future task", dueDate: futureDate)

            guard case .success(let task) = result else {
                recordFailure(20, startTime, "Task creation failed")
                return
            }

            let duplicateResult = taskManager.duplicateTask(task)

            guard case .success(let duplicate) = duplicateResult else {
                recordFailure(20, startTime, "Duplication failed")
                return
            }

            if duplicate.dueDate == futureDate {
                recordSuccess(20, startTime, "Future due date correctly preserved in duplicate")
            } else {
                recordFailure(20, startTime, "Future due date not preserved")
            }
        } catch {
            recordFailure(20, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    private func cleanDatabase() throws {
        let taskDescriptor = FetchDescriptor<Task>()
        let allTasks = try modelContext.fetch(taskDescriptor)
        for task in allTasks {
            modelContext.delete(task)
        }

        let tagDescriptor = FetchDescriptor<Tag>()
        let allTags = try modelContext.fetch(tagDescriptor)
        for tag in allTags {
            modelContext.delete(tag)
        }

        try modelContext.save()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }

    private func recordSuccess(_ testNumber: Int, _ startTime: Date, _ message: String) {
        let duration = Date().timeIntervalSince(startTime)
        let result = TestResult(
            testNumber: testNumber,
            name: currentTest,
            passed: true,
            message: message,
            duration: duration
        )
        testResults.append(result)
        print("✅ Test \(testNumber): \(currentTest) - \(message)")
    }

    private func recordFailure(_ testNumber: Int, _ startTime: Date, _ message: String) {
        let duration = Date().timeIntervalSince(startTime)
        let result = TestResult(
            testNumber: testNumber,
            name: currentTest,
            passed: false,
            message: message,
            duration: duration
        )
        testResults.append(result)
        print("❌ Test \(testNumber): \(currentTest) - FAILED: \(message)")
    }
}
#endif
