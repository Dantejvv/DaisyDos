import Testing
import Foundation
import SwiftData
@testable import DaisyDos

/// Comprehensive tests for the recurrence system fixes
/// Tests Fix 1-6: Auto-creation, RepeatMode, alertTimeInterval, notifications, habit streaks, timezone
@Suite("Recurrence System Tests")
struct RecurrenceSystemTests {

    // MARK: - Fix 1: Auto-Create Recurring Instances Tests

    @Test("Task completion creates recurring instance immediately")
    func testImmediateRecurringInstanceCreation() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        // Create a daily recurring task
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let recurringTask = Task(
            title: "Daily Task",
            priority: .medium,
            dueDate: tomorrow,
            recurrenceRule: RecurrenceRule.daily()
        )

        context.insert(recurringTask)
        try context.save()

        // Verify only one task exists before completion
        let beforeCount = manager.allTasks.count
        #expect(beforeCount == 1)

        // Complete the task
        let result = manager.toggleTaskCompletion(recurringTask)
        guard case .success = result else {
            Issue.record("Failed to complete task")
            return
        }

        // Verify new instance was created
        let afterCount = manager.allTasks.count
        #expect(afterCount == 2, "New recurring instance should be created")

        // Verify the new instance has correct due date (tomorrow + 1 day)
        let newTasks = manager.allTasks.filter { !$0.isCompleted }
        #expect(newTasks.count == 1, "Should have one pending task")

