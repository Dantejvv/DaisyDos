//
//  TestHelpers.swift
//  DaisyDosTests
//
//  Created by Claude Code on 10/20/25.
//

import Foundation
import SwiftData
@testable import DaisyDos

/// Reusable test utilities and helpers for DaisyDos test suite
@MainActor
enum TestHelpers {

    // MARK: - Shared Test Container (Singleton for Thread Safety)

    /// Shared in-memory container to prevent parallel test conflicts
    /// This ensures all tests use the same ModelContext, preventing mainActor threading issues
    private static var _sharedContainer: ModelContainer?

    /// Returns the shared ModelContainer for all tests
    /// Using a shared container with `.serialized` suites prevents parallel execution conflicts
    static var sharedContainer: ModelContainer {
        get throws {
            if let existing = _sharedContainer {
                return existing
            }
            let container = try createNewContainer()
            _sharedContainer = container
            return container
        }
    }

    /// Resets the shared container (call between test suites if needed)
    static func resetSharedContainer() {
        _sharedContainer = nil
    }

    // MARK: - ModelContainer Creation

    /// Creates a NEW in-memory ModelContainer for testing with all DaisyDos models
    /// - Returns: Configured ModelContainer for testing
    /// - Throws: ModelContainer initialization errors
    private static func createNewContainer() throws -> ModelContainer {
        let schema = Schema([
            Task.self,
            Tag.self,
            TaskAttachment.self,
            Habit.self,
            HabitCompletion.self,
            HabitStreak.self,
            HabitSkip.self,
            TaskLogEntry.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    /// Creates an in-memory ModelContainer for testing with all DaisyDos models
    /// - Returns: Configured ModelContainer for testing
    /// - Throws: ModelContainer initialization errors
    static func createTestContainer() throws -> ModelContainer {
        return try sharedContainer
    }

    // MARK: - Actor-Based Testing (ModelActor Pattern)

    /// Creates an isolated ModelContainer for actor-based tests
    /// Each test gets its own container, enabling parallel execution without conflicts
    /// - Returns: Fresh in-memory ModelContainer with all models
    /// - Throws: ModelContainer initialization errors
    static func createActorTestContainer() throws -> ModelContainer {
        let schema = Schema([
            Task.self,
            Tag.self,
            TaskAttachment.self,
            Habit.self,
            HabitCompletion.self,
            HabitStreak.self,
            HabitSkip.self,
            TaskLogEntry.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }

    /// Creates an in-memory ModelContainer with specific models
    /// - Parameter models: Array of model types to include
    /// - Returns: Configured ModelContainer for testing
    /// - Throws: ModelContainer initialization errors
    static func createTestContainer(for models: [any PersistentModel.Type]) throws -> ModelContainer {
        let schema = Schema(models)
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    // MARK: - Date Helpers

    /// Returns a date offset by the specified number of days from today
    /// - Parameter days: Number of days to offset (negative for past, positive for future)
    /// - Returns: Date offset by specified days
    static func date(daysFromNow days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date())!
    }

    /// Returns a date offset by the specified number of hours from now
    /// - Parameter hours: Number of hours to offset
    /// - Returns: Date offset by specified hours
    static func date(hoursFromNow hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: Date())!
    }

    /// Returns midnight of the current day
    /// - Returns: Date set to midnight (00:00:00) of current day
    static func midnight() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 0
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)!
    }

    /// Returns end of day (23:59:59) of the current day
    /// - Returns: Date set to end of current day
    static func endOfDay() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 23
        components.minute = 59
        components.second = 59
        return calendar.date(from: components)!
    }

    /// Compares two dates ignoring time component
    /// - Parameters:
    ///   - date1: First date to compare
    ///   - date2: Second date to compare
    /// - Returns: True if dates are on the same day
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }

    // MARK: - Test Data Factories

