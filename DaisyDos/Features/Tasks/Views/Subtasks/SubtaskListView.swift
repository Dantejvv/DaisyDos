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
    let nestingLevel: Int

    @State private var showingSubtaskCreation = false
    @State private var subtaskToEdit: Task?
    @State private var subtaskToDelete: Task?
    @State private var showingDeleteConfirmation = false

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
                        nestingLevel: nestingLevel,
                        onToggleCompletion: {
                            toggleSubtaskCompletion(subtask)
                        },
                        onEdit: {
                            subtaskToEdit = subtask
                        },
                        onDelete: {
                            subtaskToDelete = subtask
                            showingDeleteConfirmation = true
                        },
                        onAddSubtask: {
                            createNestedSubtask(for: subtask)
                        },
                        onNestedToggleCompletion: { nestedTask in
                            toggleSubtaskCompletion(nestedTask)
                        },
                        onNestedEdit: { nestedTask in
                            subtaskToEdit = nestedTask
                        },
                        onNestedDelete: { nestedTask in
                            subtaskToDelete = nestedTask
                            showingDeleteConfirmation = true
                        },
                        onNestedAddSubtask: { nestedTask in
                            createNestedSubtask(for: nestedTask)
                        }
                    )
                    .cornerRadius(8)
                    .padding(.horizontal, nestingLevel > 0 ? 8 : 16)
                    .padding(.vertical, 2)
                    .overlay(
                        // Reordering arrows (always shown in manage mode)
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
            Text("Are you sure you want to delete '\(subtask.title)' and all its subtasks?")
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
        .padding(.horizontal, nestingLevel > 0 ? 8 : 16)
        .padding(.top, 8)
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
        case .failure(let error):
            // Handle error with user feedback
            print("Failed to toggle subtask completion: \(error)")
            // TODO: Show user-friendly error message
        }
    }

    private func createNestedSubtask(for parentSubtask: Task) {
        // For now, we'll use the creation sheet
        // In the future, this could open a specific nested creation interface
        showingSubtaskCreation = true
    }

    private func deleteSubtask(_ subtask: Task) {
        let success = taskManager.deleteTaskSafely(subtask)
        if !success {
            // Handle error
            print("Failed to delete subtask")
        }
    }

    // MARK: - Drag & Drop Support

    // MARK: - Reordering Methods

    private func moveSubtaskUp(_ subtask: Task) {
        let result = taskManager.moveSubtaskUp(subtask)
        switch result {
        case .success:
            break
        case .failure(let error):
            // TODO: Show user-friendly error message
            print("Failed to move subtask up: \(error)")
        }
    }

    private func moveSubtaskDown(_ subtask: Task) {
        let result = taskManager.moveSubtaskDown(subtask)
        switch result {
        case .success:
            break
        case .failure(let error):
            // TODO: Show user-friendly error message
            print("Failed to move subtask down: \(error)")
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
    let nestedSubtask = Task(title: "Create wireframes", priority: .low)

    container.mainContext.insert(parentTask)
    container.mainContext.insert(subtask1)
    container.mainContext.insert(subtask2)
    container.mainContext.insert(subtask3)
    container.mainContext.insert(nestedSubtask)

    _ = parentTask.addSubtask(subtask1)
    _ = parentTask.addSubtask(subtask2)
    _ = parentTask.addSubtask(subtask3)
    _ = subtask2.addSubtask(nestedSubtask)

    subtask1.setCompleted(true)

    return SubtaskListView(parentTask: parentTask, nestingLevel: 0)
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

    return SubtaskListView(parentTask: parentTask, nestingLevel: 0)
        .modelContainer(container)
        .environment(taskManager)
        .background(Color.daisyBackground)
}