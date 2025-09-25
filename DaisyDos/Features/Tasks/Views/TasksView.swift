//
//  TasksView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
import SwiftData

struct TasksView: View {
    @Environment(TaskManager.self) private var taskManager
    @Environment(TagManager.self) private var tagManager
    @State private var searchText = ""
    @State private var showingAddTask = false

    var body: some View {
        NavigationStack {
            VStack {
                if filteredTasks.isEmpty && searchText.isEmpty {
                    // Empty state
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "list.bullet.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)

                        Text("No Tasks Yet")
                            .font(.title2.bold())

                        Text("Start organizing your work by creating your first task.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    Spacer()

                } else {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search tasks...", text: $searchText)
                    }
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)

                    // Task list
                    List {
                        ForEach(filteredTasks) { task in
                            TaskRowView(task: task)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }

    private var filteredTasks: [Task] {
        if searchText.isEmpty {
            return taskManager.allTasks
        } else {
            return taskManager.searchTasksSafely(query: searchText)
        }
    }
}

// MARK: - Task Row View

private struct TaskRowView: View {
    let task: Task
    @Environment(TaskManager.self) private var taskManager

    var body: some View {
        HStack {
            Button(action: {
                taskManager.toggleTaskCompletionSafely(task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)

                HStack {
                    Text("Created: \(task.createdDate, format: .dateTime.month().day())")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !task.tags.isEmpty {
                        Text("• \(task.tags.count) tag\(task.tags.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            Button(action: {
                taskManager.deleteTaskSafely(task)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Task View

private struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskManager.self) private var taskManager
    @State private var taskTitle = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("New Task") {
                    TextField("Task title", text: $taskTitle)
                }

                Section {
                    Text("More options will be available in future updates.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            taskManager.createTaskSafely(title: taskTitle)
                            dismiss()
                        }
                    }
                    .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Task.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return TasksView()
        .modelContainer(container)
        .environment(TaskManager(modelContext: container.mainContext))
        .environment(TagManager(modelContext: container.mainContext))
}