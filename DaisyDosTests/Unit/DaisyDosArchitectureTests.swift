//
//  DaisyDosTests.swift
//  DaisyDosTests
//
//  Created by Dante Vercelli on 9/23/25.
//

import Testing
import SwiftData
import Foundation
@testable import DaisyDos

extension AllTests {
    /// Architectural validation tests for Phase 1.0 completion
    /// Tests core patterns: @Observable managers, SwiftData models, error handling
    /// Pattern: Struct + Local Container for perfect test isolation
    @Suite(.serialized)
    struct DaisyDosArchitectureTests {

    // MARK: - @Observable Manager Pattern Tests

    @Test("TaskManager @Observable reactivity with SwiftData")
    func testTaskManagerObservablePattern() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let taskManager = TaskManager(modelContext: ModelContext(container))

        // Test @Observable reactivity
        let initialCount = taskManager.taskCount
        let result = taskManager.createTask(title: "Test Task")

        switch result {
        case .success(let task):
            #expect(taskManager.taskCount == initialCount + 1)
            #expect(taskManager.allTasks.count == initialCount + 1)
            #expect(taskManager.pendingTasks.contains { $0.id == task.id })
            #expect(!taskManager.completedTasks.contains { $0.id == task.id })
        case .failure:
            #expect(Bool(false), "Task creation should succeed")
        }
    }

    @Test("HabitManager streak calculations work correctly")
    func testHabitManagerStreakLogic() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let habitManager = HabitManager(modelContext: ModelContext(container))

        guard case .success(let habit) = habitManager.createHabit(title: "Test Habit") else {
            throw DaisyDosError.persistenceFailed("Failed to create habit")
        }
        #expect(habit.currentStreak == 0)
        #expect(habit.longestStreak == 0)
        #expect(!habit.isCompletedToday)

        let success = habitManager.markHabitCompleted(habit)
        #expect(success == true)
        #expect(habit.currentStreak == 1)
        #expect(habit.longestStreak == 1)
        #expect(habit.isCompletedToday)

