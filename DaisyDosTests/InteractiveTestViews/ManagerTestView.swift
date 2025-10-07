//
//  ManagerTestView.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import SwiftUI
import SwiftData

struct ManagerTestView: View {
    @Environment(TaskManager.self) private var taskManager
    @Environment(HabitManager.self) private var habitManager
    @Environment(TagManager.self) private var tagManager

    @State private var newTaskTitle = ""
    @State private var newHabitTitle = ""
    @State private var newTagName = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Manager Testing")
                        .font(.title)
                        .padding()

                    // Environment Injection Status
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Environment Injection Status")
                            .font(.headline)
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("TaskManager: Connected")
                        }
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("HabitManager: Connected")
                        }
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("TagManager: Connected")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)

                    // Task Manager Testing
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TaskManager (@Observable)")
                            .font(.headline)

                        // Statistics (computed properties)
                        HStack {
                            VStack {
                                Text("\(taskManager.taskCount)")
                                    .font(.title2)
                                    .bold()
                                Text("Total")
                                    .font(.caption)
                            }
                            Spacer()
                            VStack {
                                Text("\(taskManager.completedTaskCount)")
                                    .font(.title2)
                                    .bold()
                                Text("Completed")
                                    .font(.caption)
                            }
                            Spacer()
                            VStack {
                                Text("\(taskManager.pendingTaskCount)")
                                    .font(.title2)
                                    .bold()
                                Text("Pending")
                                    .font(.caption)
                            }
                            Spacer()
                            VStack {
                                Text("\(String(format: "%.1f%%", taskManager.completionRate * 100))")
                                    .font(.title2)
                                    .bold()
                                Text("Rate")
                                    .font(.caption)
                            }
                        }

                        // Create new task
                        HStack {
                            TextField("New task title", text: $newTaskTitle)
                                .textFieldStyle(.roundedBorder)
                            Button("Add") {
                                if !newTaskTitle.isEmpty {
                                    _ = taskManager.createTask(title: newTaskTitle)
                                    newTaskTitle = ""
                                }
                            }
                            .disabled(newTaskTitle.isEmpty)
                        }

                        // Recent tasks
                        if !taskManager.allTasks.isEmpty {
                            Text("Recent Tasks:")
                                .font(.subheadline)
                                .bold()
                            ForEach(Array(taskManager.allTasks.prefix(3)), id: \.id) { task in
                                HStack {
                                    Button(action: {
                                        taskManager.toggleTaskCompletion(task)
                                    }) {
                                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(task.isCompleted ? .green : .gray)
                                    }
                                    Text(task.title)
                                    Spacer()
                                    Button("Delete") {
                                        taskManager.deleteTask(task)
                                    }
                                    .foregroundColor(.red)
                                    .font(.caption)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemBlue).opacity(0.1))
                    .cornerRadius(8)

                    // Habit Manager Testing
                    VStack(alignment: .leading, spacing: 12) {
                        Text("HabitManager (@Observable)")
                            .font(.headline)

                        // Statistics (computed properties)
                        HStack {
                            VStack {
                                Text("\(habitManager.habitCount)")
                                    .font(.title2)
                                    .bold()
                                Text("Total")
                                    .font(.caption)
                            }
                            Spacer()
                            VStack {
                                Text("\(habitManager.completedTodayCount)")
                                    .font(.title2)
                                    .bold()
                                Text("Today")
                                    .font(.caption)
                            }
                            Spacer()
                            VStack {
                                Text("\(habitManager.longestActiveStreak)")
                                    .font(.title2)
                                    .bold()
                                Text("Best")
                                    .font(.caption)
                            }
                            Spacer()
                            VStack {
                                Text("\(String(format: "%.1f%%", habitManager.todayCompletionRate * 100))")
                                    .font(.title2)
                                    .bold()
                                Text("Rate")
                                    .font(.caption)
                            }
                        }

                        // Create new habit
                        HStack {
                            TextField("New habit title", text: $newHabitTitle)
                                .textFieldStyle(.roundedBorder)
                            Button("Add") {
                                if !newHabitTitle.isEmpty {
                                    _ = habitManager.createHabit(title: newHabitTitle)
                                    newHabitTitle = ""
                                }
                            }
                            .disabled(newHabitTitle.isEmpty)
                        }

                        // Recent habits
                        if !habitManager.allHabits.isEmpty {
                            Text("Recent Habits:")
                                .font(.subheadline)
                                .bold()
                            ForEach(Array(habitManager.allHabits.prefix(3)), id: \.id) { habit in
                                HStack {
                                    Button(action: {
                                        _ = habitManager.markHabitCompleted(habit)
                                    }) {
                                        Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(habit.isCompletedToday ? .green : .gray)
                                    }
                                    VStack(alignment: .leading) {
                                        Text(habit.title)
                                        Text("Streak: \(habit.currentStreak)")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                    Spacer()
                                    Button("Delete") {
                                        _ = habitManager.deleteHabit(habit)
                                    }
                                    .foregroundColor(.red)
                                    .font(.caption)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemOrange).opacity(0.1))
                    .cornerRadius(8)

                    // Tag Manager Testing
                    VStack(alignment: .leading, spacing: 12) {
                        Text("TagManager (@Observable)")
                            .font(.headline)

                        // Statistics (computed properties)
                        HStack {
                            VStack {
                                Text("\(tagManager.tagCount)")
                                    .font(.title2)
                                    .bold()
                                Text("Total")
                                    .font(.caption)
                            }
                            Spacer()
                            VStack {
                                Text("\(tagManager.usedTagCount)")
                                    .font(.title2)
                                    .bold()
                                Text("Used")
                                    .font(.caption)
                            }
                            Spacer()
                            VStack {
                                Text("\(tagManager.remainingTagSlots)")
                                    .font(.title2)
                                    .bold()
                                Text("Available")
                                    .font(.caption)
                            }
                            Spacer()
                            VStack {
                                Text(tagManager.canCreateNewTag ? "✅" : "❌")
                                    .font(.title2)
                                Text("Can Create")
                                    .font(.caption)
                            }
                        }

                        // Create new tag
                        HStack {
                            TextField("New tag name", text: $newTagName)
                                .textFieldStyle(.roundedBorder)
                            Button("Add") {
                                if !newTagName.isEmpty {
                                    let color = tagManager.suggestTagColor()
                                    let symbol = tagManager.suggestTagSymbol()
                                    _ = tagManager.createTag(name: newTagName, sfSymbolName: symbol, colorName: color)
                                    newTagName = ""
                                }
                            }
                            .disabled(newTagName.isEmpty || !tagManager.canCreateNewTag)
                        }

                        // Recent tags
                        if !tagManager.allTags.isEmpty {
                            Text("Recent Tags:")
                                .font(.subheadline)
                                .bold()
                            ForEach(Array(tagManager.allTags.prefix(5)), id: \.id) { tag in
                                HStack {
                                    Image(systemName: tag.sfSymbolName)
                                        .foregroundColor(tag.color)
                                    Text(tag.name)
                                    Spacer()
                                    Text("\(tag.totalItemCount)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    if !tag.isInUse {
                                        Button("Delete") {
                                            _ = tagManager.deleteTag(tag)
                                        }
                                        .foregroundColor(.red)
                                        .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemPurple).opacity(0.1))
                    .cornerRadius(8)

                    // @Bindable Testing Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("@Bindable Wrapper Testing")
                            .font(.headline)

                        if let firstTask = taskManager.allTasks.first {
                            @Bindable var bindableTask = firstTask
                            VStack(alignment: .leading) {
                                Text("Two-way binding with first task:")
                                    .font(.subheadline)
                                TextField("Task Title", text: $bindableTask.title)
                                    .textFieldStyle(.roundedBorder)
                                Toggle("Completed", isOn: $bindableTask.isCompleted)
                                Text("Changes automatically save to SwiftData")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("Add a task above to test @Bindable")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemYellow).opacity(0.1))
                    .cornerRadius(8)

                    // Test Actions
                    VStack(spacing: 10) {
                        Button("Create Test Data") {
                            createTestData()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Clear All Data") {
                            clearAllData()
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Manager Tests")
        }
    }

    private func createTestData() {
        // Create some tags first
        let workTag = tagManager.createTag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")
        let personalTag = tagManager.createTag(name: "Personal", sfSymbolName: "house", colorName: "green")
        let healthTag = tagManager.createTag(name: "Health", sfSymbolName: "heart", colorName: "red")

        // Create tasks
        let task1 = taskManager.createTaskSafely(title: "Test @Observable reactivity")!
        let task2 = taskManager.createTaskSafely(title: "Validate environment injection")!

        // Add tags to tasks
        if let workTag = workTag {
            _ = taskManager.addTag(workTag, to: task1)
        }
        if let personalTag = personalTag {
            _ = taskManager.addTag(personalTag, to: task2)
        }

        // Create habits
        guard case .success(let habit1) = habitManager.createHabit(title: "Test Manager Pattern"),
              case .success(let habit2) = habitManager.createHabit(title: "Validate Computed Properties") else {
            return
        }

        // Add tags to habits
        if let healthTag = healthTag {
            _ = habitManager.addTag(healthTag, to: habit1)
        }
        if let workTag = workTag {
            _ = habitManager.addTag(workTag, to: habit2)
        }

        // Mark some completed
        taskManager.toggleTaskCompletionSafely(task1)
        _ = habitManager.markHabitCompleted(habit1)
    }

    private func clearAllData() {
        // Delete all tasks
        taskManager.deleteTasks(taskManager.allTasks)

        // Delete all habits
        _ = habitManager.deleteHabits(habitManager.allHabits)

        // Force delete all tags
        for tag in tagManager.allTags {
            tagManager.forceDeleteTag(tag)
        }
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: Task.self, Habit.self, Tag.self)
        return ManagerTestView()
            .modelContainer(container)
            .environment(TaskManager(modelContext: container.mainContext))
            .environment(HabitManager(modelContext: container.mainContext))
            .environment(TagManager(modelContext: container.mainContext))
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}