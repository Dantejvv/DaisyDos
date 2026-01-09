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
    @Environment(TaskCompletionToastManager.self) private var toastManager
    @Environment(NavigationManager.self) private var navigationManager
    @Query(
        filter: #Predicate<Task> { task in
            task.parentTask == nil && !task.isCompleted
        },
        sort: \Task.createdDate,
        order: .reverse
    ) private var rootTasks: [Task]

    @State private var searchText = ""
    @State private var isSearchPresented = false
    @State private var showingAddTask = false
    @State private var taskToEdit: Task?
    @State private var taskToDelete: Task?
    @State private var showingDeleteConfirmation = false
    @State private var showingBulkDeleteConfirmation = false
    @State private var taskToDetail: Task?
    @State private var isMultiSelectMode = false
    @State private var selectedTasks: Set<Task.ID> = []
    @AppStorage("taskSortOption") private var sortOptionRaw: String = TaskSortOption.title.rawValue

    private var sortOption: TaskSortOption {
        get { TaskSortOption(rawValue: sortOptionRaw) ?? .title }
    }

    enum TaskSortOption: String, CaseIterable {
        case title = "Title"
        case priority = "Priority"
        case creationDate = "Creation Date"
        case dueDate = "Due Date"

        var systemImage: String {
            switch self {
            case .title: return "textformat.abc"
            case .priority: return "exclamationmark.triangle"
            case .creationDate: return "calendar"
            case .dueDate: return "calendar.badge.clock"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Content area
                if rootTasks.isEmpty {
                    // Empty state
                    emptyStateView
                } else if sortedTasks.isEmpty && !searchText.isEmpty {
                    // No search results state
                    noSearchResultsView
                } else {
                    // Task list
                    taskListView
                }
            }
            .navigationTitle("Tasks")
            .searchable(text: $searchText, isPresented: $isSearchPresented, prompt: "Search tasks...")
            .navigationTabCleanup(
                navigationManager: navigationManager,
                currentTab: .tasks,
                searchText: $searchText,
                isSearchPresented: $isSearchPresented,
                isMultiSelectMode: $isMultiSelectMode,
                selectedItems: $selectedTasks
            )
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
                    HStack {
                        if !isMultiSelectMode {
                            // Sort picker button - ALWAYS visible
                            Menu {
                                Text("Sort Tasks By")
                                    .font(.headline)

                                Divider()

                                ForEach(TaskSortOption.allCases, id: \.self) { option in
                                    Button(action: {
                                        sortOptionRaw = option.rawValue
                                    }) {
                                        Label(option.rawValue, systemImage: option.systemImage)
                                        if sortOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: sortOption.systemImage)
                            }
                        }

                        if isMultiSelectMode {
                            Menu {
                                Button("Select All") {
                                    selectedTasks = Set(sortedTasks.map(\.id))
                                }
                                .disabled(selectedTasks.count == sortedTasks.count)

                                Button("Select None") {
                                    selectedTasks.removeAll()
                                }
                                .disabled(selectedTasks.isEmpty)
                            } label: {
                                Image(systemName: "ellipsis")
                            }
                        } else {
                            // Add button - ALWAYS visible
                            Button(action: {
                                showingAddTask = true
                            }) {
                                Image(systemName: "plus")
                            }
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
                    taskToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    taskToDelete = nil
                }
            } message: { task in
                Text("Are you sure you want to delete '\(task.title)'?")
            }
            .onChange(of: showingDeleteConfirmation) { _, isShowing in
                // Clear taskToDelete when confirmation is dismissed without deletion
                if !isShowing && taskToDelete != nil {
                    // Check if the task still exists (wasn't deleted)
                    if rootTasks.contains(where: { $0.id == taskToDelete?.id }) {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            taskToDelete = nil
                        }
                    }
                }
            }
            .alert(
                "Delete \(selectedTasks.count) Tasks",
                isPresented: $showingBulkDeleteConfirmation
            ) {
                Button("Delete \(selectedTasks.count) Tasks", role: .destructive) {
                    bulkDelete()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete \(selectedTasks.count) selected tasks? This action cannot be undone.")
            }
            .errorAlert(error: Binding(
                get: { taskManager.lastError },
                set: { taskManager.lastError = $0 }
            ))
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

    private var sortedTasks: [Task] {
        let tasks = Array(filteredTasks)

        switch sortOption {
        case .creationDate:
            return tasks.sorted { $0.createdDate > $1.createdDate }
        case .dueDate:
            return tasks.sorted { task1, task2 in
                // Tasks with no due date go to the end
                switch (task1.dueDate, task2.dueDate) {
                case (nil, nil): return task1.createdDate > task2.createdDate
                case (nil, _): return false
                case (_, nil): return true
                case (let date1?, let date2?): return date1 < date2
                }
            }
        case .priority:
            return tasks.sorted { task1, task2 in
                if task1.priority == task2.priority {
                    return task1.createdDate > task2.createdDate
                }
                return task1.priority.sortOrder > task2.priority.sortOrder
            }
        case .title:
            return tasks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }


    // MARK: - Task Row Builder

    @ViewBuilder
    private func taskRow(for task: Task) -> some View {
        TaskRowView(
            task: task,
            onToggleCompletion: {
                if !isMultiSelectMode {
                    handleTaskCompletion(task)
                }
            },
            onEdit: {
                if !isMultiSelectMode {
                    taskToEdit = task
                }
            },
            onDelete: {
                if !isMultiSelectMode {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        taskToDelete = task
                    }
                    // Delay showing confirmation to let overlay render first
                    DispatchQueue.main.async {
                        showingDeleteConfirmation = true
                    }
                }
            },
            onTagAssignment: nil // Removed tag button from TasksView
        )
        .overlay {
            if taskToDelete?.id == task.id {
                Color.daisyBackground
            }
        }
        .animation(.none, value: taskToDelete)
        .rowStyling(
            isSelected: isMultiSelectMode && selectedTasks.contains(task.id),
            accentColor: .daisyTask,
            onTap: {
                if isMultiSelectMode {
                    toggleTaskSelection(task)
                } else {
                    taskToDetail = task
                }
            }
        )
        .standardRowSwipeActions(
            isMultiSelectMode: isMultiSelectMode,
            accentColor: .daisyTask,
            onDelete: {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    taskToDelete = task
                }
                // Delay showing confirmation to let overlay render first
                DispatchQueue.main.async {
                    showingDeleteConfirmation = true
                }
            },
            onEdit: {
                taskToEdit = task
            },
            leadingAction: {
                DuplicateSwipeAction {
                    _ = taskManager.duplicateTaskSafely(task)
                }
            }
        )
    }


    // MARK: - Bulk Action Toolbar

    @ViewBuilder
    private var bulkActionToolbar: some View {
        BulkActionToolbar(selectedCount: selectedTasks.count) {
            // Bulk completion toggle
            Button(action: {
                bulkToggleCompletion()
            }) {
                Label("Toggle Complete", systemImage: "checkmark.circle")
                    .labelStyle(.iconOnly)
                    .font(.title3)
            }
            .foregroundColor(.daisySuccess)

            // Bulk delete
            Button(action: {
                showingBulkDeleteConfirmation = true
            }) {
                Label("Delete", systemImage: "trash")
                    .labelStyle(.iconOnly)
                    .font(.title3)
            }
            .foregroundColor(.daisyError)
        }
    }


    // MARK: - Helper Methods

    private func handleTaskCompletion(_ task: Task) {
        // Toggle completion
        _ = taskManager.toggleTaskCompletionSafely(task)

        // Show undo toast if task was completed (not uncompleted)
        if task.isCompleted {
            toastManager.showCompletionToast(for: task) {
                // Undo action - toggle back
                _ = taskManager.toggleTaskCompletionSafely(task)
            }
        }
    }

    private func toggleTaskSelection(_ task: Task) {
        selectedTasks.toggleMembership(task.id)
    }

    private func bulkToggleCompletion() {
        let tasksToUpdate = sortedTasks.filter { selectedTasks.contains($0.id) }
        var completedTasks: [Task] = []

        for task in tasksToUpdate {
            _ = taskManager.toggleTaskCompletionSafely(task)
            if task.isCompleted {
                completedTasks.append(task)
            }
        }

        // Show toast if any tasks were completed
        if let lastTask = completedTasks.last {
            toastManager.showCompletionToast(for: lastTask) { [completedTasks] in
                // Undo all completed tasks
                for task in completedTasks {
                    _ = taskManager.toggleTaskCompletionSafely(task)
                }
            }
        }

        selectedTasks.removeAll()
        isMultiSelectMode = false
    }


    private func bulkDelete() {
        let tasksToDelete = sortedTasks.filter { selectedTasks.contains($0.id) }
        for task in tasksToDelete {
            _ = taskManager.deleteTaskSafely(task)
        }
        selectedTasks.removeAll()
        isMultiSelectMode = false
    }

    private func deleteTask(_ task: Task) {
        _ = taskManager.deleteTaskSafely(task)
    }

    // MARK: - View Components

    private var emptyStateView: some View {
        VStack {
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

                Text("Tap the + button to create your first task!")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }

    private var noSearchResultsView: some View {
        SearchEmptyStateView(searchText: searchText)
    }

    private var taskListView: some View {
        List {
            ForEach(sortedTasks) { task in
                taskRow(for: task)
            }
        }
        .listStyle(PlainListStyle())
    }
}


#Preview {
    let container = try! ModelContainer(for: Task.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return TasksView()
        .modelContainer(container)
        .environment(TaskManager(modelContext: container.mainContext))
        .environment(TagManager(modelContext: container.mainContext))
}