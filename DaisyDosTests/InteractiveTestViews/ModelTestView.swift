//
//  ModelTestView.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import SwiftUI
@testable import DaisyDos
import SwiftData
@testable import DaisyDos

struct ModelTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [Task]
    @Query private var habits: [Habit]
    @Query private var tags: [Tag]

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Model Testing")
                    .font(.title)
                    .padding()

                // Tasks Section
                VStack(alignment: .leading) {
                    Text("Tasks (\(tasks.count))")
                        .font(.headline)
                    ForEach(tasks) { task in
                        HStack {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(task.isCompleted ? .green : .gray)
                            Text(task.title)
                            Spacer()
                            Text("\(task.tags.count) tags")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

                // Habits Section
                VStack(alignment: .leading) {
                    Text("Habits (\(habits.count))")
                        .font(.headline)
                    ForEach(habits) { habit in
                        HStack {
                            Text(habit.title)
                            Spacer()
                            Text("Streak: \(habit.currentStreak)")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(habit.tags.count) tags")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

                // Tags Section
                VStack(alignment: .leading) {
                    Text("Tags (\(tags.count))")
                        .font(.headline)
                    ForEach(tags) { tag in
                        HStack {
                            Image(systemName: tag.sfSymbolName)
                                .foregroundColor(tag.color)
                            Text(tag.name)
                            Spacer()
                            Text("\(tag.totalItemCount) items")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

                // Test Actions
                VStack(spacing: 10) {
                    HStack(spacing: 15) {
                        Button("Add Test Data") {
                            addTestData()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Clear All") {
                            clearAllData()
                        }
                        .buttonStyle(.bordered)
                    }

                    // Constraint Testing
                    HStack(spacing: 10) {
                        Button("Test Tag Limits") {
                            testTagLimits()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.orange)

                        Button("Test Unique Names") {
                            testUniqueConstraints()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.orange)
                    }

                    // Relationship Testing
                    HStack(spacing: 10) {
                        Button("Test Relationships") {
                            testRelationshipIntegrity()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.blue)

                        Button("Test Persistence") {
                            testPersistence()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.purple)
                    }

                    // Edge Case Testing
                    HStack(spacing: 10) {
                        Button("Test Edge Cases") {
                            testEdgeCases()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)

                        Button("Run All Tests") {
                            runAllTests()
                        }
                        .buttonStyle(.borderedProminent)
                        .foregroundColor(.white)
                    }
                }

                Spacer()
            }
            .padding()
        }
    }

    private func addTestData() {
        // Create tags
        let workTag = Tag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")
        let personalTag = Tag(name: "Personal", sfSymbolName: "house", colorName: "green")
        let healthTag = Tag(name: "Health", sfSymbolName: "heart", colorName: "red")

        modelContext.insert(workTag)
        modelContext.insert(personalTag)
        modelContext.insert(healthTag)

        // Create tasks
        let task1 = Task(title: "Complete SwiftData models")
        let task2 = Task(title: "Review project documentation")
        let task3 = Task(title: "Plan workout routine")

        // Test tag assignment and validation
        _ = task1.addTag(workTag)
        _ = task2.addTag(workTag)
        _ = task3.addTag(personalTag)
        _ = task3.addTag(healthTag)

        modelContext.insert(task1)
        modelContext.insert(task2)
        modelContext.insert(task3)

        // Create habits
        let habit1 = Habit(title: "Daily Exercise", habitDescription: "30 minutes of exercise")
        let habit2 = Habit(title: "Read Daily", habitDescription: "Read for 20 minutes")

        _ = habit1.addTag(healthTag)
        _ = habit2.addTag(personalTag)

        habit1.markCompleted()  // Test streak logic
        habit2.currentStreak = 5

        modelContext.insert(habit1)
        modelContext.insert(habit2)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save test data: \(error)")
        }
    }

    private func clearAllData() {
        // Clear all data
        for task in tasks {
            modelContext.delete(task)
        }
        for habit in habits {
            modelContext.delete(habit)
        }
        for tag in tags {
            modelContext.delete(tag)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }

    // MARK: - Constraint Testing

    private func testTagLimits() {
        print("🧪 Testing Tag Limits...")

        // Test per-item tag limit (max 3 tags per task/habit)
        let task = Task(title: "Tag Limit Test Task")
        let tag1 = Tag(name: "Tag1", sfSymbolName: "1.circle", colorName: "red")
        let tag2 = Tag(name: "Tag2", sfSymbolName: "2.circle", colorName: "blue")
        let tag3 = Tag(name: "Tag3", sfSymbolName: "3.circle", colorName: "green")
        let tag4 = Tag(name: "Tag4", sfSymbolName: "4.circle", colorName: "yellow")

        modelContext.insert(tag1)
        modelContext.insert(tag2)
        modelContext.insert(tag3)
        modelContext.insert(tag4)
        modelContext.insert(task)

        // Should succeed (within limit)
        let result1 = task.addTag(tag1)
        let result2 = task.addTag(tag2)
        let result3 = task.addTag(tag3)

        // Should fail (exceeds limit)
        let result4 = task.addTag(tag4)

        print("✅ Tag 1 added: \(result1)")
        print("✅ Tag 2 added: \(result2)")
        print("✅ Tag 3 added: \(result3)")
        print("❌ Tag 4 added: \(result4) (should be false)")
        print("📊 Final tag count: \(task.tags.count) (should be 3)")

        // Test system-wide tag limit (max 30 tags)
        let canCreateMore = Tag.canCreateNewTag(in: modelContext)
        print("🌐 Can create more tags: \(canCreateMore)")
        print("🏷️ Current tag count: \(tags.count)")

        do {
            try modelContext.save()
            print("✅ Tag limit test data saved successfully")
        } catch {
            print("❌ Failed to save tag limit test: \(error)")
        }
    }

    private func testUniqueConstraints() {
        print("🧪 Testing Unique Constraints...")

        // Test unique tag name constraint
        let tag1 = Tag(name: "UniqueTest", sfSymbolName: "star", colorName: "blue")
        let tag2 = Tag(name: "UniqueTest", sfSymbolName: "heart", colorName: "red") // Same name - should fail

        modelContext.insert(tag1)
        modelContext.insert(tag2)

        do {
            try modelContext.save()
            print("❌ UNEXPECTED: Duplicate tag names were allowed!")
        } catch {
            print("✅ EXPECTED: Unique constraint prevented duplicate names: \(error.localizedDescription)")
            // Remove the duplicate tag to clean up
            modelContext.delete(tag2)
        }

        // Test UUID uniqueness (should always be unique due to UUID generation)
        let tag3 = Tag(name: "Test3", sfSymbolName: "circle", colorName: "green")
        let tag4 = Tag(name: "Test4", sfSymbolName: "square", colorName: "purple")

        print("🆔 Tag3 ID: \(tag3.id)")
        print("🆔 Tag4 ID: \(tag4.id)")
        print("✅ UUIDs are unique: \(tag3.id != tag4.id)")

        modelContext.insert(tag3)
        modelContext.insert(tag4)

        do {
            try modelContext.save()
            print("✅ Unique constraint test completed")
        } catch {
            print("❌ Failed to save unique constraint test: \(error)")
        }
    }

    // MARK: - Relationship Testing

    private func testRelationshipIntegrity() {
        print("🧪 Testing Relationship Integrity...")

        // Create test objects
        let task = Task(title: "Relationship Test Task")
        let habit = Habit(title: "Relationship Test Habit", habitDescription: "Testing relationships")
        let sharedTag = Tag(name: "SharedTag", sfSymbolName: "link", colorName: "blue")

        modelContext.insert(task)
        modelContext.insert(habit)
        modelContext.insert(sharedTag)

        // Test bidirectional relationships
        print("🔗 Testing bidirectional Task-Tag relationship...")
        let taskTagResult = task.addTag(sharedTag)
        print("  Task added tag: \(taskTagResult)")
        print("  Task tag count: \(task.tags.count)")
        print("  Tag task count: \(sharedTag.tasks.count)")
        print("  Bidirectional consistency: \(task.tags.contains(sharedTag) && sharedTag.tasks.contains(task))")

        print("🔗 Testing bidirectional Habit-Tag relationship...")
        let habitTagResult = habit.addTag(sharedTag)
        print("  Habit added tag: \(habitTagResult)")
        print("  Habit tag count: \(habit.tags.count)")
        print("  Tag habit count: \(sharedTag.habits.count)")
        print("  Bidirectional consistency: \(habit.tags.contains(sharedTag) && sharedTag.habits.contains(habit))")

        print("📊 Tag total item count: \(sharedTag.totalItemCount) (should be 2)")

        // Test removing relationships
        print("🗑️ Testing relationship removal...")
        task.removeTag(sharedTag)
        print("  After removal - Task tag count: \(task.tags.count)")
        print("  After removal - Tag task count: \(sharedTag.tasks.count)")
        print("  After removal - Tag total items: \(sharedTag.totalItemCount)")

        do {
            try modelContext.save()
            print("✅ Relationship integrity test completed")
        } catch {
            print("❌ Failed to save relationship test: \(error)")
        }
    }

    private func testPersistence() {
        print("🧪 Testing SwiftData Persistence...")

        // Create test data
        let persistenceTag = Tag(name: "PersistenceTest", sfSymbolName: "database", colorName: "green")
        let persistenceTask = Task(title: "Persistence Test Task")
        let persistenceHabit = Habit(title: "Persistence Test Habit", habitDescription: "Testing persistence")

        // Establish relationships
        _ = persistenceTask.addTag(persistenceTag)
        _ = persistenceHabit.addTag(persistenceTag)

        modelContext.insert(persistenceTag)
        modelContext.insert(persistenceTask)
        modelContext.insert(persistenceHabit)

        // Save and verify
        do {
            try modelContext.save()
            print("✅ Test data saved successfully")

            // Immediately verify the data exists
            let tagDescriptor = FetchDescriptor<Tag>(predicate: #Predicate<Tag> { tag in
                tag.name == "PersistenceTest"
            })

            let taskDescriptor = FetchDescriptor<Task>(predicate: #Predicate<Task> { task in
                task.title == "Persistence Test Task"
            })

            let habitDescriptor = FetchDescriptor<Habit>(predicate: #Predicate<Habit> { habit in
                habit.title == "Persistence Test Habit"
            })

            let fetchedTags = try modelContext.fetch(tagDescriptor)
            let fetchedTasks = try modelContext.fetch(taskDescriptor)
            let fetchedHabits = try modelContext.fetch(habitDescriptor)

            print("📊 Persistence verification:")
            print("  Found tags: \(fetchedTags.count)")
            print("  Found tasks: \(fetchedTasks.count)")
            print("  Found habits: \(fetchedHabits.count)")

            if let tag = fetchedTags.first,
               let task = fetchedTasks.first,
               let habit = fetchedHabits.first {
                print("  Tag has \(tag.tasks.count) tasks and \(tag.habits.count) habits")
                print("  Task has \(task.tags.count) tags")
                print("  Habit has \(habit.tags.count) tags")
                print("  Relationships preserved: \(tag.totalItemCount == 2 && task.tags.count == 1 && habit.tags.count == 1)")
            }

            print("✅ Persistence test completed successfully")

        } catch {
            print("❌ Persistence test failed: \(error)")
        }
    }

    // MARK: - Edge Case Testing

    private func testEdgeCases() {
        print("🧪 Testing Edge Cases...")

        // Test adding same tag multiple times
        let task = Task(title: "Edge Case Task")
        let tag = Tag(name: "EdgeCaseTag", sfSymbolName: "exclamationmark.triangle", colorName: "orange")

        modelContext.insert(task)
        modelContext.insert(tag)

        let firstAdd = task.addTag(tag)
        let secondAdd = task.addTag(tag) // Should fail - already exists

        print("🔄 Adding same tag twice:")
        print("  First add result: \(firstAdd)")
        print("  Second add result: \(secondAdd) (should be false)")
        print("  Final tag count: \(task.tags.count) (should be 1)")

        // Test removing non-existent tag
        let unrelatedTag = Tag(name: "UnrelatedTag", sfSymbolName: "questionmark", colorName: "gray")
        modelContext.insert(unrelatedTag)

        let initialCount = task.tags.count
        task.removeTag(unrelatedTag)
        print("🗑️ Removing non-existent tag:")
        print("  Count before: \(initialCount)")
        print("  Count after: \(task.tags.count) (should be same)")

        // Test habit streak logic edge cases
        let habit = Habit(title: "Edge Case Habit", habitDescription: "Testing edge cases")
        modelContext.insert(habit)

        print("📈 Habit streak edge cases:")
        print("  Initial streak: \(habit.currentStreak)")
        print("  Can mark completed: \(habit.canMarkCompleted())")

        habit.markCompleted()
        print("  After first completion - streak: \(habit.currentStreak)")
        print("  Can mark completed again today: \(habit.canMarkCompleted()) (should be false)")

        // Try to mark completed again (should not increase streak)
        let previousStreak = habit.currentStreak
        habit.markCompleted()
        print("  After second attempt - streak: \(habit.currentStreak) (should be same as previous: \(previousStreak))")

        // Test tag validation edge cases
        print("🏷️ Tag validation edge cases:")
        print("  Can create new tag: \(Tag.canCreateNewTag(in: modelContext))")

        // Test the relationship counts
        let sharedTag = Tag(name: "SharedEdgeTag", sfSymbolName: "asterisk", colorName: "purple")
        modelContext.insert(sharedTag)

        _ = task.addTag(sharedTag)
        _ = habit.addTag(sharedTag)

        print("  Shared tag total items: \(sharedTag.totalItemCount)")
        print("  Shared tag is in use: \(sharedTag.isInUse)")

        do {
            try modelContext.save()
            print("✅ Edge case testing completed")
        } catch {
            print("❌ Edge case testing failed: \(error)")
        }
    }

    private func runAllTests() {
        print("🚀 Running All Comprehensive Tests...")
        print("==================================================")

        testTagLimits()
        print("------------------------------")

        testUniqueConstraints()
        print("------------------------------")

        testRelationshipIntegrity()
        print("------------------------------")

        testPersistence()
        print("------------------------------")

        testEdgeCases()
        print("==================================================")
        print("🎉 All tests completed!")
    }
}

#Preview {
    ModelTestView()
        .modelContainer(for: [Task.self, Habit.self, Tag.self], inMemory: true)
}