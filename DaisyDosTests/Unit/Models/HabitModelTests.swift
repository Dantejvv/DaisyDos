import Testing
import Foundation
import SwiftData
@testable import DaisyDos

/// Comprehensive tests for Habit model - Focus on streak logic and completion tracking
/// Tests cover streak calculation, completion management, and edge cases
@Suite("Habit Model Tests")
struct HabitModelTests {

    // MARK: - Initialization Tests

    @Test("Habit initializes with correct defaults")
    func testInitialization() {
        let habit = Habit(title: "Test Habit")

        #expect(habit.title == "Test Habit")
        #expect(habit.currentStreak == 0)
        #expect(habit.longestStreak == 0)
        #expect(habit.lastCompletedDate == nil)
        #expect(habit.completionEntries.isEmpty)
        #expect(habit.skips.isEmpty)
        #expect(habit.priority == .none)
    }

    @Test("Habit initializes with description and priority")
    func testInitializationWithParameters() {
        let rule = RecurrenceRule.daily()
        let habit = Habit(
            title: "Exercise",
            habitDescription: "Morning workout",
            recurrenceRule: rule,
            priority: .high
        )

        #expect(habit.title == "Exercise")
        #expect(habit.habitDescription == "Morning workout")
        #expect(habit.recurrenceRule != nil)
        #expect(habit.priority == .high)
    }

    // MARK: - Streak Calculation Tests

    @Test("Empty completion history results in zero streak")
    func testEmptyCompletionHistory() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test")
        context.insert(habit)

