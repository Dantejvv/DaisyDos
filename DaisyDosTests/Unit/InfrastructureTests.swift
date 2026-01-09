import Testing
import SwiftData
@testable import DaisyDos

/// Infrastructure validation tests - Verify test helpers and setup work correctly
@Suite("Infrastructure Tests")
struct InfrastructureTests {

    @Test("TestHelpers creates valid container")
    func testContainerCreation() async throws {
        // Create container using our helper
        let container = try TestHelpers.createTestContainer()

        // Verify container is valid (11 entities: Task, Habit, Tag, HabitCompletion, HabitStreak, HabitSkip, HabitSubtask, TaskLogEntry, TaskAttachment, HabitAttachment, PendingRecurrence)
        #expect(container.schema.entities.count == 11)

        // Verify we can create a context
        let context = ModelContext(container)
        #expect(context != nil)
    }

    @Test("TestHelpers creates valid context")
    func testContextCreation() async throws {
        // Create context using our helper
        let context = try TestHelpers.createTestContext()

        // Verify context is valid
        #expect(context != nil)
    }

    @Test("Container isolation - each test gets fresh container")
    func testContainerIsolation1() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        // Create a task
        let task = Task(title: "Test Task 1")
        context.insert(task)
        try context.save()

        // Verify task exists
        let descriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(descriptor)
        #expect(tasks.count == 1)
    }

    @Test("Container isolation - second test has empty container")
    func testContainerIsolation2() async throws {
        let container = try TestHelpers.createTestContainer()
        let context = ModelContext(container)

        // Verify container is empty (previous test didn't pollute)
        let descriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(descriptor)
        #expect(tasks.count == 0)
    }
}
