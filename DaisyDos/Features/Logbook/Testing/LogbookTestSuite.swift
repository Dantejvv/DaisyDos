//
//  LogbookTestSuite.swift
//  DaisyDos
//
//  Created by Claude Code on 10/15/25.
//  Automated test suite for Logbook & Housekeeping functionality
//

#if DEBUG
import Foundation
import SwiftData

@Observable
class LogbookTestSuite {
    let modelContext: ModelContext
    let logbookManager: LogbookManager

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

    init(modelContext: ModelContext, logbookManager: LogbookManager) {
        self.modelContext = modelContext
        self.logbookManager = logbookManager
    }

    // MARK: - Test Runner

    func runAllTests() {
        testResults.removeAll()
        isRunning = true

        print("\n🧪 ========================================")
        print("🧪 LOGBOOK TEST SUITE - STARTING")
        print("🧪 ========================================\n")

        // Housekeeping functionality tests
        runTest1_Basic3TierDeletion()
        runTest2_EdgeCase90Days()
        runTest3_EdgeCase91Days()
        runTest4_EdgeCase365Days()
        runTest5_EdgeCase366Days()
        runTest6_TasksWithTags()
        runTest7_TasksWithSubtasks()
        runTest8_MultipleHousekeepingRuns()
        runTest9_OverdueTaskArchival()
        runTest10_TaskLogEntryCleanup()
        runTest11_EmptyDatabase()
        runTest12_TasksWithNilCompletionDates()

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

    /// Test 1: Basic 3-Tier Deletion
    private func runTest1_Basic3TierDeletion() {
        currentTest = "Test 1: Basic 3-Tier Deletion"
        let startTime = Date()

        do {
            // Clean database
            try cleanDatabase()

            // Create test tasks
            let tasks = createTestTasks()
            try modelContext.save()

            // Run housekeeping
            let result = logbookManager.performHousekeeping()

            guard case .success(let stats) = result else {
                recordFailure(1, startTime, "Housekeeping failed")
                return
            }

            // Verify results
            let allCompleted = try fetchAllCompletedTasks()
            let allLogEntries = try fetchAllLogEntries()

            let expectedDeleted = 1
            let expectedArchived = 3
            let expectedRemaining = 3

            if stats.tasksDeleted == expectedDeleted &&
               stats.tasksArchived == expectedArchived &&
               allCompleted.count == expectedRemaining &&
               allLogEntries.count == expectedArchived {
                recordSuccess(1, startTime, "Deleted: \(stats.tasksDeleted), Archived: \(stats.tasksArchived), Remaining: \(allCompleted.count)")
            } else {
                recordFailure(1, startTime, "Expected D:\(expectedDeleted)/A:\(expectedArchived)/R:\(expectedRemaining), Got D:\(stats.tasksDeleted)/A:\(stats.tasksArchived)/R:\(allCompleted.count)")
            }
        } catch {
            recordFailure(1, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 2: Edge Case - Exactly 90 Days Old
    private func runTest2_EdgeCase90Days() {
        currentTest = "Test 2: Edge Case - Exactly 90 Days Old"
        let startTime = Date()

        do {
            try cleanDatabase()

            // Create task exactly 90 days old
            let task = createTask(title: "90-Day Task", daysAgo: 90)
            try modelContext.save()

            let result = logbookManager.performHousekeeping()
            guard case .success(let stats) = result else {
                recordFailure(2, startTime, "Housekeeping failed")
                return
            }

            // Should NOT be archived (cutoff is < 91 days)
            if stats.tasksArchived == 0 && stats.tasksDeleted == 0 {
                recordSuccess(2, startTime, "Task correctly remained as full Task object")
            } else {
                recordFailure(2, startTime, "Task was incorrectly archived or deleted")
            }
        } catch {
            recordFailure(2, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 3: Edge Case - Exactly 91 Days Old
    private func runTest3_EdgeCase91Days() {
        currentTest = "Test 3: Edge Case - Exactly 91 Days Old"
        let startTime = Date()

        do {
            try cleanDatabase()

            let task = createTask(title: "91-Day Task", daysAgo: 91)
            try modelContext.save()

            let result = logbookManager.performHousekeeping()
            guard case .success(let stats) = result else {
                recordFailure(3, startTime, "Housekeeping failed")
                return
            }

            // Should be archived
            if stats.tasksArchived == 1 && stats.tasksDeleted == 0 {
                recordSuccess(3, startTime, "Task correctly archived to TaskLogEntry")
            } else {
                recordFailure(3, startTime, "Task was not archived (A:\(stats.tasksArchived) D:\(stats.tasksDeleted))")
            }
        } catch {
            recordFailure(3, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 4: Edge Case - Exactly 365 Days Old
    private func runTest4_EdgeCase365Days() {
        currentTest = "Test 4: Edge Case - Exactly 365 Days Old"
        let startTime = Date()

        do {
            try cleanDatabase()

            let task = createTask(title: "365-Day Task", daysAgo: 365)
            try modelContext.save()

            let result = logbookManager.performHousekeeping()
            guard case .success(let stats) = result else {
                recordFailure(4, startTime, "Housekeeping failed")
                return
            }

            // Should be archived (cutoff is >= 365 for archival)
            if stats.tasksArchived == 1 && stats.tasksDeleted == 0 {
                recordSuccess(4, startTime, "Task correctly archived at 365-day boundary")
            } else {
                recordFailure(4, startTime, "Task handling incorrect (A:\(stats.tasksArchived) D:\(stats.tasksDeleted))")
            }
        } catch {
            recordFailure(4, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 5: Edge Case - Exactly 366 Days Old
    private func runTest5_EdgeCase366Days() {
        currentTest = "Test 5: Edge Case - Exactly 366 Days Old"
        let startTime = Date()

        do {
            try cleanDatabase()

            let task = createTask(title: "366-Day Task", daysAgo: 366)
            try modelContext.save()

            let result = logbookManager.performHousekeeping()
            guard case .success(let stats) = result else {
                recordFailure(5, startTime, "Housekeeping failed")
                return
            }

            // Should be deleted entirely
            if stats.tasksDeleted == 1 && stats.tasksArchived == 0 {
                recordSuccess(5, startTime, "Task correctly deleted (no archive)")
            } else {
                recordFailure(5, startTime, "Task should be deleted (A:\(stats.tasksArchived) D:\(stats.tasksDeleted))")
            }
        } catch {
            recordFailure(5, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 6: Tasks with Tags
    private func runTest6_TasksWithTags() {
        currentTest = "Test 6: Tasks with Tags"
        let startTime = Date()

        do {
            try cleanDatabase()

            // Create tags
            let tag1 = Tag(name: "Work", sfSymbolName: "briefcase", colorName: "red")
            let tag2 = Tag(name: "Urgent", sfSymbolName: "exclamationmark", colorName: "green")
            let tag3 = Tag(name: "Important", sfSymbolName: "star", colorName: "blue")
            modelContext.insert(tag1)
            modelContext.insert(tag2)
            modelContext.insert(tag3)

            let task = createTask(title: "Tagged Task", daysAgo: 100)
            task.tags = [tag1, tag2, tag3]
            try modelContext.save()

            let result = logbookManager.performHousekeeping()
            guard case .success = result else {
                recordFailure(6, startTime, "Housekeeping failed")
                return
            }

            // Check TaskLogEntry has tag names
            let logEntries = try fetchAllLogEntries()
            if let entry = logEntries.first,
               entry.tagNames.count == 3 &&
               entry.tagNames.contains("Work") &&
               entry.tagNames.contains("Urgent") &&
               entry.tagNames.contains("Important") {
                recordSuccess(6, startTime, "Tag names correctly stored: \(entry.tagNames.joined(separator: ", "))")
            } else {
                recordFailure(6, startTime, "Tag names not properly stored")
            }
        } catch {
            recordFailure(6, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 7: Tasks with Subtasks
    private func runTest7_TasksWithSubtasks() {
        currentTest = "Test 7: Tasks with Subtasks"
        let startTime = Date()

        do {
            try cleanDatabase()

            let parent = createTask(title: "Parent Task", daysAgo: 120)
            let sub1 = parent.createSubtask(title: "Subtask 1")
            let sub2 = parent.createSubtask(title: "Subtask 2")
            let sub3 = parent.createSubtask(title: "Subtask 3")

            // Mark subtasks as completed and set completion dates
            sub1.setCompleted(true)
            sub2.setCompleted(true)
            sub3.setCompleted(true)
            if let date = Calendar.current.date(byAdding: .day, value: -120, to: Date()) {
                sub1.completedDate = date
                sub2.completedDate = date
                sub3.completedDate = date
            }

            try modelContext.save()

            let result = logbookManager.performHousekeeping()
            guard case .success(let stats) = result else {
                recordFailure(7, startTime, "Housekeeping failed")
                return
            }

            // Should have 4 archived entries (1 parent + 3 subtasks)
            let logEntries = try fetchAllLogEntries()
            let parentEntry = logEntries.first { !$0.wasSubtask }
            let subtaskEntries = logEntries.filter { $0.wasSubtask }

            if stats.tasksArchived == 4 &&
               parentEntry?.subtaskCount == 3 &&
               subtaskEntries.count == 3 &&
               subtaskEntries.allSatisfy({ $0.parentTaskTitle == "Parent Task" }) {
                recordSuccess(7, startTime, "Parent + 3 subtasks correctly archived")
            } else {
                recordFailure(7, startTime, "Subtask archival incorrect (Archived: \(stats.tasksArchived), Entries: \(logEntries.count))")
            }
        } catch {
            recordFailure(7, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 8: Multiple Housekeeping Runs
    private func runTest8_MultipleHousekeepingRuns() {
        currentTest = "Test 8: Multiple Housekeeping Runs"
        let startTime = Date()

        do {
            try cleanDatabase()

            let task = createTask(title: "Test Task", daysAgo: 100)
            try modelContext.save()

            // First run
            let result1 = logbookManager.performHousekeeping()
            guard case .success(let stats1) = result1 else {
                recordFailure(8, startTime, "First housekeeping failed")
                return
            }

            // Second run (should do nothing)
            let result2 = logbookManager.performHousekeeping()
            guard case .success(let stats2) = result2 else {
                recordFailure(8, startTime, "Second housekeeping failed")
                return
            }

            if stats1.tasksArchived == 1 &&
               stats2.tasksArchived == 0 &&
               stats2.tasksDeleted == 0 &&
               stats2.logsDeleted == 0 {
                recordSuccess(8, startTime, "Second run correctly did nothing")
            } else {
                recordFailure(8, startTime, "Second run performed unexpected operations")
            }
        } catch {
            recordFailure(8, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 9: Overdue Task Archival
    private func runTest9_OverdueTaskArchival() {
        currentTest = "Test 9: Overdue Task Archival"
        let startTime = Date()

        do {
            try cleanDatabase()

            let task = createTask(title: "Overdue Task", daysAgo: 120)
            // Set due date to 130 days ago (completed 10 days late)
            task.dueDate = Calendar.current.date(byAdding: .day, value: -130, to: Date())
            try modelContext.save()

            let result = logbookManager.performHousekeeping()
            guard case .success = result else {
                recordFailure(9, startTime, "Housekeeping failed")
                return
            }

            let logEntries = try fetchAllLogEntries()
            if let entry = logEntries.first,
               entry.wasOverdue {
                recordSuccess(9, startTime, "Overdue status correctly captured")
            } else {
                recordFailure(9, startTime, "Overdue status not captured")
            }
        } catch {
            recordFailure(9, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 10: TaskLogEntry Cleanup (365+ days)
    private func runTest10_TaskLogEntryCleanup() {
        currentTest = "Test 10: TaskLogEntry Cleanup"
        let startTime = Date()

        do {
            try cleanDatabase()

            // Create old TaskLogEntry directly
            let oldDate = Calendar.current.date(byAdding: .day, value: -370, to: Date())!
            let entry = TaskLogEntry(
                originalTaskId: UUID(),
                title: "Old Log Entry",
                taskDescription: "",
                completedDate: oldDate,
                createdDate: oldDate,
                dueDate: nil,
                priority: .none,
                wasOverdue: false,
                subtaskCount: 0,
                completedSubtaskCount: 0,
                wasSubtask: false,
                parentTaskTitle: nil,
                tagNames: [],
                completionDuration: 100
            )
            modelContext.insert(entry)
            try modelContext.save()

            let result = logbookManager.performHousekeeping()
            guard case .success(let stats) = result else {
                recordFailure(10, startTime, "Housekeeping failed")
                return
            }

            if stats.logsDeleted == 1 {
                recordSuccess(10, startTime, "Old log entry correctly deleted")
            } else {
                recordFailure(10, startTime, "Log entry not deleted (Deleted: \(stats.logsDeleted))")
            }
        } catch {
            recordFailure(10, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 11: Empty Database
    private func runTest11_EmptyDatabase() {
        currentTest = "Test 11: Empty Database"
        let startTime = Date()

        do {
            try cleanDatabase()

            let result = logbookManager.performHousekeeping()
            guard case .success(let stats) = result else {
                recordFailure(11, startTime, "Housekeeping failed")
                return
            }

            if stats.tasksArchived == 0 &&
               stats.tasksDeleted == 0 &&
               stats.logsDeleted == 0 {
                recordSuccess(11, startTime, "Empty database handled correctly")
            } else {
                recordFailure(11, startTime, "Unexpected operations on empty database")
            }
        } catch {
            recordFailure(11, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    /// Test 12: Tasks with Nil Completion Dates
    private func runTest12_TasksWithNilCompletionDates() {
        currentTest = "Test 12: Tasks with Nil Completion Dates"
        let startTime = Date()

        do {
            try cleanDatabase()

            // Create incomplete tasks
            let task1 = Task(title: "Incomplete Task 1")
            let task2 = Task(title: "Incomplete Task 2")
            modelContext.insert(task1)
            modelContext.insert(task2)
            try modelContext.save()

            let result = logbookManager.performHousekeeping()
            guard case .success(let stats) = result else {
                recordFailure(12, startTime, "Housekeeping failed")
                return
            }

            // Incomplete tasks should be ignored
            if stats.tasksArchived == 0 && stats.tasksDeleted == 0 {
                recordSuccess(12, startTime, "Incomplete tasks correctly ignored")
            } else {
                recordFailure(12, startTime, "Incomplete tasks incorrectly processed")
            }
        } catch {
            recordFailure(12, startTime, "Exception: \(error.localizedDescription)")
        }
    }

    // MARK: - Helper Methods

    private func cleanDatabase() throws {
        // Delete all tasks
        let taskDescriptor = FetchDescriptor<Task>()
        let allTasks = try modelContext.fetch(taskDescriptor)
        for task in allTasks {
            modelContext.delete(task)
        }

        // Delete all log entries
        let logDescriptor = FetchDescriptor<TaskLogEntry>()
        let allLogs = try modelContext.fetch(logDescriptor)
        for log in allLogs {
            modelContext.delete(log)
        }

        // Delete all tags
        let tagDescriptor = FetchDescriptor<Tag>()
        let allTags = try modelContext.fetch(tagDescriptor)
        for tag in allTags {
            modelContext.delete(tag)
        }

        try modelContext.save()
    }

    private func createTask(title: String, daysAgo: Int) -> Task {
        let task = Task(title: title)
        task.setCompleted(true)

        if let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) {
            task.completedDate = date
            task.createdDate = Calendar.current.date(byAdding: .day, value: -(daysAgo + 5), to: Date()) ?? date
        }

        modelContext.insert(task)
        return task
    }

    private func createTestTasks() -> [Task] {
        let tasks = [
            createTask(title: "Recent Task (30 days old)", daysAgo: 30),
            createTask(title: "Medium Task (60 days old)", daysAgo: 60),
            createTask(title: "Edge Task (85 days old)", daysAgo: 85),
            createTask(title: "Old Task (120 days old)", daysAgo: 120),
            createTask(title: "Ancient Task (370 days old)", daysAgo: 370),
            createTask(title: "Parent Task (100 days old)", daysAgo: 100)
        ]

        // Add subtask to parent
        let subtask = tasks[5].createSubtask(title: "Subtask (100 days old)")
        subtask.setCompleted(true)
        if let date = Calendar.current.date(byAdding: .day, value: -100, to: Date()) {
            subtask.completedDate = date
        }
        modelContext.insert(subtask)

        return tasks
    }

    private func fetchAllCompletedTasks() throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate<Task> { $0.isCompleted }
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchAllLogEntries() throws -> [TaskLogEntry] {
        let descriptor = FetchDescriptor<TaskLogEntry>()
        return try modelContext.fetch(descriptor)
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