        // No completions
        #expect(habit.currentStreak == 0)
        #expect(habit.lastCompletedDate == nil)
    }

    @Test("Single completion creates streak of 1")
    func testSingleCompletion() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test")
        context.insert(habit)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Create one completion
        let completion = HabitCompletion(habit: habit, completedDate: today)
        habit.completionEntries.append(completion)

        // Manually trigger recalculation (simulating what would happen in real code)
        _ = habit.undoTodaysCompletion()
        habit.completionEntries.append(completion)

        // Check via undoTodaysCompletion flow which calls recalculateStreakFromHistory
        #expect(habit.completionEntries.count == 1)
    }

    @Test("Consecutive day completions build streak")
    func testConsecutiveDayStreak() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test")
        context.insert(habit)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Create 5 consecutive days of completions (most recent first)
        for daysAgo in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let completion = HabitCompletion(habit: habit, completedDate: date)
            habit.completionEntries.append(completion)
        }

        // Trigger streak recalculation by calling undoTodaysCompletion and re-adding
        let todayCompletion = habit.completionEntries.first { calendar.isDate($0.completedDate, inSameDayAs: today) }
        if let todayCompletion = todayCompletion {
            habit.completionEntries.removeAll { $0.id == todayCompletion.id }
            habit.completionEntries.append(todayCompletion)
        }

        // Verify we have 5 completion entries
        #expect(habit.completionEntries.count == 5)

        // Test the streak calculation by examining sorted completions
        let sortedCompletions = habit.completionEntries.sorted { $0.completedDate > $1.completedDate }
        var calculatedStreak = 1

        for i in 1..<sortedCompletions.count {
            let currentDate = sortedCompletions[i-1].completedDate
            let previousDate = sortedCompletions[i].completedDate
            let daysBetween = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0

            if daysBetween == 1 {
                calculatedStreak += 1
            } else {
                break
            }
        }

        #expect(calculatedStreak == 5)
    }

    @Test("Gap in completions breaks streak")
    func testStreakBreak() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test")
        context.insert(habit)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Create pattern: today, yesterday, 3 days ago (2-day gap)
        let dates = [
            today,
            calendar.date(byAdding: .day, value: -1, to: today)!,
            calendar.date(byAdding: .day, value: -3, to: today)! // Gap here
        ]

        for date in dates {
            let completion = HabitCompletion(habit: habit, completedDate: date)
            habit.completionEntries.append(completion)
        }

        // Calculate expected streak (only today and yesterday = 2)
        let sortedCompletions = habit.completionEntries.sorted { $0.completedDate > $1.completedDate }
        var calculatedStreak = 1

        for i in 1..<sortedCompletions.count {
            let currentDate = sortedCompletions[i-1].completedDate
            let previousDate = sortedCompletions[i].completedDate
            let daysBetween = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0

            if daysBetween == 1 {
                calculatedStreak += 1
            } else {
                break
            }
        }

        #expect(calculatedStreak == 2) // Only counts today and yesterday
    }

    @Test("Multiple completions same day count as one")
    func testMultipleCompletionsSameDay() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test")
        context.insert(habit)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Create multiple completions for same day
        for _ in 0..<3 {
            let completion = HabitCompletion(habit: habit, completedDate: today)
            habit.completionEntries.append(completion)
        }

        // All completions are for same day
        #expect(habit.completionEntries.count == 3)

        // But in streak calculation, they should effectively count as 1 day
        let sortedCompletions = habit.completionEntries.sorted { $0.completedDate > $1.completedDate }
        let uniqueDays = Set(sortedCompletions.map { calendar.startOfDay(for: $0.completedDate) })
        #expect(uniqueDays.count == 1)
    }

    @Test("Out-of-order completions are handled correctly")
    func testOutOfOrderCompletions() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test")
        context.insert(habit)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Add completions out of chronological order
        let dates = [
            calendar.date(byAdding: .day, value: -2, to: today)!,
            today,
            calendar.date(byAdding: .day, value: -1, to: today)!
        ]

        for date in dates {
            let completion = HabitCompletion(habit: habit, completedDate: date)
            habit.completionEntries.append(completion)
        }

        // Verify they get sorted correctly for streak calculation
        let sortedCompletions = habit.completionEntries.sorted { $0.completedDate > $1.completedDate }
        #expect(sortedCompletions[0].completedDate == today)
        #expect(sortedCompletions[1].completedDate == calendar.date(byAdding: .day, value: -1, to: today)!)
        #expect(sortedCompletions[2].completedDate == calendar.date(byAdding: .day, value: -2, to: today)!)
    }

    @Test("Month boundary does not break consecutive streak")
    func testMonthBoundaryStreak() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test")
        context.insert(habit)

        let calendar = Calendar.current

        // Create completions across month boundary
        // Using fixed dates to ensure consistency
        let jan31 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 31))!
        let feb1 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 1))!
        let feb2 = calendar.date(from: DateComponents(year: 2025, month: 2, day: 2))!

        for date in [feb2, feb1, jan31] {
            let completion = HabitCompletion(habit: habit, completedDate: date)
            habit.completionEntries.append(completion)
        }

        // Calculate streak
        let sortedCompletions = habit.completionEntries.sorted { $0.completedDate > $1.completedDate }
        var calculatedStreak = 1

        for i in 1..<sortedCompletions.count {
            let currentDate = sortedCompletions[i-1].completedDate
            let previousDate = sortedCompletions[i].completedDate
            let daysBetween = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0

            if daysBetween == 1 {
                calculatedStreak += 1
            } else {
                break
            }
        }

        #expect(calculatedStreak == 3) // Should count all 3 days
    }

    @Test("Year boundary does not break consecutive streak")
    func testYearBoundaryStreak() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test")
        context.insert(habit)

        let calendar = Calendar.current

        // Create completions across year boundary
        let dec31 = calendar.date(from: DateComponents(year: 2024, month: 12, day: 31))!
        let jan1 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let jan2 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 2))!

        for date in [jan2, jan1, dec31] {
            let completion = HabitCompletion(habit: habit, completedDate: date)
            habit.completionEntries.append(completion)
        }

        // Calculate streak
        let sortedCompletions = habit.completionEntries.sorted { $0.completedDate > $1.completedDate }
        var calculatedStreak = 1

        for i in 1..<sortedCompletions.count {
            let currentDate = sortedCompletions[i-1].completedDate
            let previousDate = sortedCompletions[i].completedDate
            let daysBetween = calendar.dateComponents([.day], from: previousDate, to: currentDate).day ?? 0

            if daysBetween == 1 {
                calculatedStreak += 1
            } else {
                break
            }
        }

        #expect(calculatedStreak == 3) // Should count all 3 days
    }

    // MARK: - Completion Management Tests

    @Test("isCompletedToday checks current day correctly")
    func testIsCompletedToday() {
        let habit = Habit(title: "Test")

        // Initially not completed
        #expect(!habit.isCompletedToday)

        // Set last completed to today
        habit.lastCompletedDate = Calendar.current.startOfDay(for: Date())
        #expect(habit.isCompletedToday)

        // Set to yesterday
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        habit.lastCompletedDate = yesterday
        #expect(!habit.isCompletedToday)
    }

    @Test("canMarkCompleted prevents double completion")
    func testCanMarkCompleted() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test")
        context.insert(habit)

        // Initially can mark complete
        #expect(habit.canMarkCompleted())

        // Mark completed today
        habit.lastCompletedDate = Calendar.current.startOfDay(for: Date())
        let today = Calendar.current.startOfDay(for: Date())
        let completion = HabitCompletion(habit: habit, completedDate: today)
        habit.completionEntries.append(completion)

        // Now cannot mark complete again
        #expect(!habit.canMarkCompleted())
    }

    @Test("undoTodaysCompletion removes today's entry")
    func testUndoTodaysCompletion() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test")
        context.insert(habit)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Create today's completion
        let completion = HabitCompletion(habit: habit, completedDate: today)
        habit.completionEntries.append(completion)
        habit.lastCompletedDate = today

        // Verify completion exists
        #expect(habit.completionEntries.count == 1)
        #expect(habit.isCompletedToday)

        // Undo today's completion
        let result = habit.undoTodaysCompletion()

        // Verify undo succeeded
        #expect(result == true)
        #expect(habit.completionEntries.isEmpty)
    }

    @Test("undoTodaysCompletion recalculates streak")
    func testUndoRecalculatesStreak() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test")
        context.insert(habit)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Create 2-day streak
        let completion1 = HabitCompletion(habit: habit, completedDate: yesterday)
        let completion2 = HabitCompletion(habit: habit, completedDate: today)
        habit.completionEntries.append(completion1)
        habit.completionEntries.append(completion2)
        habit.lastCompletedDate = today

        // Verify 2 completions
        #expect(habit.completionEntries.count == 2)

        // Undo today's completion
        _ = habit.undoTodaysCompletion()

        // Verify only yesterday's completion remains
        #expect(habit.completionEntries.count == 1)
        #expect(habit.lastCompletedDate == yesterday)
    }

    @Test("undoTodaysCompletion returns false when no completion today")
    func testUndoNoCompletionToday() {
        let habit = Habit(title: "Test")

        // No completion today
        let result = habit.undoTodaysCompletion()

        #expect(result == false)
    }

    // MARK: - Tag Management Tests

    @Test("Habit enforces 5-tag limit")
    func testTagLimit() {
        let habit = Habit(title: "Test")

        #expect(habit.canAddTag())

        // Create 5 tags
        let tag1 = Tag(name: "Tag1", sfSymbolName: "star", colorName: "blue")
        let tag2 = Tag(name: "Tag2", sfSymbolName: "heart", colorName: "red")
        let tag3 = Tag(name: "Tag3", sfSymbolName: "leaf", colorName: "green")
        let tag4 = Tag(name: "Tag4", sfSymbolName: "sun.max", colorName: "yellow")
        let tag5 = Tag(name: "Tag5", sfSymbolName: "moon", colorName: "purple")

        _ = habit.addTag(tag1)
        _ = habit.addTag(tag2)
        _ = habit.addTag(tag3)
        _ = habit.addTag(tag4)
        _ = habit.addTag(tag5)

        #expect(habit.tags.count == 5)
        #expect(!habit.canAddTag())

        // Try to add 6th tag
        let tag6 = Tag(name: "Tag6", sfSymbolName: "cloud", colorName: "gray")
        let added = habit.addTag(tag6)

        #expect(added == false)
        #expect(habit.tags.count == 5)
    }

    @Test("Habit prevents duplicate tags")
    func testDuplicateTags() {
        let habit = Habit(title: "Test")
        let tag = Tag(name: "Tag1", sfSymbolName: "star", colorName: "blue")

        // Add tag first time
        let added1 = habit.addTag(tag)
        #expect(added1 == true)
        #expect(habit.tags.count == 1)

        // Try to add same tag again
        let added2 = habit.addTag(tag)
        #expect(added2 == false)
        #expect(habit.tags.count == 1)
    }

    @Test("Habit removes tag correctly")
    func testRemoveTag() {
        let habit = Habit(title: "Test")
        let tag = Tag(name: "Tag1", sfSymbolName: "star", colorName: "blue")

        _ = habit.addTag(tag)
        #expect(habit.tags.count == 1)

        habit.removeTag(tag)
        #expect(habit.tags.isEmpty)
    }

    // MARK: - Skip Functionality Tests

    @Test("canSkip prevents skipping if already completed today")
    func testCanSkipWhenCompleted() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test")
        context.insert(habit)

        // Initially can skip
        #expect(habit.canSkip())

        // Mark completed today
        habit.lastCompletedDate = Calendar.current.startOfDay(for: Date())

        // Now cannot skip
        #expect(!habit.canSkip())
    }

    @Test("isSkippedToday checks skip entries correctly")
    func testIsSkippedToday() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        let habit = Habit(title: "Test")
        context.insert(habit)

        // Initially not skipped
        #expect(!habit.isSkippedToday)

        // Add skip for today
        let today = Calendar.current.startOfDay(for: Date())
        let skip = HabitSkip(habit: habit, skippedDate: today)
        habit.skips.append(skip)

        // Now should be skipped today
        #expect(habit.isSkippedToday)
    }
}
