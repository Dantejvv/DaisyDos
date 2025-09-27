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
    @Query(sort: \Task.createdDate, order: .reverse) private var allTasks: [Task]
    @State private var searchText = ""
    @State private var showingAddTask = false
    @State private var showingTagAssignment = false
    @State private var taskToAssignTags: Task?
    @State private var taskToEdit: Task?
    @State private var taskToDelete: Task?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            VStack {
                if allTasks.isEmpty {
                    // Empty state when no tasks exist at all
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
                    // Show search bar and tasks when we have tasks
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search tasks...", text: $searchText)
                    }
                    .padding()
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)

                    // Task list or search results
                    if filteredTasks.isEmpty && !searchText.isEmpty {
                        // Show "no search results" state
                        VStack(spacing: 16) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)

                            Text("No results for '\(searchText)'")
                                .font(.title2.bold())

                            Text("Try adjusting your search terms")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        Spacer()
                    } else {
                        // Show task list
                        List {
                            ForEach(filteredTasks) { task in
                                TaskRowView(
                                    task: task,
                                    onToggleCompletion: {
                                        _ = taskManager.toggleTaskCompletionSafely(task)
                                    },
                                    onEdit: {
                                        taskToEdit = task
                                    },
                                    onDelete: {
                                        taskToDelete = task
                                        showingDeleteConfirmation = true
                                    },
                                    onTagAssignment: {
                                        taskToAssignTags = task
                                        showingTagAssignment = true
                                    },
                                    displayMode: .detailed
                                )
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
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
            .sheet(isPresented: $showingTagAssignment) {
                if let task = taskToAssignTags {
                    TagAssignmentSheet.forTask(task: task) { newTags in
                        // Update task tags
                        for tag in task.tags {
                            if !newTags.contains(tag) {
                                _ = taskManager.removeTagSafely(tag, from: task)
                            }
                        }

                        for tag in newTags {
                            if !task.tags.contains(tag) {
                                _ = taskManager.addTagSafely(tag, to: task)
                            }
                        }
                    }
                }
            }
            .sheet(item: $taskToEdit) { task in
                // Task edit view would go here
                // For now, just show AddTaskView as placeholder
                AddTaskView()
            }
            .alert(
                "Delete Task",
                isPresented: $showingDeleteConfirmation,
                presenting: taskToDelete
            ) { task in
                Button("Delete", role: .destructive) {
                    _ = taskManager.deleteTaskSafely(task)
                }
                Button("Cancel", role: .cancel) { }
            } message: { task in
                Text("Are you sure you want to delete '\(task.title)'?")
            }
        }
    }

    private var filteredTasks: [Task] {
        if searchText.isEmpty {
            return allTasks
        } else {
            return taskManager.searchTasksSafely(query: searchText)
        }
    }

    // MARK: - Helper Methods

    private func deleteTask(_ task: Task) {
        _ = taskManager.deleteTaskSafely(task)
    }
}


#Preview {
    let container = try! ModelContainer(for: Task.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return TasksView()
        .modelContainer(container)
        .environment(TaskManager(modelContext: container.mainContext))
        .environment(TagManager(modelContext: container.mainContext))
}