//
//  NotificationGroupTests.swift
//  DaisyDosTests
//
//  Created by Claude Code on 12/22/25.
//

import Testing
import Foundation
import SwiftData
@testable import DaisyDos

@Suite("Notification Group Tests")
struct NotificationGroupTests {

    // MARK: - Task Grouping Tests

    @Test("High priority task uses high-priority group")
    func testHighPriorityTaskGrouping() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let task = Task(
            title: "Urgent task",
            priority: .high,
            dueDate: Date().addingTimeInterval(3600) // 1 hour from now
        )
        context.insert(task)

        let group = NotificationGroup.forTask(task)

        #expect(group == .highPriorityTasks)
        #expect(group.threadIdentifier == "task-high-priority")
    }

    @Test("Task due today uses due-today group")
    func testDueTodayTaskGrouping() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        // Create task due today (medium priority)
        let task = Task(
            title: "Task due today",
            priority: .medium,
            dueDate: Date() // Due now (today)
        )
        context.insert(task)

        let group = NotificationGroup.forTask(task)

        #expect(group == .dueTodayTasks)
        #expect(group.threadIdentifier == "task-due-today")
    }

    @Test("Overdue task uses overdue group")
    func testOverdueTaskGrouping() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        // Create overdue task (due in the past)
        let task = Task(
            title: "Overdue task",
            priority: .low,
            dueDate: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        context.insert(task)

        let group = NotificationGroup.forTask(task)

        #expect(group == .overdueTasksReminders)
        #expect(group.threadIdentifier == "task-overdue")
    }

    @Test("Regular task with no special conditions uses ungrouped")
    func testRegularTaskGrouping() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        // Task due tomorrow, medium priority
        let task = Task(
            title: "Regular task",
            priority: .medium,
            dueDate: Date().addingTimeInterval(86400) // Tomorrow
        )
        context.insert(task)

        let group = NotificationGroup.forTask(task)

        #expect(group == .ungrouped)
        #expect(group.threadIdentifier == nil)
    }

    @Test("High priority overrides due today grouping")
    func testHighPriorityOverridesDueToday() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        // High priority task due today
        let task = Task(
            title: "High priority task due today",
            priority: .high,
            dueDate: Date()
        )
        context.insert(task)

        let group = NotificationGroup.forTask(task)

        // High priority takes precedence
        #expect(group == .highPriorityTasks)
    }

    // MARK: - Habit Grouping Tests

    @Test("Morning habit (8 AM) uses morning group")
    func testMorningHabitGrouping() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        // 8 AM = 8 * 3600 = 28800 seconds since midnight
        let habit = Habit(title: "Morning meditation")
        habit.alertTimeInterval = 28800
        context.insert(habit)

        let group = NotificationGroup.forHabit(habit)

        #expect(group == .morningHabits)
        #expect(group.threadIdentifier == "habit-morning")
    }

    @Test("Afternoon habit (2 PM) uses afternoon group")
    func testAfternoonHabitGrouping() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        // 2 PM = 14 * 3600 = 50400 seconds since midnight
        let habit = Habit(title: "Afternoon walk")
        habit.alertTimeInterval = 50400
        context.insert(habit)

        let group = NotificationGroup.forHabit(habit)

        #expect(group == .afternoonHabits)
        #expect(group.threadIdentifier == "habit-afternoon")
    }

    @Test("Evening habit (8 PM) uses evening group")
    func testEveningHabitGrouping() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        // 8 PM = 20 * 3600 = 72000 seconds since midnight
        let habit = Habit(title: "Evening reading")
        habit.alertTimeInterval = 72000
        context.insert(habit)

        let group = NotificationGroup.forHabit(habit)

        #expect(group == .eveningHabits)
        #expect(group.threadIdentifier == "habit-evening")
    }

    @Test("Habit at exactly 6 AM boundary uses morning group")
    func testHabitAt6AMBoundary() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        // 6 AM = 6 * 3600 = 21600 seconds since midnight (boundary)
        let habit = Habit(title: "6 AM habit")
        habit.alertTimeInterval = 21600
        context.insert(habit)

        let group = NotificationGroup.forHabit(habit)

        // 6 AM is start of morning period (6 AM - 12 PM)
        #expect(group == .morningHabits)
    }

    @Test("Habit at exactly 6 PM boundary uses evening group")
    func testHabitAt6PMBoundary() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        // 6 PM = 18 * 3600 = 64800 seconds since midnight (boundary)
        let habit = Habit(title: "6 PM habit")
        habit.alertTimeInterval = 64800
        context.insert(habit)

        let group = NotificationGroup.forHabit(habit)

        // At exactly 64800, it should be evening (>= 64800)
        #expect(group == .eveningHabits)
    }

    @Test("Habit with no alert time uses ungrouped")
    func testHabitWithNoAlertTime() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "No alert habit")
        // Don't set alertTimeInterval - leave it nil
        context.insert(habit)

        let group = NotificationGroup.forHabit(habit)

        #expect(group == .ungrouped)
        #expect(group.threadIdentifier == nil)
    }

    // MARK: - Summary Text Tests

    @Test("Morning habits summary text (singular)")
    func testMorningHabitsSummarySingular() {
        let group = NotificationGroup.morningHabits
        let summary = group.summaryText(count: 1)

        #expect(summary == "morning habit")
    }

    @Test("Morning habits summary text (plural)")
    func testMorningHabitsSummaryPlural() {
        let group = NotificationGroup.morningHabits
        let summary = group.summaryText(count: 5)

        #expect(summary == "5 morning habits")
    }

    @Test("High priority tasks summary text (singular)")
    func testHighPriorityTasksSummarySingular() {
        let group = NotificationGroup.highPriorityTasks
        let summary = group.summaryText(count: 1)

        #expect(summary == "high priority task")
    }

    @Test("High priority tasks summary text (plural)")
    func testHighPriorityTasksSummaryPlural() {
        let group = NotificationGroup.highPriorityTasks
        let summary = group.summaryText(count: 3)

        #expect(summary == "3 high priority tasks")
    }

    @Test("Due today tasks summary text")
    func testDueTodayTasksSummary() {
        let group = NotificationGroup.dueTodayTasks
        let summary = group.summaryText(count: 4)

        #expect(summary == "4 tasks due today")
    }

    @Test("Overdue tasks summary text")
    func testOverdueTasksSummary() {
        let group = NotificationGroup.overdueTasksReminders
        let summary = group.summaryText(count: 2)

        #expect(summary == "2 overdue tasks")
    }

    @Test("Ungrouped has no summary text")
    func testUngroupedNoSummary() {
        let group = NotificationGroup.ungrouped
        let summary = group.summaryText(count: 5)

        #expect(summary == "")
    }

    // MARK: - Factory Method Tests

    @Test("Overdue reminder static factory returns overdue group")
    func testOverdueReminderFactory() {
        let group = NotificationGroup.overdueReminder

        #expect(group == .overdueTasksReminders)
        #expect(group.threadIdentifier == "task-overdue")
    }
}
