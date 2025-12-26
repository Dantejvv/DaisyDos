import Testing
import Foundation
import SwiftData
@testable import DaisyDos

/// Tests for HabitSkip model - Focus on skip impact calculation and frequency analysis
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
        let skip = HabitSkip(habit: habit, skippedDate: today, reason: "Too busy")

        #expect(skip.habit == habit)
        #expect(skip.skippedDate == today)
        #expect(skip.reason == "Too busy")
        #expect(skip.hasReason)
    }

    @Test("HabitSkip without reason")
    func testSkipWithoutReason() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let skip = HabitSkip(habit: habit, skippedDate: Date())

        #expect(skip.reason == nil)
        #expect(!skip.hasReason)
        #expect(skip.reasonDisplay == "No reason given")
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

    // MARK: - Skip Impact Tests

    @Test("Skip impact: rare (< 10% no reason)")
    func testSkipImpactRare() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Add 1 skip in past 30 days (no reason) = ~3% skip rate
        let skip = HabitSkip(habit: habit, skippedDate: today)
        habit.skips = (habit.skips ?? []) + [skip]

        let impact = skip.skipImpact()

        #expect(impact == .rare)
    }

    @Test("Skip impact: occasional (< 10% with reason)")
    func testSkipImpactOccasional() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Add 1 skip with reason in past 30 days = ~3% skip rate
        let skip = HabitSkip(habit: habit, skippedDate: today, reason: "Sick")
        habit.skips = (habit.skips ?? []) + [skip]

        let impact = skip.skipImpact()

        #expect(impact == .occasional)
    }

    @Test("Skip impact: worrying (10-30% no reason)")
    func testSkipImpactWorrying() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Add 6 skips without reason in past 30 days = ~20% skip rate
        for daysAgo in 0..<6 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let skip = HabitSkip(habit: habit, skippedDate: date)
            habit.skips = (habit.skips ?? []) + [skip]
        }

        guard let lastSkip = habit.skips?.last else {
            Issue.record("Expected last skip to exist")
            return
        }
        let impact = lastSkip.skipImpact()

        #expect(impact == .worrying)
    }

    @Test("Skip impact: concerning (10-30% with reason)")
    func testSkipImpactConcerning() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Add 6 skips with reasons in past 30 days = ~20% skip rate
        for daysAgo in 0..<6 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let skip = HabitSkip(habit: habit, skippedDate: date, reason: "Busy")
            habit.skips = (habit.skips ?? []) + [skip]
        }

        guard let lastSkip = habit.skips?.last else {
            Issue.record("Expected last skip to exist")
            return
        }
        let impact = lastSkip.skipImpact()

        #expect(impact == .concerning)
    }

    @Test("Skip impact: alarming (>30% no reason)")
    func testSkipImpactAlarming() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Add 10 skips without reason in past 30 days = ~33% skip rate
        for daysAgo in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let skip = HabitSkip(habit: habit, skippedDate: date)
            habit.skips = (habit.skips ?? []) + [skip]
        }

        guard let lastSkip = habit.skips?.last else {
            Issue.record("Expected last skip to exist")
            return
        }
        let impact = lastSkip.skipImpact()

        #expect(impact == .alarming)
    }

    @Test("Skip impact: problematic (>30% with reason)")
    func testSkipImpactProblematic() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Add 10 skips with reasons in past 30 days = ~33% skip rate
        for daysAgo in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let skip = HabitSkip(habit: habit, skippedDate: date, reason: "Too much")
            habit.skips = (habit.skips ?? []) + [skip]
        }

        guard let lastSkip = habit.skips?.last else {
            Issue.record("Expected last skip to exist")
            return
        }
        let impact = lastSkip.skipImpact()

        #expect(impact == .problematic)
    }

    // MARK: - Skip Frequency Tests

    @Test("Skip frequency calculation with no skips")
    func testSkipFrequencyNone() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let skip = HabitSkip(habit: habit, skippedDate: Date())

        let frequency = skip.skipFrequencyInPast30Days()

        // 1 skip out of 30 days = ~3%
        #expect(frequency < 0.1)
    }

    @Test("Skip frequency calculation with multiple skips")
    func testSkipFrequencyMultiple() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test Habit")
        context.insert(habit)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Add 15 skips in past 30 days = 50%
        for daysAgo in 0..<15 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let skip = HabitSkip(habit: habit, skippedDate: date)
            habit.skips = (habit.skips ?? []) + [skip]
        }

        guard let lastSkip = habit.skips?.last else {
            Issue.record("Expected last skip to exist")
            return
        }
        let frequency = lastSkip.skipFrequencyInPast30Days()

        #expect(frequency >= 0.3) // Should be high frequency
    }

    // MARK: - Impact Display Tests

    @Test("Skip impact display messages are not empty")
    func testImpactDisplayMessages() {
        // Just verify all messages are set and non-empty
        #expect(!HabitSkip.SkipImpact.rare.displayMessage.isEmpty)
        #expect(!HabitSkip.SkipImpact.occasional.displayMessage.isEmpty)
        #expect(!HabitSkip.SkipImpact.worrying.displayMessage.isEmpty)
        #expect(!HabitSkip.SkipImpact.concerning.displayMessage.isEmpty)
        #expect(!HabitSkip.SkipImpact.problematic.displayMessage.isEmpty)
        #expect(!HabitSkip.SkipImpact.alarming.displayMessage.isEmpty)
    }

    @Test("Skip impact severity is ordered correctly")
    func testImpactSeverityOrdering() {
        #expect(HabitSkip.SkipImpact.rare.severity < HabitSkip.SkipImpact.occasional.severity)
        #expect(HabitSkip.SkipImpact.occasional.severity < HabitSkip.SkipImpact.concerning.severity)
        #expect(HabitSkip.SkipImpact.concerning.severity < HabitSkip.SkipImpact.worrying.severity)
        #expect(HabitSkip.SkipImpact.worrying.severity < HabitSkip.SkipImpact.problematic.severity)
        #expect(HabitSkip.SkipImpact.problematic.severity < HabitSkip.SkipImpact.alarming.severity)
    }
}
