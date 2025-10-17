//
//  SubtaskRowView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI
import SwiftData

struct SubtaskRowView: View {
    let subtask: Task
    let onToggleCompletion: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    init(
        subtask: Task,
        onToggleCompletion: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.subtask = subtask
        self.onToggleCompletion = onToggleCompletion
        self.onEdit = onEdit
        self.onDelete = onDelete
    }

    var body: some View {
        HStack(spacing: 12) {
            // Completion toggle
            Button(action: onToggleCompletion) {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(subtask.isCompleted ? .daisySuccess : .daisyTextSecondary)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel(subtask.isCompleted ? "Mark as incomplete" : "Mark as complete")

            // Subtask content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(subtask.title)
                        .font(.body)
                        .strikethrough(subtask.isCompleted)
                        .foregroundColor(subtask.isCompleted ? .daisyTextSecondary : .daisyText)
                        .lineLimit(2)

                    Spacer()

                    // Priority indicator
                    subtask.priority.indicatorView()
                        .font(.caption)
                }

                // Subtask metadata
                if !subtask.taskDescription.isEmpty {
                    Text(subtask.taskDescription)
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                        .lineLimit(1)
                }
            }

            // Action menu
            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }

                Divider()

                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.body)
                    .foregroundColor(.daisyTextSecondary)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color.daisySurface)
        .cornerRadius(8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Subtask: \(subtask.title)")
        .accessibilityAddTraits(subtask.isCompleted ? .isSelected : [])
    }

}

// MARK: - Display Mode Variants

extension SubtaskRowView {
    /// Compact variant for limited space
    static func compact(
        subtask: Task,
        onToggleCompletion: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            // Completion toggle
            Button(action: onToggleCompletion) {
                Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(subtask.isCompleted ? .daisySuccess : .daisyTextSecondary)
                    .font(.body)
            }
            .buttonStyle(.plain)

            // Title
            Text(subtask.title)
                .font(.body)
                .strikethrough(subtask.isCompleted)
                .foregroundColor(subtask.isCompleted ? .daisyTextSecondary : .daisyText)
                .lineLimit(1)

            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }
}

#Preview("Single Subtask") {
    let container = try! ModelContainer(
        for: Task.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    // Create parent task
    let parentTask = Task(
        title: "Parent Task",
        taskDescription: "Main task with subtasks",
        priority: .high
    )

    // Create subtask
    let subtask = Task(
        title: "Review documentation",
        taskDescription: "Check all docs for accuracy",
        priority: .medium
    )

    container.mainContext.insert(parentTask)
    container.mainContext.insert(subtask)
    _ = parentTask.addSubtask(subtask)

    return SubtaskRowView(
        subtask: subtask,
        onToggleCompletion: {
            subtask.toggleCompletion()
        },
        onEdit: {
            print("Edit subtask")
        },
        onDelete: {
            print("Delete subtask")
        }
    )
    .modelContainer(container)
    .padding()
}