        // Test cannot mark completed twice same day
        let secondAttempt = habitManager.markHabitCompleted(habit)
        #expect(secondAttempt == false)
        #expect(habit.currentStreak == 1) // Should not increment
    }

    @Test("TagManager constraint validation works")
    func testTagManagerConstraintValidation() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let tagManager = TagManager(modelContext: ModelContext(container))

        // Test tag creation
        let tag1 = tagManager.createTag(name: "Work", colorName: "blue")
        #expect(tag1 != nil)
        #expect(tag1?.name == "Work")
        #expect(tag1?.colorName == "blue")

        // Test duplicate name prevention
        let duplicateTag = tagManager.createTag(name: "Work")
        #expect(duplicateTag == nil) // Should fail due to duplicate name

        // Test system can create new tags initially
        #expect(tagManager.canCreateNewTag == true)
        #expect(tagManager.tagCount == 1)
    }

    // MARK: - SwiftData Model Business Logic Tests

    @Test("Task model business logic and constraints")
    func testTaskModelConstraints() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let task = Task(title: "Test Task")
        let tag1 = Tag(name: "Tag1", colorName: "red")
        let tag2 = Tag(name: "Tag2", colorName: "green")
        let tag3 = Tag(name: "Tag3", colorName: "blue")
        let tag4 = Tag(name: "Tag4", colorName: "yellow")

        // Test initial state
        #expect(task.title == "Test Task")
        #expect(task.isCompleted == false)
        #expect(task.tags.isEmpty)
        #expect(task.canAddTag() == true)

        // Test 3-tag limit
        #expect(task.addTag(tag1) == true)
        #expect(task.addTag(tag2) == true)
        #expect(task.addTag(tag3) == true)
        #expect(task.addTag(tag4) == false) // Should fail - exceeds limit
        #expect(task.tags.count == 3)
        #expect(task.canAddTag() == false)

        // Test completion toggle
        task.toggleCompletion()
        #expect(task.isCompleted == true)

        task.toggleCompletion()
        #expect(task.isCompleted == false)

        // Test tag removal
        task.removeTag(tag1)
        #expect(task.tags.count == 2)
        #expect(task.canAddTag() == true)
    }

    @Test("Habit model streak calculations and business logic")
    func testHabitModelBusinessLogic() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let habit = Habit(title: "Daily Exercise", habitDescription: "30 min workout")

        // Test initial state
        #expect(habit.title == "Daily Exercise")
        #expect(habit.habitDescription == "30 min workout")
        #expect(habit.currentStreak == 0)
        #expect(habit.longestStreak == 0)
        #expect(habit.lastCompletedDate == nil)
        #expect(habit.isCompletedToday == false)
        #expect(habit.canMarkCompleted() == true)

        // Test mark completed
        habit.markCompleted()
        #expect(habit.currentStreak == 1)
        #expect(habit.longestStreak == 1)
        #expect(habit.isCompletedToday == true)
        #expect(habit.canMarkCompleted() == false) // Cannot complete twice same day

        // Test reset streak
        habit.resetStreak()
        #expect(habit.currentStreak == 0)
        #expect(habit.lastCompletedDate == nil)
        #expect(habit.canMarkCompleted() == true)
    }

    @Test("Tag model system limits and properties")
    func testTagModelSystemLimits() async throws {
        let container = try TestHelpers.createActorTestContainer()
        // Test system validation method
        let canCreate = Tag.validateSystemTagLimit(in: ModelContext(container))
        #expect(canCreate == true) // Should be true with empty database

        let canCreateMethod = Tag.canCreateNewTag(in: ModelContext(container))
        #expect(canCreateMethod == true)

        // Test tag properties
        let tag = Tag(name: "Test Tag", sfSymbolName: "star", colorName: "red")
        #expect(tag.name == "Test Tag")
        #expect(tag.sfSymbolName == "star")
        #expect(tag.colorName == "red")
        #expect(tag.color == .red)
        #expect(tag.totalItemCount == 0)
        #expect(tag.isInUse == false)

        // Test available options
        let colors = Tag.availableColors()
        #expect(colors.contains("red"))
        #expect(colors.contains("blue"))
        #expect(colors.count == 9)

        let symbols = Tag.availableSymbols()
        #expect(symbols.contains("tag"))
        #expect(symbols.contains("star"))
        #expect(symbols.count > 10)
    }

    // MARK: - Error Handling Architecture Tests

    @Test("Error transformation system works end-to-end")
    func testErrorTransformationSystem() async throws {
        let container = try TestHelpers.createActorTestContainer()
        // Test platform → app → user transformation
        let mockError = NSError(
            domain: "TestDomain",
            code: 133021,
            userInfo: [NSLocalizedDescriptionKey: "unique constraint failed"]
        )
        let context = ErrorTransformer.ErrorContext.taskOperation("create task")

        let transformed = ErrorTransformer.transform(error: mockError, context: context)

        // Verify transformation to RecoverableError
        #expect(transformed.userMessage.count > 0)
        #expect(transformed.userReason.count > 0)
        #expect(transformed.recoveryOptions.count > 0)

        // Test AnyRecoverableError wrapper
        let wrappedError = AnyRecoverableError(transformed)
        #expect(wrappedError.userMessage == transformed.userMessage)
        #expect(wrappedError.recoveryOptions.count == transformed.recoveryOptions.count)
    }

    @Test("DaisyDosError provides user-friendly messages")
    func testDaisyDosErrorUserMessages() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let tagLimitError = DaisyDosError.tagLimitExceeded

        #expect(tagLimitError.userMessage == "Too many tags")
        #expect(tagLimitError.userReason.contains("3 tags per item"))
        #expect(tagLimitError.recoveryOptions.count >= 2)
        #expect(tagLimitError.priority == .low)

        let validationError = DaisyDosError.validationFailed("title")
        #expect(validationError.userMessage == "Please check your information")
        #expect(validationError.isUserError == true)
        #expect(validationError.priority == .low)

        let dataCorrupted = DaisyDosError.dataCorrupted("test corruption")
        #expect(dataCorrupted.isCritical == true)
        #expect(dataCorrupted.priority == .critical)
    }

    @Test("ErrorTransformer safely wrapper works correctly")
    func testErrorTransformerSafelyWrapper() async throws {
        let container = try TestHelpers.createActorTestContainer()
        // Test successful operation
        let successResult = ErrorTransformer.safely(
            operation: "test operation",
            entityType: "test"
        ) {
            return "success"
        }

        switch successResult {
        case .success(let value):
            #expect(value == "success")
        case .failure:
            #expect(Bool(false), "Operation should succeed")
        }

        // Test failed operation
        let failureResult = ErrorTransformer.safely(
            operation: "test operation",
            entityType: "test"
        ) {
            throw DaisyDosError.validationFailed("test field")
        }

        switch failureResult {
        case .success:
            #expect(Bool(false), "Operation should fail")
        case .failure(let error):
            #expect(error.userMessage.count > 0)
        }
    }

    // MARK: - Environment Injection & Integration Tests

    @Test("Environment injection works with @Observable managers")
    func testEnvironmentInjectionPattern() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let taskManager = TaskManager(modelContext: ModelContext(container))
        let habitManager = HabitManager(modelContext: ModelContext(container))
        let tagManager = TagManager(modelContext: ModelContext(container))

        // Verify managers can be created and used
        #expect(taskManager.taskCount == 0)
        #expect(habitManager.habitCount == 0)
        #expect(tagManager.tagCount == 0)

        // Test cross-manager workflow
        let tag = tagManager.createTag(name: "Work", colorName: "blue")
        let taskResult = taskManager.createTask(title: "Test Task")

        #expect(tag != nil)

        switch taskResult {
        case .success(let task):
            // Test tag assignment across managers
            if let createdTag = tag {
                let tagResult = taskManager.addTag(createdTag, to: task)
                switch tagResult {
                case .success:
                    #expect(task.tags.count == 1)
                    #expect(createdTag.totalItemCount == 1)
                    #expect(createdTag.isInUse == true)
                case .failure:
                    #expect(Bool(false), "Tag assignment should succeed")
                }
            }
        case .failure:
            #expect(Bool(false), "Task creation should succeed")
        }
    }

    @Test("SwiftData schema and migration plan work correctly")
    func testSwiftDataSchemaIntegration() async throws {
        let container = try TestHelpers.createActorTestContainer()
        // Test schema definition
        let schemaModels = DaisyDosSchemaV3.models
        #expect(schemaModels.count == 7) // Task, Habit, Tag, TaskAttachment, HabitCompletion, HabitStreak, HabitSkip

        // Test migration plan
        let migrationSchemas = DaisyDosMigrationPlan.schemas
        #expect(migrationSchemas.count == 1) // V3 only
        #expect(DaisyDosMigrationPlan.stages.isEmpty) // No migrations - V3 is baseline

        // Test container works with schema
        #expect(ModelContext(container) != nil)

        // Test all model types can be created
        let task = Task(title: "Schema Test Task")
        let habit = Habit(title: "Schema Test Habit")
        let tag = Tag(name: "Schema Test Tag")

        ModelContext(container).insert(task)
        ModelContext(container).insert(habit)
        ModelContext(container).insert(tag)

        try ModelContext(container).save()

        // Verify persistence worked
        let taskDescriptor = FetchDescriptor<Task>()
        let fetchedTasks = try ModelContext(container).fetch(taskDescriptor)
        #expect(fetchedTasks.count == 1)
        #expect(fetchedTasks.first?.title == "Schema Test Task")
    }

    // MARK: - Performance Baseline Validation Tests

    @Test("Performance baselines are met")
    func testPerformanceBaselines() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let taskManager = TaskManager(modelContext: ModelContext(container))

        let startTime = CFAbsoluteTimeGetCurrent()

        // Create 50 tasks (reasonable load test)
        for i in 1...50 {
            let _ = taskManager.createTaskSafely(title: "Performance Test Task \(i)")
        }

        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = endTime - startTime

        #expect(duration < 0.5) // Should complete in under 500ms
        #expect(taskManager.allTasks.count == 50)
        #expect(taskManager.pendingTasks.count == 50)
        #expect(taskManager.completedTasks.count == 0)

        // Test query performance
        let queryStartTime = CFAbsoluteTimeGetCurrent()
        let searchResults = taskManager.searchTasksSafely(query: "Performance")
        let queryEndTime = CFAbsoluteTimeGetCurrent()
        let queryDuration = queryEndTime - queryStartTime

        #expect(queryDuration < 0.1) // Search should be under 100ms
        #expect(searchResults.count == 50) // All tasks should match "Performance"
    }

    @Test("Manager error handling preserves data integrity")
    func testManagerErrorHandling() async throws {
        let container = try TestHelpers.createActorTestContainer()
        let taskManager = TaskManager(modelContext: ModelContext(container))
        let tagManager = TagManager(modelContext: ModelContext(container))

        // Test validation error doesn't corrupt state
        let initialCount = taskManager.taskCount
        let emptyTitleResult = taskManager.createTask(title: "")

        switch emptyTitleResult {
        case .success:
            #expect(Bool(false), "Empty title should fail validation")
        case .failure:
            #expect(taskManager.taskCount == initialCount) // Count unchanged
        }

        // Test successful creation after failure
        let validResult = taskManager.createTask(title: "Valid Task")
        switch validResult {
        case .success(let task):
            #expect(taskManager.taskCount == initialCount + 1)

            // Test tag limit enforcement preserves integrity
            let tag = tagManager.createTag(name: "Test Tag")
            #expect(tag != nil)

            if let createdTag = tag {
                // Add 3 tags successfully
                for i in 1...3 {
                    let tempTag = Tag(name: "Temp Tag \(i)")
                    let result = taskManager.addTag(tempTag, to: task)
                    switch result {
                    case .success:
                        continue // Expected
                    case .failure:
                        #expect(Bool(false), "Adding tag \(i) should succeed")
                    }
                }

                // 4th tag should fail but not corrupt state
                let fourthTagResult = taskManager.addTag(createdTag, to: task)
                switch fourthTagResult {
                case .success:
                    #expect(Bool(false), "4th tag should fail due to limit")
                case .failure:
                    #expect(task.tags.count == 3) // Unchanged
                }
            }
        case .failure:
            #expect(Bool(false), "Valid task creation should succeed")
        }
    }
}
}
