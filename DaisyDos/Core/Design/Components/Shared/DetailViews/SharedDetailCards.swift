//
//  SharedDetailCards.swift
//  DaisyDos
//
//  Created by Claude Code on 11/11/25.
//  Shared card components for detail views
//
//  PURPOSE: Reduce code duplication between TaskDetailView and HabitDetailView
//  by extracting common card layouts into reusable components
//
//  Used by: TaskDetailView, HabitDetailView
//

import SwiftUI

// MARK: - History Card

/// Displays creation, modification, and completion timestamps
///
/// **Usage**:
/// ```swift
/// // For tasks (single completion)
/// HistoryCard(
///     createdDate: task.createdDate,
///     modifiedDate: task.modifiedDate,
///     completionInfo: task.isCompleted && task.completedDate != nil
///         ? .single(task.completedDate!)
///         : nil
/// )
///
/// // For habits (multiple completions)
/// HistoryCard(
///     createdDate: habit.createdDate,
///     modifiedDate: habit.modifiedDate,
///     completionInfo: !sortedCompletions.isEmpty
///         ? .multiple(count: sortedCompletions.count, lastDate: sortedCompletions.first!.completedDate)
///         : nil
/// )
/// ```
struct HistoryCard: View {
    let createdDate: Date
    let modifiedDate: Date
    let completionInfo: CompletionInfo?

    /// Completion information display mode
    enum CompletionInfo {
        case single(Date)  // Task: single completion date
        case multiple(count: Int, lastDate: Date)  // Habit: total count + last completion
    }

    var body: some View {
        DetailCard(title: "History") {
            VStack(spacing: 12) {
                // Created date
                HStack {
                    Label("Created", systemImage: "calendar.badge.plus")
                        .font(.subheadline)
                        .foregroundColor(.daisyTextSecondary)
                    Spacer()
                    Text(createdDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.daisyText)
                }

                // Modified date (only if significantly different from created)
                if modifiedDate.timeIntervalSince(createdDate) > 60 {
                    Divider()

                    HStack {
                        Label("Modified", systemImage: "pencil.circle")
                            .font(.subheadline)
                            .foregroundColor(.daisyTextSecondary)
                        Spacer()
                        Text(modifiedDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.daisyText)
                    }
                }

                // Completion info
                if let completionInfo = completionInfo {
                    Divider()
                    completionInfoView(completionInfo)
                }
            }
        }
    }

    @ViewBuilder
    private func completionInfoView(_ info: CompletionInfo) -> some View {
        switch info {
        case .single(let date):
            HStack {
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.daisySuccess)
                Spacer()
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)
            }

        case .multiple(let count, let lastDate):
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Total Completions", systemImage: "checkmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.daisySuccess)
                    Spacer()
                    Text("\(count)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.daisyText)
                }

                HStack {
                    Text("Last completed")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                    Spacer()
                    Text(lastDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Task History - Completed") {
    HistoryCard(
        createdDate: Calendar.current.date(byAdding: .day, value: -7, to: Date())!,
        modifiedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
        completionInfo: .single(Date())
    )
    .padding()
    .background(Color.daisyBackground)
}

#Preview("Task History - Not Completed") {
    HistoryCard(
        createdDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
        modifiedDate: Date(),
        completionInfo: nil
    )
    .padding()
    .background(Color.daisyBackground)
}

#Preview("Habit History - Multiple Completions") {
    HistoryCard(
        createdDate: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
        modifiedDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
        completionInfo: .multiple(count: 45, lastDate: Date())
    )
    .padding()
    .background(Color.daisyBackground)
}

// MARK: - Tags Card

/// Displays and manages tags with add/remove functionality
///
/// **Usage**:
/// ```swift
/// TagsCard(
///     tags: task.tags,
///     accentColor: .daisyTask,
///     canModify: true,
///     maxTags: 5,
///     onAddTags: { showingTagAssignment = true },
///     onRemoveTag: { tag in removeTag(tag) }
/// )
/// ```
struct TagsCard: View {
    let tags: [Tag]
    let accentColor: Color
    let canModify: Bool
    let maxTags: Int
    let onAddTags: () -> Void
    let onRemoveTag: (Tag) -> Void

    var body: some View {
        DetailCard(title: "Tags") {
            if tags.isEmpty {
                // Empty state
                if canModify {
                    Button(action: onAddTags) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle")
                            Text("Add Tags")
                            Spacer()
                        }
                        .font(.body)
                        .foregroundColor(accentColor)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                } else {
                    // Read-only empty state
                    HStack {
                        Text("None")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.daisyTextSecondary)
                    }
                    .padding(.vertical, 12)
                }
            } else {
                // Tags display
                WrappingHStack(spacing: 8) {
                    ForEach(tags, id: \.id) { tag in
                        TagChipView(
                            tag: tag,
                            isSelected: true,
                            isRemovable: canModify,
                            onRemove: canModify ? {
                                onRemoveTag(tag)
                            } : nil
                        )
                    }

                    if canModify && tags.count < maxTags {
                        Button(action: onAddTags) {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .foregroundColor(accentColor)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Add more tags")
                    }
                }
            }
        }
    }
}

// MARK: - Tags Card Preview

#Preview("Tags - Empty State") {
    TagsCard(
        tags: [],
        accentColor: .daisyTask,
        canModify: true,
        maxTags: 5,
        onAddTags: {},
        onRemoveTag: { _ in }
    )
    .padding()
    .background(Color.daisyBackground)
}

#Preview("Tags - With Tags") {
    // Preview requires Tag model - simplified preview
    DetailCard(title: "Tags") {
        Text("Tags would be displayed here")
            .foregroundColor(.daisyTextSecondary)
    }
    .padding()
    .background(Color.daisyBackground)
}

#Preview("Tags - Read Only") {
    TagsCard(
        tags: [],
        accentColor: .daisyHabit,
        canModify: false,
        maxTags: 5,
        onAddTags: {},
        onRemoveTag: { _ in }
    )
    .padding()
    .background(Color.daisyBackground)
}
