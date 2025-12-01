#!/usr/bin/env swift

import Foundation
import SwiftUI
import SwiftData

// This script creates comprehensive test data for DaisyDos
// Run this from within the app or copy the logic into a test/preview

/*
COMPREHENSIVE TEST DATA CREATION SCRIPT

This creates:
- 10 Tags with various colors and icons
- 30 Tasks with varying:
  * Priorities (None, Low, Medium, High)
  * Due dates (past, today, future, none)
  * Completion status
  * Subtasks (0-5 subtasks)
  * Recurrence rules (daily, weekly, monthly, none)
  * Tag assignments (0-5 tags)
  * Rich text descriptions
- 20 Habits with varying:
  * Priorities
  * Current streaks (0-100 days)
  * Completion status
  * Subtasks (0-3 subtasks)
  * Recurrence rules
  * Tag assignments
  * Skip history

Usage: Copy this code into a preview or test helper function
*/

func createComprehensiveTestData(modelContext: ModelContext) {
    let calendar = Calendar.current
    let now = Date()

    // MARK: - Create Tags

    let tagData: [(String, String, Color)] = [
        ("Work", "briefcase", .blue),
        ("Personal", "person", .purple),
        ("Urgent", "exclamationmark.triangle", .red),
        ("Health", "heart", .pink),
        ("Finance", "dollarsign.circle", .green),
        ("Learning", "book", .orange),
        ("Home", "house", .cyan),
        ("Social", "person.2", .indigo),
        ("Creative", "paintbrush", .yellow),
        ("Fitness", "figure.run", .mint)
    ]

    var tags: [Tag] = []
    for (name, icon, color) in tagData {
        let tag = Tag(name: name, color: color, icon: icon)
        modelContext.insert(tag)
        tags.append(tag)
    }

    // MARK: - Create Tasks

    let taskTemplates: [(String, String, Priority, Int, Bool, String?)] = [
        // Title, Description, Priority, DaysOffset, HasSubtasks, RecurrenceType
        ("Review quarterly reports", "Go through Q4 financial reports and prepare summary", .high, -2, true, nil), // Overdue with subtasks
        ("Call dentist for appointment", "Schedule 6-month checkup", .medium, 0, false, nil), // Due today
        ("Buy groceries", "Milk, eggs, bread, vegetables, fruits", .low, 1, false, "daily"), // Tomorrow, recurring
        ("Prepare presentation", "Create slides for Monday's client meeting", .high, 3, true, nil), // Future, high priority
        ("Water plants", "All indoor and outdoor plants", .none, 0, false, "weekly"), // Today, recurring weekly
        ("Pay electricity bill", "Due date: end of month", .medium, 7, false, "monthly"), // Next week, monthly
        ("Read 'Atomic Habits' chapter 5", "Continue reading productivity book", .low, -5, false, nil), // Overdue, no priority
        ("Update resume", "Add recent projects and achievements", .medium, 14, false, nil), // Two weeks out
        ("Clean garage", "Organize tools and dispose of old items", .low, 2, true, nil), // Soon, with subtasks
        ("Submit expense report", "Include receipts from business trip", .high, -1, false, nil), // Overdue yesterday
        ("Team standup meeting", "Daily sync with development team", .none, 0, false, "daily"), // Today, daily recurring
        ("Weekly planning session", "Review and plan upcoming week", .medium, 0, true, "weekly"), // Today, weekly
        ("Backup computer files", "Full system backup to external drive", .medium, 5, false, "monthly"), // Future, monthly
        ("Call Mom", "Catch up and check in", .low, 0, false, "weekly"), // Today, weekly
        ("Review code PR #234", "Backend API changes for user service", .high, 0, true, nil), // Today, high priority
        ("Renew car insurance", "Policy expires next month", .high, 30, false, nil), // Future, important
        ("Organize photos", "Sort and backup vacation photos", .none, 10, true, nil), // Future, low priority
        ("Practice guitar", "30 minutes of chord progressions", .low, 0, false, "daily"), // Today, daily
        ("Meal prep for week", "Prepare lunches and dinners", .medium, -1, true, "weekly"), // Yesterday, weekly
        ("Fix leaky faucet", "Kitchen sink needs repair", .medium, 2, false, nil), // Soon
        ("Write blog post", "Article about productivity tips", .low, 7, true, nil), // Next week
        ("Research vacation destinations", "Look into summer trip options", .none, 20, false, nil), // Far future
        ("Schedule car maintenance", "Oil change and tire rotation", .medium, 4, false, nil), // This week
        ("Respond to client emails", "Follow up on pending inquiries", .high, 0, false, "daily"), // Today, urgent
        ("Update project documentation", "README and API docs", .medium, 3, true, nil), // Soon
        ("Order birthday gift", "For Sarah's birthday next month", .low, 15, false, nil), // Couple weeks
        ("Clean bathroom", "Deep clean and restock supplies", .low, 1, false, "weekly"), // Tomorrow, weekly
        ("Review investment portfolio", "Check performance and rebalance", .medium, 10, false, "monthly"), // Next week, monthly
        ("Brainstorm product ideas", "New features for next quarter", .none, 5, true, nil), // This week
        ("File tax documents", "Organize receipts and forms", .high, -10, true, nil) // Very overdue
    ]

    for (index, template) in taskTemplates.enumerated() {
        let task = Task(
            title: template.0,
            taskDescription: template.1,
            priority: template.2
        )

        // Set due date based on offset
        if template.3 != 999 { // 999 means no due date
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
                    priority: .none,
                    parentTask: task
                )
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
        // Title, Description, Priority, Streak, HasSubtasks, RecurrenceType
        ("Morning meditation", "10 minutes of mindfulness practice", .high, 45, false, "daily"),
        ("Drink 8 glasses of water", "Stay hydrated throughout the day", .medium, 12, false, "daily"),
        ("Exercise", "30 minutes cardio or strength training", .high, 0, true, "daily"), // New habit
        ("Journal", "Write down thoughts and reflections", .low, 7, false, "daily"),
        ("Read for 30 minutes", "Fiction or non-fiction books", .medium, 23, false, "daily"),
        ("Take vitamins", "Daily multivitamin and supplements", .medium, 89, false, "daily"),
        ("Practice language", "Duolingo Spanish lessons", .low, 156, false, "daily"),
        ("Stretch routine", "Full body stretching exercises", .medium, 3, true, "daily"),
        ("No social media after 9pm", "Digital detox before bed", .high, 5, false, "daily"),
        ("Meal prep", "Prepare healthy meals for the week", .medium, 8, true, "weekly"),
        ("Call family", "Stay connected with loved ones", .low, 15, false, "weekly"),
        ("Review finances", "Check budget and expenses", .medium, 4, false, "weekly"),
        ("Clean workspace", "Organize desk and supplies", .low, 11, false, "weekly"),
        ("Plan weekly goals", "Set objectives for the coming week", .high, 20, false, "weekly"),
        ("Grocery shopping", "Healthy food for the week", .medium, 6, true, "weekly"),
        ("Long walk in nature", "Outdoor exercise and fresh air", .low, 2, false, "weekly"),
        ("Deep work session", "2 hours focused work on important project", .high, 9, false, "weekly"),
        ("Social activity", "Connect with friends or community", .medium, 1, false, "weekly"),
        ("Review monthly goals", "Check progress on long-term objectives", .high, 3, false, "monthly"),
        ("Deep clean house", "Thorough cleaning of all rooms", .low, 2, true, "monthly")
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

        // Add skip history to some habits
        if index % 5 == 0 {
            habit.skipDates = [
                calendar.date(byAdding: .day, value: -7, to: now)!,
                calendar.date(byAdding: .day, value: -14, to: now)!
            ]
            habit.skipReasons = [
                "Was sick": calendar.date(byAdding: .day, value: -7, to: now)!,
                "Traveling": calendar.date(byAdding: .day, value: -14, to: now)!
            ]
        }

        // Add subtasks if specified
        if template.4 {
            let subtaskCount = (index % 3) + 1 // 1-3 subtasks for habits
            for i in 0..<subtaskCount {
                let subtask = HabitSubtask(
                    title: "Step \(i + 1): \(template.0)",
                    orderIndex: i,
                    habit: habit
                )
                // Complete some subtasks
                if i % 2 == 0 {
                    subtask.isCompleted = true
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

    print("✅ Created comprehensive test data:")
    print("   - 10 Tags")
    print("   - 30 Tasks (varied priorities, dates, subtasks, recurrence)")
    print("   - 20 Habits (varied streaks, subtasks, recurrence)")
}

// MARK: - Preview Helper

#Preview("Test Data") {
    let container = try! ModelContainer(
        for: Task.self, Habit.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let context = container.mainContext
    createComprehensiveTestData(modelContext: context)

    return ContentView()
        .modelContainer(container)
        .environment(TaskManager(modelContext: context))
        .environment(HabitManager(modelContext: context))
        .environment(TagManager(modelContext: context))
        .environment(TaskCompletionToastManager())
        .environment(HabitCompletionToastManager())
        .environment(NavigationManager())
}
