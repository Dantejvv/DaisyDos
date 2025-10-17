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
    let nestingLevel: Int
    let onToggleCompletion: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    // Optional action forwarders for nested subtasks
    var onNestedToggleCompletion: ((Task) -> Void)? = nil
    var onNestedEdit: ((Task) -> Void)? = nil
    var onNestedDelete: ((Task) -> Void)? = nil

    @State private var isExpanded: Bool = true

    // Convenience initializer for top-level subtasks with action forwarding
    init(
        subtask: Task,
        nestingLevel: Int,
        onToggleCompletion: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onNestedToggleCompletion: ((Task) -> Void)? = nil,
        onNestedEdit: ((Task) -> Void)? = nil,
        onNestedDelete: ((Task) -> Void)? = nil
    ) {
        self.subtask = subtask
        self.nestingLevel = nestingLevel
        self.onToggleCompletion = onToggleCompletion
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onNestedToggleCompletion = onNestedToggleCompletion
        self.onNestedEdit = onNestedEdit
        self.onNestedDelete = onNestedDelete
    }

    private var indentationWidth: CGFloat {
        CGFloat(nestingLevel) * 20.0
    }

    private var hasSubtasks: Bool {
        subtask.hasSubtasks
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main subtask row
            HStack(spacing: 12) {
                // Indentation for nesting level
                if nestingLevel > 0 {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: indentationWidth)
                }

                // Nesting level indicator
                if nestingLevel > 0 {
                    nestingIndicator
                }

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
                    if !subtask.taskDescription.isEmpty || subtask.hasSubtasks {
                        HStack(spacing: 8) {
                            if !subtask.taskDescription.isEmpty {
                                Text(subtask.taskDescription)
                                    .font(.caption)
                                    .foregroundColor(.daisyTextSecondary)
                                    .lineLimit(1)
                            }

                            if subtask.hasSubtasks {
                                HStack(spacing: 4) {
                                    Image(systemName: "list.bullet")
                                        .font(.caption2)
                                    Text("\(subtask.completedSubtaskCount)/\(subtask.subtaskCount)")
                                        .font(.caption)
                                }
                                .foregroundColor(.daisyTextSecondary)
                            }

                            Spacer()
                        }
                    }
                }

                // Expand/Collapse button for subtasks
                if hasSubtasks {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel(isExpanded ? "Collapse subtasks" : "Expand subtasks")
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
            .background(Color.daisySurface.opacity(nestingLevel > 0 ? 0.5 : 1.0))
            .cornerRadius(nestingLevel > 0 ? 8 : 0)

            // Nested subtasks (recursive)
            if hasSubtasks && isExpanded {
                VStack(spacing: 0) {
                    ForEach(subtask.orderedSubtasks.sorted(by: { !$0.isCompleted && $1.isCompleted }), id: \.id) { nestedSubtask in
                        SubtaskRowView(
                            subtask: nestedSubtask,
                            nestingLevel: nestingLevel + 1,
                            onToggleCompletion: {
                                onNestedToggleCompletion?(nestedSubtask)
                            },
                            onEdit: {
                                onNestedEdit?(nestedSubtask)
                            },
                            onDelete: {
                                onNestedDelete?(nestedSubtask)
                            },
                            onNestedToggleCompletion: onNestedToggleCompletion,
                            onNestedEdit: onNestedEdit,
                            onNestedDelete: onNestedDelete
                        )
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Subtask: \(subtask.title)")
        .accessibilityAddTraits(subtask.isCompleted ? .isSelected : [])
    }

    @ViewBuilder
    private var nestingIndicator: some View {
        VStack {
            Rectangle()
                .fill(nestingColor)
                .frame(width: 2)
        }
        .frame(height: 20)
    }

    private var nestingColor: Color {
        let colors: [Color] = [.daisyTask, .daisyHabit, .daisyCTA, .daisySuccess, .daisyWarning]
        return colors[min(nestingLevel - 1, colors.count - 1)]
    }
}

// MARK: - Display Mode Variants

extension SubtaskRowView {
    /// Compact variant for limited space
    static func compact(
        subtask: Task,
        nestingLevel: Int = 0,
        onToggleCompletion: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 8) {
            // Indentation
            if nestingLevel > 0 {
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: CGFloat(nestingLevel) * 12.0)
            }

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

            // Subtask count if has subtasks
            if subtask.hasSubtasks {
                Text("\(subtask.completedSubtaskCount)/\(subtask.subtaskCount)")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
            }
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
        nestingLevel: 1,
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

#Preview("Nested Subtasks") {
    let container = try! ModelContainer(
        for: Task.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    // Create task hierarchy
    let parentTask = Task(title: "Build iOS App", priority: .high)
    let subtask1 = Task(title: "Setup Project", priority: .medium)
    let subtask2 = Task(title: "Design UI", priority: .medium)
    let nestedSubtask = Task(title: "Create wireframes", priority: .low)

    container.mainContext.insert(parentTask)
    container.mainContext.insert(subtask1)
    container.mainContext.insert(subtask2)
    container.mainContext.insert(nestedSubtask)

    _ = parentTask.addSubtask(subtask1)
    _ = parentTask.addSubtask(subtask2)
    _ = subtask2.addSubtask(nestedSubtask)

    subtask1.setCompleted(true)

    return VStack(spacing: 0) {
        ForEach(parentTask.subtasks, id: \.id) { subtask in
            SubtaskRowView(
                subtask: subtask,
                nestingLevel: 1,
                onToggleCompletion: {
                    subtask.toggleCompletion()
                },
                onEdit: {
                    print("Edit: \(subtask.title)")
                },
                onDelete: {
                    print("Delete: \(subtask.title)")
                }
            )
        }
    }
    .modelContainer(container)
    .background(Color.daisyBackground)
}