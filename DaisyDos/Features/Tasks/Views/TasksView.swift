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
    @Query(
        filter: #Predicate<Task> { task in
            task.parentTask == nil
        },
        sort: \Task.createdDate,
        order: .reverse
    ) private var rootTasks: [Task]
    @State private var searchText = ""
    @State private var showingAddTask = false
    @State private var taskToEdit: Task?
    @State private var taskToDelete: Task?
    @State private var taskToDetail: Task?
    @State private var showingDeleteConfirmation = false
    @State private var isMultiSelectMode = false
    @State private var selectedTasks: Set<Task.ID> = []

    var body: some View {
        NavigationStack {
            VStack {
                if rootTasks.isEmpty {
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
                                HStack {
                                    // Multi-select checkbox
                                    if isMultiSelectMode {
                                        Button(action: {
                                            toggleTaskSelection(task)
                                        }) {
                                            Image(systemName: selectedTasks.contains(task.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedTasks.contains(task.id) ? .daisyTask : .daisyTextSecondary)
                                        }
                                        .buttonStyle(.plain)
                                        .frame(minWidth: 44, minHeight: 44)
                                    }

                                    TaskRowView(
                                        task: task,
                                        onToggleCompletion: {
                                            if !isMultiSelectMode {
                                                _ = taskManager.toggleTaskCompletionSafely(task)
                                            }
                                        },
                                        onEdit: {
                                            if !isMultiSelectMode {
                                                taskToEdit = task
                                            }
                                        },
                                        onDelete: {
                                            if !isMultiSelectMode {
                                                taskToDelete = task
                                                showingDeleteConfirmation = true
                                            }
                                        },
                                        onTagAssignment: nil, // Removed tag button from TasksView
                                        displayMode: isMultiSelectMode ? .compact : .detailed,
                                        showsTagButton: false // Disable tag button
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        if isMultiSelectMode {
                                            toggleTaskSelection(task)
                                        } else {
                                            taskToDetail = task
                                        }
                                    }
                                    .contextMenu {
                                        if !isMultiSelectMode {
                                            Button(action: {
                                                taskToDetail = task
                                            }) {
                                                Label("View Details", systemImage: "info.circle")
                                            }

                                            Button(action: {
                                                taskToEdit = task
                                            }) {
                                                Label("Edit", systemImage: "pencil")
                                            }

                                            Button(action: {
                                                _ = taskManager.duplicateTaskSafely(task)
                                            }) {
                                                Label("Duplicate", systemImage: "plus.square.on.square")
                                            }

                                            Divider()

                                            Button(action: {
                                                taskToDelete = task
                                                showingDeleteConfirmation = true
                                            }) {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            .foregroundColor(.daisyError)
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !rootTasks.isEmpty {
                        Button(isMultiSelectMode ? "Done" : "Select") {
                            withAnimation {
                                isMultiSelectMode.toggle()
                                if !isMultiSelectMode {
                                    selectedTasks.removeAll()
                                }
                            }
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isMultiSelectMode {
                        Menu {
                            Button("Select All") {
                                selectedTasks = Set(filteredTasks.map(\.id))
                            }
                            .disabled(selectedTasks.count == filteredTasks.count)

                            Button("Select None") {
                                selectedTasks.removeAll()
                            }
                            .disabled(selectedTasks.isEmpty)
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    } else {
                        Button(action: {
                            showingAddTask = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isMultiSelectMode && !selectedTasks.isEmpty {
                    bulkActionToolbar
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .sheet(item: $taskToEdit) { task in
                TaskEditView(task: task)
            }
            .navigationDestination(item: $taskToDetail) { task in
                TaskDetailView(task: task)
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
            return rootTasks
        } else {
            // Filter search results to only include root tasks
            return taskManager.searchTasksSafely(query: searchText).filter { $0.parentTask == nil }
        }
    }

    // MARK: - Bulk Action Toolbar

    @ViewBuilder
    private var bulkActionToolbar: some View {
        HStack {
            Text("\(selectedTasks.count) selected")
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)

            Spacer()

            HStack(spacing: 20) {
                // Bulk completion toggle
                Button(action: {
                    bulkToggleCompletion()
                }) {
                    Label("Toggle Complete", systemImage: "checkmark.circle")
                }
                .foregroundColor(.daisySuccess)

                // Bulk delete
                Button(action: {
                    bulkDelete()
                }) {
                    Label("Delete", systemImage: "trash")
                }
                .foregroundColor(.daisyError)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    // MARK: - Helper Methods

    private func toggleTaskSelection(_ task: Task) {
        if selectedTasks.contains(task.id) {
            selectedTasks.remove(task.id)
        } else {
            selectedTasks.insert(task.id)
        }
    }

    private func bulkToggleCompletion() {
        let tasksToUpdate = filteredTasks.filter { selectedTasks.contains($0.id) }
        for task in tasksToUpdate {
            _ = taskManager.toggleTaskCompletionSafely(task)
        }
        selectedTasks.removeAll()
        isMultiSelectMode = false
    }


    private func bulkDelete() {
        let tasksToDelete = filteredTasks.filter { selectedTasks.contains($0.id) }
        for task in tasksToDelete {
            _ = taskManager.deleteTaskSafely(task)
        }
        selectedTasks.removeAll()
        isMultiSelectMode = false
    }

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