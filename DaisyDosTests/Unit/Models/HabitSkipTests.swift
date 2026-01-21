import Testing
import Foundation
import SwiftData
@testable import DaisyDos

/// Tests for HabitSkip model - Basic skip functionality
@Suite("HabitSkip Tests")
struct HabitSkipTests {

    // MARK: - Initialization Tests

    @Test("HabitSkip initializes correctly")
    func testInitialization() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let today = Calendar.current.startOfDay(for: Date())
        let skip = HabitSkip(habit: habit, skippedDate: today)

        #expect(skip.habit == habit)
        #expect(skip.skippedDate == today)
        #expect(skip.id != UUID())
    }

    // MARK: - Computed Properties Tests

    @Test("isToday detects today's skip")
    func testIsToday() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let today = Date()
        let skip = HabitSkip(habit: habit, skippedDate: today)

        #expect(skip.isToday)
    }

    @Test("isToday returns false for yesterday")
    func testIsNotToday() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let skip = HabitSkip(habit: habit, skippedDate: yesterday)

        #expect(!skip.isToday)
    }

    @Test("dayOfWeek returns day name")
    func testDayOfWeek() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let skip = HabitSkip(habit: habit, skippedDate: Date())

        #expect(!skip.dayOfWeek.isEmpty)
        // Day name should be something like "Monday", "Tuesday", etc.
        #expect(skip.dayOfWeek.count > 4)
    }

    @Test("isThisWeek detects skip in current week")
    func testIsThisWeek() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let today = Date()
        let skip = HabitSkip(habit: habit, skippedDate: today)

        #expect(skip.isThisWeek)
    }

    @Test("isThisMonth detects skip in current month")
    func testIsThisMonth() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let today = Date()
        let skip = HabitSkip(habit: habit, skippedDate: today)

        #expect(skip.isThisMonth)
    }

    @Test("isThisMonth returns false for last month")
    func testIsNotThisMonth() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        let skip = HabitSkip(habit: habit, skippedDate: lastMonth)

        #expect(!skip.isThisMonth)
    }

    // MARK: - Habit Integration Tests

    @Test("Skip is added to habit's skip array")
    func testSkipAddedToHabit() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let skip = habit.skipHabit()

        #expect(skip != nil)
        #expect(habit.skips?.count == 1)
        #expect(habit.isSkippedToday)
    }

    @Test("Cannot skip habit twice in same day")
    func testCannotSkipTwice() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let firstSkip = habit.skipHabit()
        let secondSkip = habit.skipHabit()

        #expect(firstSkip != nil)
        #expect(secondSkip == nil)
        #expect(habit.skips?.count == 1)
    }

    @Test("Cannot skip completed habit")
    func testCannotSkipCompletedHabit() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        // Complete the habit
        habit.markCompleted()

        // Try to skip
        let skip = habit.skipHabit()

        #expect(skip == nil)
        #expect(habit.isCompletedToday)
        #expect(!habit.isSkippedToday)
    }
}