    /// Creates a test task with common defaults
    /// - Parameters:
    ///   - title: Task title (default: "Test Task")
    ///   - description: Task description (default: "")
    ///   - priority: Task priority (default: .medium)
    ///   - dueDate: Task due date (default: nil)
    /// - Returns: Configured Task instance
    static func makeTask(
        title: String = "Test Task",
        description: String = "",
        priority: Priority = .medium,
        dueDate: Date? = nil
    ) -> Task {
        Task(
            title: title,
            taskDescription: description,
            priority: priority,
            dueDate: dueDate
        )
    }

    /// Creates a test habit with common defaults
    /// - Parameters:
    ///   - title: Habit title (default: "Test Habit")
    ///   - description: Habit description (default: "")
    /// - Returns: Configured Habit instance
    static func makeHabit(
        title: String = "Test Habit",
        description: String = ""
    ) -> Habit {
        Habit(
            title: title,
            habitDescription: description
        )
    }

    /// Creates a test tag with common defaults
    /// - Parameters:
    ///   - name: Tag name (default: "Test Tag")
    ///   - color: Tag color name (default: "blue")
    ///   - symbol: SF Symbol name (default: "tag")
    /// - Returns: Configured Tag instance
    static func makeTag(
        name: String = "Test Tag",
        color: String = "blue",
        symbol: String = "tag"
    ) -> Tag {
        Tag(name: name, sfSymbolName: symbol, colorName: color)
    }

    // MARK: - Manager Creation

    /// Creates a TaskManager with in-memory context for testing
    /// - Parameter container: ModelContainer to use (creates new if nil)
    /// - Returns: Tuple of (TaskManager, ModelContainer)
    /// - Throws: Container creation errors
    static func makeTaskManager(
        container: ModelContainer? = nil
    ) throws -> (manager: TaskManager, container: ModelContainer) {
        let testContainer = try container ?? createTestContainer(for: [Task.self, Tag.self, TaskAttachment.self])
        let manager = TaskManager(modelContext: testContainer.mainContext)
        return (manager, testContainer)
    }

    /// Creates a HabitManager with in-memory context for testing
    /// - Parameter container: ModelContainer to use (creates new if nil)
    /// - Returns: Tuple of (HabitManager, ModelContainer)
    /// - Throws: Container creation errors
    static func makeHabitManager(
        container: ModelContainer? = nil
    ) throws -> (manager: HabitManager, container: ModelContainer) {
        let testContainer = try container ?? createTestContainer(for: [
            Habit.self,
            HabitCompletion.self,
            HabitStreak.self,
            HabitSkip.self,
            Tag.self
        ])
        let manager = HabitManager(modelContext: testContainer.mainContext)
        return (manager, testContainer)
    }

    /// Creates a TagManager with in-memory context for testing
    /// - Parameter container: ModelContainer to use (creates new if nil)
    /// - Returns: Tuple of (TagManager, ModelContainer)
    /// - Throws: Container creation errors
    static func makeTagManager(
        container: ModelContainer? = nil
    ) throws -> (manager: TagManager, container: ModelContainer) {
        let testContainer = try container ?? createTestContainer(for: [Tag.self, Task.self, Habit.self])
        let manager = TagManager(modelContext: testContainer.mainContext)
        return (manager, testContainer)
    }

    // MARK: - Assertion Helpers

    /// Unwraps a Result and returns the success value or throws
    /// - Parameter result: Result to unwrap
    /// - Returns: Success value
    /// - Throws: Failure error
    static func unwrap<T, E: Error>(_ result: Result<T, E>) throws -> T {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        }
    }

    /// Checks if a Result is successful
    /// - Parameter result: Result to check
    /// - Returns: True if result is success
    static func isSuccess<T, E>(_ result: Result<T, E>) -> Bool {
        if case .success = result {
            return true
        }
        return false
    }

    /// Checks if a Result is failure
    /// - Parameter result: Result to check
    /// - Returns: True if result is failure
    static func isFailure<T, E>(_ result: Result<T, E>) -> Bool {
        if case .failure = result {
            return true
        }
        return false
    }
}

// MARK: - Result Extensions for Testing

extension Result {
    /// Returns the success value or nil if failure
    var successValue: Success? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }

    /// Returns the failure error or nil if success
    var failureError: Failure? {
        if case .failure(let error) = self {
            return error
        }
        return nil
    }
}
