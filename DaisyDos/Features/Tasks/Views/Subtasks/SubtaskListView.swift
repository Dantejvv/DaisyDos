//
//  SubtaskListView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI
import SwiftData

struct SubtaskListView: View {
    @Environment(TaskManager.self) private var taskManager
    let parentTask: Task
    let isReadOnly: Bool

    @State private var showingSubtaskCreation = false
    @State private var subtaskToEdit: Task?
    @State private var subtaskToDelete: Task?
    @State private var showingDeleteConfirmation = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    private var displayedSubtasks: [Task] {
        // Use ordered subtasks which respects the subtaskOrder property
        return parentTask.orderedSubtasks
    }

    var body: some View {
        VStack(spacing: 0) {
            if parentTask.hasSubtasks {
                ForEach(displayedSubtasks, id: \.id) { subtask in
                    SubtaskRowView(
                        subtask: subtask,
                        isReadOnly: isReadOnly,
                        onToggleCompletion: {
                            toggleSubtaskCompletion(subtask)
                        },
                        onEdit: {
                            subtaskToEdit = subtask
                        },
                        onDelete: {
                            subtaskToDelete = subtask
                            showingDeleteConfirmation = true
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 2)
                    .overlay(
                        // Reordering arrows (hidden in read-only mode)
                        Group {
                            if !isReadOnly {
                                HStack {
                                    Spacer()
                                    VStack(spacing: 4) {
                                        // Up arrow
                                        Button(action: {
                                            moveSubtaskUp(subtask)
                                        }) {
                                            Image(systemName: "chevron.up")
                                                .font(.caption)
                                                .foregroundColor(canMoveUp(subtask) ? .daisyTask : .daisyTextSecondary)
                                                .frame(width: 32, height: 24)
                                                .background(Color.daisySurface.opacity(0.8), in: RoundedRectangle(cornerRadius: 6))
                                        }
                                        .disabled(!canMoveUp(subtask))

                                        // Down arrow
                                        Button(action: {
                                            moveSubtaskDown(subtask)
                                        }) {
                                            Image(systemName: "chevron.down")
                                                .font(.caption)
                                                .foregroundColor(canMoveDown(subtask) ? .daisyTask : .daisyTextSecondary)
                                                .frame(width: 32, height: 24)
                                                .background(Color.daisySurface.opacity(0.8), in: RoundedRectangle(cornerRadius: 6))
                                        }
                                        .disabled(!canMoveDown(subtask))
                                    }
                                    .padding(.trailing, 8)
                                }
                            }
                        },
                        alignment: .trailing
                    )
                }
            } else {
                // Empty state for no subtasks
                emptyStateView
            }

            // Add subtask button
            addSubtaskButton
        }
        .sheet(isPresented: $showingSubtaskCreation) {
            SubtaskCreationView(parentTask: parentTask)
        }
        .sheet(item: $subtaskToEdit) { subtask in
            // For now, use TaskEditView - will create dedicated SubtaskEditView later
            TaskEditView(task: subtask)
        }
        .alert(
            "Delete Subtask",
            isPresented: $showingDeleteConfirmation,
            presenting: subtaskToDelete
        ) { subtask in
            Button("Delete", role: .destructive) {
                deleteSubtask(subtask)
            }
            Button("Cancel", role: .cancel) { }
        } message: { subtask in
            Text("Are you sure you want to delete '\(subtask.title)'?")
        }
        .alert("Subtask Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.circle")
                .font(.system(size: 32))
                .foregroundColor(.daisyTextSecondary)

            Text("No subtasks yet")
                .font(.headline)
                .foregroundColor(.daisyTextSecondary)

            Text("Break this task into smaller, manageable steps")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Add Subtask Button

    @ViewBuilder
    private var addSubtaskButton: some View {
        if !isReadOnly {
            Button(action: {
                showingSubtaskCreation = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.daisyTask)
                    Text("Add Subtask")
                        .font(.body.weight(.medium))
                        .foregroundColor(.daisyTask)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.daisySurface.opacity(0.5))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Actions

    private func toggleSubtaskCompletion(_ subtask: Task) {
        let result = taskManager.toggleSubtaskCompletion(
            subtask,
            strategy: .hybrid,
            propagateToParent: true
        )

        switch result {
        case .success:
            // Success - UI will update automatically via @Query
            break
        case .failure:
            // Handle error with user feedback
            errorMessage = "Unable to update subtask completion. Please try again."
            showingErrorAlert = true
        }
    }

    private func deleteSubtask(_ subtask: Task) {
        let success = taskManager.deleteTaskSafely(subtask)
        if !success {
            errorMessage = "Unable to delete subtask. Please try again."
            showingErrorAlert = true
        }
    }

    // MARK: - Drag & Drop Support

    // MARK: - Reordering Methods

    private func moveSubtaskUp(_ subtask: Task) {
        let result = taskManager.moveSubtaskUp(subtask)
        switch result {
        case .success:
            break
        case .failure:
            errorMessage = "Unable to reorder subtasks. Please try again."
            showingErrorAlert = true
        }
    }

    private func moveSubtaskDown(_ subtask: Task) {
        let result = taskManager.moveSubtaskDown(subtask)
        switch result {
        case .success:
            break
        case .failure:
            errorMessage = "Unable to reorder subtasks. Please try again."
            showingErrorAlert = true
        }
    }

    private func canMoveUp(_ subtask: Task) -> Bool {
        guard let currentIndex = parentTask.orderedSubtasks.firstIndex(of: subtask) else { return false }
        return currentIndex > 0
    }

    private func canMoveDown(_ subtask: Task) -> Bool {
        guard let currentIndex = parentTask.orderedSubtasks.firstIndex(of: subtask) else { return false }
        return currentIndex < parentTask.orderedSubtasks.count - 1
    }

}


#Preview("Subtask List - With Subtasks") {
    let container = try! ModelContainer(
        for: Task.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let taskManager = TaskManager(modelContext: container.mainContext)

    // Create parent task with subtasks
    let parentTask = Task(
        title: "Build Mobile App",
        taskDescription: "Complete iOS application",
        priority: .high
    )

    let subtask1 = Task(title: "Setup Xcode Project", priority: .medium)
    let subtask2 = Task(title: "Design User Interface", priority: .medium)
    let subtask3 = Task(title: "Implement Core Features", priority: .high)

    container.mainContext.insert(parentTask)
    container.mainContext.insert(subtask1)
    container.mainContext.insert(subtask2)
    container.mainContext.insert(subtask3)

    _ = parentTask.addSubtask(subtask1)
    _ = parentTask.addSubtask(subtask2)
    _ = parentTask.addSubtask(subtask3)

    subtask1.setCompleted(true)

    return SubtaskListView(parentTask: parentTask, isReadOnly: false)
        .modelContainer(container)
        .environment(taskManager)
        .background(Color.daisyBackground)
}

#Preview("Subtask List - Empty") {
    let container = try! ModelContainer(
        for: Task.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let taskManager = TaskManager(modelContext: container.mainContext)

    let parentTask = Task(
        title: "Empty Parent Task",
        taskDescription: "No subtasks yet",
        priority: .medium
    )

    container.mainContext.insert(parentTask)

    return SubtaskListView(parentTask: parentTask, isReadOnly: false)
        .modelContainer(container)
        .environment(taskManager)
        .background(Color.daisyBackground)
}