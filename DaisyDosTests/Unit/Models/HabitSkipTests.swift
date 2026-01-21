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