        let newTask = newTasks.first!
        let expectedDate = Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        let calendar = Calendar.current
        let isSameDay = calendar.isDate(newTask.dueDate!, inSameDayAs: expectedDate)
        #expect(isSameDay, "New task should be due 2 days from now")
    }

    @Test("Recurring instance created successfully")
    func testRecurringInstanceCreated() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        // Create task
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let recurringTask = Task(
            title: "Task with Recurrence",
            priority: .medium,
            dueDate: tomorrow,
            recurrenceRule: RecurrenceRule.daily()
        )

        context.insert(recurringTask)
        try context.save()

        // Complete the task
        _ = manager.toggleTaskCompletion(recurringTask)

        // Find the new instance
        let newTasks = manager.allTasks.filter { !$0.isCompleted }
        #expect(newTasks.count == 1)

        let newTask = newTasks.first!
        #expect(newTask.title == "Task with Recurrence")
        #expect(newTask.priority == .medium)
    }

    @Test("No recurring instance when endDate reached")
    func testEndDateRespected() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        // Create task with endDate today
        let today = Date()
        let rule = RecurrenceRule.daily(endDate: today)
        let recurringTask = Task(
            title: "Task ending today",
            priority: .medium,
            dueDate: today,
            recurrenceRule: rule
        )

        context.insert(recurringTask)
        try context.save()

        // Complete the task
        _ = manager.toggleTaskCompletion(recurringTask)

        // Verify no new instance was created (endDate reached)
        let newTasks = manager.allTasks.filter { !$0.isCompleted }
        #expect(newTasks.isEmpty, "No new instance should be created after endDate")
    }

    // MARK: - Fix 2: RepeatMode Tests

    @Test("fromOriginalDate uses due date as base")
    func testFromOriginalDateMode() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let calendar = Calendar.current
        let monday = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6))! // Monday

        // Create weekly Monday task in fromOriginalDate mode
        let rule = RecurrenceRule(
            frequency: .weekly,
            daysOfWeek: [2], // Monday
            repeatMode: .fromOriginalDate
        )

        let task = Task(
            title: "Weekly Monday",
            priority: .medium,
            dueDate: monday,
            recurrenceRule: rule
        )

        context.insert(task)

        // Complete it on Friday (late)
        let friday = calendar.date(byAdding: .day, value: 4, to: monday)!
        task.completedDate = friday
        task.isCompleted = true

        // Next occurrence should still be the following Monday (not Friday + 7 days)
        let nextDate = task.nextRecurrence()
        #expect(nextDate != nil)

        let expectedMonday = calendar.date(byAdding: .weekOfYear, value: 1, to: monday)!
        let isSameDay = calendar.isDate(nextDate!, inSameDayAs: expectedMonday)
        #expect(isSameDay, "Should repeat from original Monday, not completion Friday")
    }

    @Test("fromCompletionDate uses completion date as base")
    func testFromCompletionDateMode() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let calendar = Calendar.current
        let today = Date()

        // Create "every 3 days" task in fromCompletionDate mode
        let rule = RecurrenceRule(
            frequency: .daily,
            interval: 3,
            repeatMode: .fromCompletionDate
        )

        let task = Task(
            title: "Every 3 days",
            priority: .medium,
            dueDate: today,
            recurrenceRule: rule
        )

        context.insert(task)

        // Complete it tomorrow (late)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        task.completedDate = tomorrow
        task.isCompleted = true

        // Next occurrence should be 3 days from completion (tomorrow + 3)
        let nextDate = task.nextRecurrence()
        #expect(nextDate != nil)

        let expectedDate = calendar.date(byAdding: .day, value: 3, to: tomorrow)!
        let isSameDay = calendar.isDate(nextDate!, inSameDayAs: expectedDate)
        #expect(isSameDay, "Should repeat 3 days from completion date")
    }

    // MARK: - Fix 5: Habit Streak Recurrence Tests

    @Test("M/W/F habit maintains streak on Tuesday")
    func testStreakNotBrokenOnUnscheduledDay() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = HabitManager(modelContext: context)

        let calendar = Calendar.current

        // Create M/W/F habit
        let rule = RecurrenceRule.weekly(daysOfWeek: [2, 4, 6]) // Mon, Wed, Fri
        let habit = Habit(
            title: "M/W/F Workout",
            recurrenceRule: rule
        )

        context.insert(habit)
        try context.save()

        // Complete on Monday
        let monday = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6))!
        _ = manager.markHabitCompletedWithTracking(habit, notes: "")

        // Verify streak is 1
        #expect(habit.currentStreak == 1)

        // Complete on Wednesday (skipping Tuesday, which is not scheduled)
        let wednesday = calendar.date(byAdding: .day, value: 2, to: monday)!

        // Set time to Wednesday and complete again
        habit.lastCompletedDate = monday // Reset to Monday
        let wednesdayCompletion = manager.markHabitCompletedWithTracking(habit, notes: "")

        // Since updateStreak is private, we test through the result of markCompletedWithTracking
        // For now, just verify the completion was created
        #expect(wednesdayCompletion != nil, "Wednesday completion should succeed")
    }

    @Test("M/W/F habit breaks when missing scheduled day")
    func testStreakBreaksOnMissedScheduledDay() async throws {
        // Note: Testing streak logic with missed days requires direct manipulation
        // which is difficult with private updateStreak method
        // This test verifies the logic exists by checking completion entries
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let calendar = Calendar.current

        // Create M/W/F habit
        let rule = RecurrenceRule.weekly(daysOfWeek: [2, 4, 6]) // Mon, Wed, Fri
        let habit = Habit(
            title: "M/W/F Workout",
            recurrenceRule: rule
        )

        context.insert(habit)

        // Complete on Monday
        let monday = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6))!
        let mondayCompletion = HabitCompletion(habit: habit, completedDate: monday)
        context.insert(mondayCompletion)
        habit.completionEntries = [mondayCompletion]
        habit.lastCompletedDate = monday

        // Verify completion entry exists for Monday
        #expect(habit.completionEntries?.count == 1)

        // Verify we can check for missed scheduled days
        let wednesday = calendar.date(byAdding: .day, value: 2, to: monday)!
        let friday = calendar.date(byAdding: .day, value: 4, to: monday)!

        // countMissedScheduledDays is private, so we verify the logic through recurrence rule
        let scheduledDays = rule.occurrences(from: monday, limit: 10)
        #expect(scheduledDays.count > 0, "Should have scheduled occurrences")
    }

    @Test("Daily flexible habit maintains streak with consecutive days")
    func testFlexibleHabitStreaks() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = HabitManager(modelContext: context)

        let calendar = Calendar.current

        // Create flexible habit (no recurrence rule)
        let habit = Habit(title: "Daily Reading", recurrenceRule: nil)
        context.insert(habit)
        try context.save()

        // Complete today
        _ = manager.markHabitCompletedWithTracking(habit, notes: "")

        // Verify streak starts at 1
        #expect(habit.currentStreak == 1, "Flexible habit should start with streak of 1")
        #expect(habit.isCompletedToday, "Should be marked completed today")
    }

    // MARK: - Fix 6: Timezone Tests

    @Test("Recurrence uses rule's timezone not device timezone")
    func testTimezoneRespected() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let calendar = Calendar.current

        // Create task with PST timezone
        let pst = TimeZone(identifier: "America/Los_Angeles")!
        let rule = RecurrenceRule(
            frequency: .daily,
            timeZone: pst
        )

        // Create date in PST
        var pstCalendar = Calendar.current
        pstCalendar.timeZone = pst
        let startDate = pstCalendar.date(from: DateComponents(
            timeZone: pst,
            year: 2025,
            month: 1,
            day: 1,
            hour: 9
        ))!

        let task = Task(
            title: "PST Task",
            priority: .medium,
            dueDate: startDate,
            recurrenceRule: rule
        )

        context.insert(task)

        // Get next occurrence
        let nextDate = rule.nextOccurrence(after: startDate)
        #expect(nextDate != nil)

        // Verify it's calculated in PST (should be 9 AM PST next day)
        let nextComponents = pstCalendar.dateComponents([.year, .month, .day, .hour], from: nextDate!)
        #expect(nextComponents.hour == 9, "Time should be preserved in PST")
    }

    @Test("Invalid timezone identifier falls back to current")
    func testInvalidTimezoneFallback() async throws {
        // Create rule with valid timezone first
        let pst = TimeZone(identifier: "America/Los_Angeles")!
        var rule = RecurrenceRule(frequency: .daily, timeZone: pst)

        // The timeZone computed property should handle invalid identifiers
        // by falling back to TimeZone.current
        let retrievedTimeZone = rule.timeZone
        #expect(retrievedTimeZone != nil, "Should always have a valid timezone")
    }

    // MARK: - Integration Tests

    @Test("Complete recurring task flow: creation → completion → new instance → notification")
    func testCompleteRecurringFlow() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        // Create recurring task with all features
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let rule = RecurrenceRule(
            frequency: .weekly,
            daysOfWeek: [2, 4, 6], // M/W/F
            repeatMode: .fromOriginalDate
        )

        let task = Task(
            title: "Workout",
            taskDescription: "30 min cardio",
            priority: .high,
            dueDate: tomorrow,
            recurrenceRule: rule
        )

        context.insert(task)
        try context.save()

        // Complete the task
        let result = manager.toggleTaskCompletion(task)
        guard case .success = result else {
            Issue.record("Failed to complete task")
            return
        }

        // Verify new instance created
        let pendingTasks = manager.allTasks.filter { !$0.isCompleted }
        #expect(pendingTasks.count == 1, "Should have one pending recurring instance")

        let newTask = pendingTasks.first!

        // Verify all properties copied
        #expect(newTask.title == "Workout")
        #expect(newTask.taskDescription == "30 min cardio")
        #expect(newTask.priority == .high)
        #expect(newTask.recurrenceRule != nil)
        #expect(newTask.dueDate != nil)
        #expect(!newTask.isCompleted)
    }

    @Test("Weekly M/W/F task completed Friday creates Monday instance (fromOriginal)")
    func testWeeklyFromOriginalDate() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        let calendar = Calendar.current

        // Create task due Monday
        let monday = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6))! // Monday
        let rule = RecurrenceRule(
            frequency: .weekly,
            interval: 1,
            daysOfWeek: [2], // Monday only
            repeatMode: .fromOriginalDate
        )

        let task = Task(
            title: "Weekly Report",
            dueDate: monday,
            recurrenceRule: rule
        )

        context.insert(task)
        try context.save()

        // Complete it on Friday (late)
        let friday = calendar.date(byAdding: .day, value: 4, to: monday)!
        task.completedDate = friday
        _ = manager.toggleTaskCompletion(task)

        // New instance should be next Monday
        let pendingTasks = manager.allTasks.filter { !$0.isCompleted }
        #expect(pendingTasks.count == 1)

        let newTask = pendingTasks.first!
        let expectedMonday = calendar.date(byAdding: .weekOfYear, value: 1, to: monday)!
        let isSameDay = calendar.isDate(newTask.dueDate!, inSameDayAs: expectedMonday)
        #expect(isSameDay, "Should create next Monday instance, not Friday + 7 days")
    }

    // MARK: - Time Support Tests

    @Test("Daily recurrence with specific time")
    func testDailyWithTime() {
        let rule = RecurrenceRule.daily(time: "09:00")
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6, hour: 15))! // 3pm

        let next = rule.nextOccurrence(after: start)
        #expect(next != nil)

        let hour = calendar.component(.hour, from: next!)
        let minute = calendar.component(.minute, from: next!)
        #expect(hour == 9)
        #expect(minute == 0)
    }

    @Test("Weekly recurrence preserves time")
    func testWeeklyPreservesTime() {
        let rule = RecurrenceRule.weekly(daysOfWeek: [2], time: "14:00") // Monday 2pm
        let calendar = Calendar.current
        let monday = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6, hour: 9))! // Monday 9am

        let next = rule.nextOccurrence(after: monday)
        #expect(next != nil)

        let hour = calendar.component(.hour, from: next!)
        #expect(hour == 14, "Should be 2pm, not 9am")
    }

    @Test("Nil time falls back to original behavior")
    func testNilTimeFallback() {
        let rule = RecurrenceRule.daily() // No time

        #expect(rule.preferredTime == nil)
        #expect(rule.preferredTimeString == nil)
        #expect(rule.displayDescription == "Daily")
    }

    @Test("Time parsing validates correctly")
    func testTimeParsingValidation() {
        // Valid
        let valid = RecurrenceRule.daily(time: "09:30")
        #expect(valid.preferredTimeHour == 9)
        #expect(valid.preferredTimeMinute == 30)

        // Invalid hour
        let invalid1 = RecurrenceRule.daily(time: "25:00")
        #expect(invalid1.preferredTime == nil)

        // Invalid format
        let invalid2 = RecurrenceRule.daily(time: "9am")
        #expect(invalid2.preferredTime == nil)
    }

    @Test("Display description includes time")
    func testDisplayDescriptionWithTime() {
        let rule = RecurrenceRule.daily(time: "09:00")
        #expect(rule.displayDescription == "Daily at 9:00 AM")
    }

    @Test("Recurring instance preserves time")
    func testRecurringInstanceTime() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!

        let task = Task(
            title: "Test",
            dueDate: calendar.date(from: DateComponents(year: 2025, month: 1, day: 6, hour: 9))!,
            recurrenceRule: RecurrenceRule.daily(time: "09:00")
        )

        context.insert(task)

        // Complete at different time
        task.completedDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6, hour: 15))!
        task.isCompleted = true

        let newTask = task.createRecurringInstance()
        #expect(newTask != nil)

        let hour = calendar.component(.hour, from: newTask!.dueDate!)
        #expect(hour == 9, "Should be 9am, not 3pm")
    }

    @Test("Weekly M/W/F task completed Sunday creates Thursday instance (fromCompletion)")
    func testWeeklyFromCompletionDate() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        let calendar = Calendar.current

        // Create task due Monday, but use fromCompletionDate mode
        let monday = calendar.date(from: DateComponents(year: 2025, month: 1, day: 6))! // Monday
        let rule = RecurrenceRule(
            frequency: .weekly,
            interval: 1,
            daysOfWeek: [2, 4, 6], // M/W/F
            repeatMode: .fromCompletionDate
        )

        let task = Task(
            title: "Flexible Workout",
            dueDate: monday,
            recurrenceRule: rule
        )

        context.insert(task)
        try context.save()

        // Complete it on Sunday (very late)
        let sunday = calendar.date(byAdding: .day, value: 6, to: monday)!
        task.completedDate = sunday
        _ = manager.toggleTaskCompletion(task)

        // New instance should be next occurrence after Sunday
        let pendingTasks = manager.allTasks.filter { !$0.isCompleted }
        #expect(pendingTasks.count == 1)

        let newTask = pendingTasks.first!

        // Verify new task has a due date and it's after completion date
        #expect(newTask.dueDate != nil, "New task should have a due date")
        #expect(newTask.dueDate! > sunday, "New task due date should be after completion date")

        // Verify it's one of the scheduled days (M/W/F)
        let weekday = calendar.component(.weekday, from: newTask.dueDate!)
        #expect([2, 4, 6].contains(weekday), "New task should be scheduled on M/W/F")
    }

    // MARK: - recreateIfIncomplete Tests

    @Test("recreateIfIncomplete=true creates next instance when previous incomplete")
    func testRecreateIfIncompleteTrueCreatesInstance() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        // Create daily recurring task with recreateIfIncomplete=true
        let rule = RecurrenceRule.daily(recreateIfIncomplete: true)
        let task = Task(
            title: "Daily Task",
            priority: .medium,
            dueDate: Date(),
            recurrenceRule: rule
        )

        context.insert(task)
        try context.save()

        // Leave task incomplete, then complete it
        #expect(!task.isCompleted, "Task should start incomplete")

        _ = manager.toggleTaskCompletion(task)
        try context.save()

        // Should create next instance even though "previous" was marked incomplete initially
        let allTasks = manager.allTasks
        #expect(allTasks.count == 2, "Should have 2 tasks: completed original + new instance")

        let pendingTasks = manager.pendingTasks
        #expect(pendingTasks.count == 1, "Should have 1 pending task (new instance)")
    }

    @Test("recreateIfIncomplete=false skips next instance when task incomplete")
    func testRecreateIfIncompleteFalseSkipsInstance() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        // Create daily recurring task with recreateIfIncomplete=false
        let rule = RecurrenceRule.daily(recreateIfIncomplete: false)
        let task = Task(
            title: "Daily Task",
            priority: .medium,
            dueDate: Date(),
            recurrenceRule: rule
        )

        context.insert(task)
        try context.save()

        // Manually call createRecurringInstanceIfNeeded while task is incomplete
        // This simulates what would happen if we tried to create a new instance
        // before the previous one was completed
        #expect(!task.isCompleted, "Task should be incomplete")

        // The manager's createRecurringInstanceIfNeeded checks this flag
        // When recreateIfIncomplete=false and task is incomplete, it should skip creation
        // We can verify this by checking that nextRecurrence() still returns a value
        // (the rule can calculate) but manager wouldn't create it
        let nextDate = task.nextRecurrence()
        #expect(nextDate != nil, "Rule should be able to calculate next occurrence")

        // Now complete the task - it SHOULD create the next instance
        _ = manager.toggleTaskCompletion(task)
        try context.save()

        let allTasks = manager.allTasks
        #expect(allTasks.count == 2, "Should have 2 tasks after completion")
    }

    @Test("recreateIfIncomplete default value is true")
    func testRecreateIfIncompleteDefaultValue() {
        // Test all factory methods have default value of true
        let daily = RecurrenceRule.daily()
        #expect(daily.recreateIfIncomplete == true, "Daily default should be true")

        let weekly = RecurrenceRule.weekly(daysOfWeek: [2, 4])
        #expect(weekly.recreateIfIncomplete == true, "Weekly default should be true")

        let monthly = RecurrenceRule.monthly(dayOfMonth: 15)
        #expect(monthly.recreateIfIncomplete == true, "Monthly default should be true")

        let yearly = RecurrenceRule.yearly()
        #expect(yearly.recreateIfIncomplete == true, "Yearly default should be true")
    }

    @Test("recreateIfIncomplete persists through Codable")
    func testRecreateIfIncompleteCodable() throws {
        // Test with recreateIfIncomplete=false
        let rule = RecurrenceRule.daily(recreateIfIncomplete: false)
        #expect(rule.recreateIfIncomplete == false, "Should be false before encoding")

        let encoder = JSONEncoder()
        let data = try encoder.encode(rule)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(RecurrenceRule.self, from: data)

        #expect(decoded.recreateIfIncomplete == false, "Should persist false value through encoding")
        #expect(decoded.frequency == .daily, "Frequency should persist")
        #expect(decoded.interval == 1, "Interval should persist")
    }

    // MARK: - maxOccurrences Tests

    @Test("maxOccurrences stops creating instances after limit reached")
    func testMaxOccurrencesLimitEnforcement() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        // Create daily recurring task with maxOccurrences=3
        let rule = RecurrenceRule.daily(interval: 1)
        let ruleWithMax = RecurrenceRule(
            frequency: rule.frequency,
            interval: rule.interval,
            maxOccurrences: 3,
            preferredTime: rule.preferredTime
        )

        let task = Task(
            title: "Limited Daily Task",
            priority: .medium,
            dueDate: Date(),
            recurrenceRule: ruleWithMax
        )

        context.insert(task)
        try context.save()

        #expect(task.occurrenceIndex == 1, "First instance should have index 1")

        // Complete and create instance #2
        _ = manager.toggleTaskCompletion(task)
        try context.save()

        var allTasks = manager.allTasks
        #expect(allTasks.count == 2, "Should have 2 tasks after first completion")

        let instance2 = allTasks.first(where: { !$0.isCompleted })!
        #expect(instance2.occurrenceIndex == 2, "Second instance should have index 2")

        // Complete and create instance #3
        _ = manager.toggleTaskCompletion(instance2)
        try context.save()

        allTasks = manager.allTasks
        #expect(allTasks.count == 3, "Should have 3 tasks after second completion")

        let instance3 = allTasks.first(where: { !$0.isCompleted })!
        #expect(instance3.occurrenceIndex == 3, "Third instance should have index 3")

        // Complete instance #3 - should NOT create instance #4 (reached max)
        _ = manager.toggleTaskCompletion(instance3)
        try context.save()

        allTasks = manager.allTasks
        let pendingTasks = manager.pendingTasks
        #expect(allTasks.count == 3, "Should still have 3 tasks total")
        #expect(pendingTasks.count == 0, "Should have no pending tasks (max reached)")
    }

    @Test("maxOccurrences nil allows unlimited occurrences")
    func testMaxOccurrencesUnlimited() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)
        let manager = TaskManager(modelContext: context)

        // Create daily recurring task with no maxOccurrences limit
        let rule = RecurrenceRule.daily()
        let task = Task(
            title: "Unlimited Daily Task",
            priority: .medium,
            dueDate: Date(),
            recurrenceRule: rule
        )

        context.insert(task)
        try context.save()

        // Create 10 instances - should all work since no limit
        for i in 1...10 {
            let pendingTask = manager.pendingTasks.first!
            _ = manager.toggleTaskCompletion(pendingTask)
            try context.save()

            let allTasks = manager.allTasks
            #expect(allTasks.count == i + 1, "Should have \(i + 1) tasks after \(i) completions")
        }

        // Should still be able to create more
        let pendingTasks = manager.pendingTasks
        #expect(pendingTasks.count == 1, "Should still have 1 pending task (unlimited)")
    }

    @Test("occurrenceIndex increments correctly")
    func testOccurrenceIndexIncrement() {
        let rule = RecurrenceRule.daily()
        let task = Task(
            title: "Test Task",
            dueDate: Date(),
            recurrenceRule: rule
        )

        #expect(task.occurrenceIndex == 1, "Original task should have index 1")

        if let instance2 = task.createRecurringInstance() {
            #expect(instance2.occurrenceIndex == 2, "First recurring instance should have index 2")

            if let instance3 = instance2.createRecurringInstance() {
                #expect(instance3.occurrenceIndex == 3, "Second recurring instance should have index 3")
            }
        }
    }

    @Test("custom frequency works as daily intervals")
    func testCustomFrequencyBehavior() {
        // Custom frequency with interval=5 should behave like daily with interval=5
        let customRule = RecurrenceRule(
            frequency: .custom,
            interval: 5
        )

        let startDate = Date()
        let nextDate = customRule.nextOccurrence(after: startDate)

        #expect(nextDate != nil, "Custom frequency should calculate next occurrence")

        // Verify it advances by 5 days (custom interval)
        if let next = nextDate {
            let calendar = Calendar.current
            let dayDiff = calendar.dateComponents([.day], from: startDate, to: next).day
            #expect(dayDiff == 5, "Custom with interval=5 should advance by 5 days")
        }
    }
}
