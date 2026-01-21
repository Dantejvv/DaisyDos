//
//  TestDataGenerator.swift
//  DaisyDos
//
//  Created for testing and debugging purposes
//

import SwiftUI
import SwiftData

/// Helper to generate comprehensive test data for debugging
struct TestDataGenerator {
    let modelContext: ModelContext

    /// Creates a comprehensive set of test data covering many scenarios
    func generateTestData() {
        let calendar = Calendar.current
        let now = Date()

        // MARK: - Create Tags

        let tagData: [(String, String, String)] = [
            ("Work", "briefcase", "blue"),
            ("Personal", "person", "purple"),
            ("Urgent", "exclamationmark.triangle", "red"),
            ("Health", "heart", "pink"),
            ("Finance", "dollarsign.circle", "green"),
            ("Learning", "book", "orange"),
            ("Home", "house", "cyan"),
            ("Social", "person.2", "indigo"),
            ("Creative", "paintbrush", "yellow"),
            ("Fitness", "figure.run", "mint")
        ]

        var tags: [Tag] = []
        for (name, icon, colorName) in tagData {
            let tag = Tag(name: name, sfSymbolName: icon, colorName: colorName)
            modelContext.insert(tag)
            tags.append(tag)
        }

        // MARK: - Create Tasks

        let taskTemplates: [(String, String, Priority, Int, Bool, String?)] = [
            // Title, Description, Priority, DaysOffset, HasSubtasks, RecurrenceType
            ("Review quarterly reports", "Go through Q4 financial reports and prepare summary for stakeholders", .high, -2, true, nil),
            ("Call dentist for appointment", "Schedule 6-month checkup and cleaning", .medium, 0, false, nil),
            ("Buy groceries", "Milk, eggs, bread, vegetables, fruits, chicken", .low, 1, false, "daily"),
            ("Prepare presentation", "Create slides for Monday's client meeting with sales data", .high, 3, true, nil),
            ("Water plants", "All indoor and outdoor plants need watering", .none, 0, false, "weekly"),
            ("Pay electricity bill", "Due date: end of month, set up autopay", .medium, 7, false, "monthly"),
            ("Read 'Atomic Habits' chapter 5", "Continue reading productivity book, take notes", .low, -5, false, nil),
            ("Update resume", "Add recent projects and achievements from this year", .medium, 14, false, nil),
            ("Clean garage", "Organize tools and dispose of old items we don't use", .low, 2, true, nil),
            ("Submit expense report", "Include receipts from business trip to SF", .high, -1, false, nil),
            ("Team standup meeting", "Daily sync with development team at 9am", .none, 0, false, "daily"),
            ("Weekly planning session", "Review last week and plan upcoming week's priorities", .medium, 0, true, "weekly"),
            ("Backup computer files", "Full system backup to external drive and cloud", .medium, 5, false, "monthly"),
            ("Call Mom", "Catch up and check in, ask about her doctor appointment", .low, 0, false, "weekly"),
            ("Review code PR #234", "Backend API changes for user authentication service", .high, 0, true, nil),
            ("Renew car insurance", "Policy expires next month, shop for better rates", .high, 30, false, nil),
            ("Organize vacation photos", "Sort and backup photos from Hawaii trip", .none, 10, true, nil),
            ("Practice guitar", "30 minutes of chord progressions and scales", .low, 0, false, "daily"),
            ("Meal prep for week", "Prepare healthy lunches and dinners for next 5 days", .medium, -1, true, "weekly"),
            ("Fix leaky faucet", "Kitchen sink has been dripping, need to replace washer", .medium, 2, false, nil),
            ("Write blog post", "Article about productivity tips and time management", .low, 7, true, nil),
            ("Research vacation destinations", "Look into summer trip options - Italy or Greece?", .none, 20, false, nil),
            ("Schedule car maintenance", "Oil change and tire rotation, check brakes", .medium, 4, false, nil),
            ("Respond to client emails", "Follow up on pending inquiries from this week", .high, 0, false, "daily"),
            ("Update project documentation", "README and API docs need to reflect recent changes", .medium, 3, true, nil),
            ("Order birthday gift", "For Sarah's birthday next month - she likes books", .low, 15, false, nil),
            ("Deep clean bathroom", "Scrub tiles, restock supplies, organize cabinet", .low, 1, false, "weekly"),
            ("Review investment portfolio", "Check performance and consider rebalancing", .medium, 10, false, "monthly"),
            ("Brainstorm product ideas", "New features for Q2 roadmap planning", .none, 5, true, nil),
            ("File tax documents", "Organize receipts and forms for accountant", .high, -10, true, nil)
        ]

        for (index, template) in taskTemplates.enumerated() {
            let task = Task(
                title: template.0,
                taskDescription: template.1,
                priority: template.2
            )

            // Set due date based on offset
            if template.3 != 999 {
                task.dueDate = calendar.date(byAdding: .day, value: template.3, to: now)
            }

            // Add recurrence if specified
            if let recurrenceType = template.5 {
                switch recurrenceType {
                case "daily":
                    task.recurrenceRule = RecurrenceRule(frequency: .daily, interval: 1)
                case "weekly":
                    task.recurrenceRule = RecurrenceRule(frequency: .weekly, interval: 1)
                case "monthly":
                    task.recurrenceRule = RecurrenceRule(frequency: .monthly, interval: 1)
                default:
                    break
                }
            }

            // Complete some tasks (roughly 30%)
            if index % 3 == 0 {
                task.isCompleted = true
                task.completedDate = calendar.date(byAdding: .hour, value: -index, to: now)
            }

            // Add subtasks if specified
            if template.4 {
                let subtaskCount = (index % 4) + 1 // 1-4 subtasks
                for i in 0..<subtaskCount {
                    let subtask = Task(
                        title: "Subtask \(i + 1) for \(template.0)",
                        taskDescription: "",
                        priority: .none
                    )
                    subtask.parentTask = task
                    subtask.subtaskOrder = i
                    // Complete some subtasks
                    if i % 2 == 0 {
                        subtask.isCompleted = true
                        subtask.completedDate = now
                    }
                    modelContext.insert(subtask)
                }
            }

            // Assign random tags (0-3 tags)
            let tagCount = index % 4
            let shuffledTags = tags.shuffled()
            for i in 0..<min(tagCount, shuffledTags.count) {
                _ = task.addTag(shuffledTags[i])
            }

            modelContext.insert(task)
        }

        // MARK: - Create Habits

        let habitTemplates: [(String, String, Priority, Int, Bool, String)] = [
            ("Morning meditation", "10 minutes of mindfulness practice to start the day", .high, 45, false, "daily"),
            ("Drink 8 glasses of water", "Stay hydrated throughout the day for better health", .medium, 12, false, "daily"),
            ("Exercise", "30 minutes cardio or strength training", .high, 0, true, "daily"),
            ("Journal", "Write down thoughts, reflections, and gratitude", .low, 7, false, "daily"),
            ("Read for 30 minutes", "Fiction or non-fiction books for learning", .medium, 23, false, "daily"),
            ("Take vitamins", "Daily multivitamin and supplements", .medium, 89, false, "daily"),
            ("Practice Spanish", "Duolingo lessons and vocabulary review", .low, 156, false, "daily"),
            ("Stretch routine", "Full body stretching exercises for flexibility", .medium, 3, true, "daily"),
            ("No social media after 9pm", "Digital detox before bed for better sleep", .high, 5, false, "daily"),
            ("Meal prep", "Prepare healthy meals for the week ahead", .medium, 8, true, "weekly"),
            ("Call family", "Stay connected with loved ones regularly", .low, 15, false, "weekly"),
            ("Review finances", "Check budget, expenses, and savings progress", .medium, 4, false, "weekly"),
            ("Clean workspace", "Organize desk, files, and supplies", .low, 11, false, "weekly"),
            ("Plan weekly goals", "Set clear objectives for the coming week", .high, 20, false, "weekly"),
            ("Grocery shopping", "Stock up on healthy food for the week", .medium, 6, true, "weekly"),
            ("Long walk in nature", "Outdoor exercise and fresh air for mental health", .low, 2, false, "weekly"),
            ("Deep work session", "2 hours focused work on important project", .high, 9, false, "weekly"),
            ("Social activity", "Connect with friends or join community event", .medium, 1, false, "weekly"),
            ("Review monthly goals", "Check progress on long-term objectives", .high, 3, false, "monthly"),
            ("Deep clean house", "Thorough cleaning of all rooms and organization", .low, 2, true, "monthly")
        ]

        for (index, template) in habitTemplates.enumerated() {
            let habit = Habit(
                title: template.0,
                habitDescription: template.1,
                priority: template.2
            )

            // Set recurrence
            switch template.5 {
            case "daily":
                habit.recurrenceRule = RecurrenceRule(frequency: .daily, interval: 1)
            case "weekly":
                habit.recurrenceRule = RecurrenceRule(frequency: .weekly, interval: 1)
            case "monthly":
                habit.recurrenceRule = RecurrenceRule(frequency: .monthly, interval: 1)
            default:
                break
            }

            // Set streak
            habit.currentStreak = template.3

            if template.3 > 0 {
                habit.longestStreak = template.3 + Int.random(in: 0...10)
            }

            // Complete some habits for today (50% chance)
            if index % 2 == 0 {
                habit.lastCompletedDate = now
            }

            // Add skip history to some habits using HabitSkip model
            if index % 5 == 0 && template.3 > 0 {
                let skip1 = HabitSkip(
                    habit: habit,
                    skippedDate: calendar.date(byAdding: .day, value: -7, to: now)!
                )
                modelContext.insert(skip1)

                let skip2 = HabitSkip(
                    habit: habit,
                    skippedDate: calendar.date(byAdding: .day, value: -14, to: now)!
                )
                modelContext.insert(skip2)
            }

            // Add subtasks if specified
            if template.4 {
                let subtaskCount = (index % 3) + 1 // 1-3 subtasks for habits
                for i in 0..<subtaskCount {
                    let subtask = HabitSubtask(title: "Step \(i + 1): \(template.0)")
                    subtask.parentHabit = habit
                    subtask.subtaskOrder = i
                    // Complete some subtasks
                    if i % 2 == 0 {
                        subtask.isCompletedToday = true
                        subtask.lastCompletedDate = now
                    }
                    modelContext.insert(subtask)
                }
            }

            // Assign random tags (0-3 tags)
            let tagCount = (index % 4)
            let shuffledTags = tags.shuffled()
            for i in 0..<min(tagCount, shuffledTags.count) {
                _ = habit.addTag(shuffledTags[i])
            }

            modelContext.insert(habit)
        }

        // Save all changes
        try? modelContext.save()
    }
}

// MARK: - Test Data Button View

struct TestDataGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingConfirmation = false
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Test Data Generator")
                            .font(.headline)

                        Text("Generate comprehensive test data including:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Label("10 Tags (various colors & icons)", systemImage: "tag")
                            Label("30 Tasks (varied states)", systemImage: "checkmark.circle")
                            Label("20 Habits (varied streaks)", systemImage: "repeat.circle")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)

                    Button(action: {
                        showingConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Generate Test Data")
                        }
                    }
                    .disabled(isGenerating)
                } header: {
                    Text("Generate")
                } footer: {
                    Text("This will create sample data for testing. Existing data will not be affected.")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Test Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Generate Test Data?", isPresented: $showingConfirmation) {
                Button("Generate", role: .destructive) {
                    generateData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will create 10 tags, 30 tasks, and 20 habits with various test scenarios.")
            }
        }
    }

    private func generateData() {
        isGenerating = true

        let generator = TestDataGenerator(modelContext: modelContext)
        generator.generateTestData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isGenerating = false
            dismiss()
        }
    }
}

#Preview {
    TestDataGeneratorView()
        .modelContainer(for: [Task.self, Habit.self, Tag.self], inMemory: true)
}
