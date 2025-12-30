//
//  HabitRowView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//  Refactored on 1/2/25 - Removed unused display modes, extracted shared components
//

import SwiftUI
import SwiftData

// MARK: - HabitRowView

struct HabitRowView: View {
    // MARK: - Properties

    @Environment(AppearanceManager.self) private var appearanceManager
    @Environment(\.colorScheme) private var colorScheme

    let habit: Habit
    let onMarkComplete: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSkip: () -> Void
    let onTagAssignment: (() -> Void)?
    let isReorderMode: Bool
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    let canMoveUp: Bool
    let canMoveDown: Bool

    // MARK: - Initializers

    init(
        habit: Habit,
        onMarkComplete: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onTagAssignment: (() -> Void)? = nil,
        isReorderMode: Bool = false,
        onMoveUp: (() -> Void)? = nil,
        onMoveDown: (() -> Void)? = nil,
        canMoveUp: Bool = false,
        canMoveDown: Bool = false
    ) {
        self.habit = habit
        self.onMarkComplete = onMarkComplete
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onSkip = onSkip
        self.onTagAssignment = onTagAssignment
        self.isReorderMode = isReorderMode
        self.onMoveUp = onMoveUp
        self.onMoveDown = onMoveDown
        self.canMoveUp = canMoveUp
        self.canMoveDown = canMoveDown
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Show reorder controls or completion toggle
            if isReorderMode {
                reorderControls
            } else {
                completionToggle
            }

            // Content - 3 Row Layout
            VStack(alignment: .leading, spacing: 4) {
                // ROW 1: Title
                Text(habit.title)
                    .font(.body)
                    .strikethrough(habit.isCompletedToday)
                    .foregroundColor(
                        habit.isCompletedToday ? .daisyTextSecondary :
                        habit.isSkippedToday ? .orange.opacity(0.8) :
                        .daisyText
                    )
                    .lineLimit(1)

                if !habit.isCompletedToday && !habit.isSkippedToday {
                    // ACTIVE HABITS: Inline Layout

                    // ROW 2: Metadata • Tags (LEFT/MIDDLE) | Streak (RIGHT) - always show
                    HStack(spacing: 4) {
                        // Left side: Subtasks
                        if let progressText = habit.subtaskProgressText {
                            SubtaskProgressIndicator(progressText: progressText)
                        }

                        // Combined Alert/Recurrence indicator
                        if habit.hasAlert || habit.hasRecurrence {
                            alertRecurrenceIndicator
                        }

                        // Middle: Tags (inline with metadata, limit to 3 max)
                        if !(habit.tags ?? []).isEmpty {
                            let visibleTags = Array((habit.tags ?? []).prefix(3))
                            let remainingCount = (habit.tags ?? []).count - visibleTags.count

                            ForEach(visibleTags, id: \.id) { tag in
                                IconOnlyTagChipView(tag: tag)
                            }

                            if remainingCount > 0 {
                                Text("+\(remainingCount)")
                                    .font(.caption2.weight(.medium))
                                    .foregroundColor(.daisyTextSecondary)
                            }
                        }

                        Spacer()

                        // Right side: Streak indicator (always show, even if 0)
                        streakIndicator
                    }
                } else {
                    // COMPLETED OR SKIPPED HABITS: Minimal Layout

                    // ROW 2: Subtasks (LEFT) | Status Text (RIGHT)
                    HStack(spacing: 4) {
                        // Left side: Subtasks only
                        if let progressText = habit.subtaskProgressText {
                            SubtaskProgressIndicator(progressText: progressText)
                        }

                        Spacer()

                        // Right side: Status text
                        if habit.isCompletedToday {
                            Text("Completed today")
                                .font(.caption2)
                                .foregroundColor(.daisySuccess.opacity(0.8))
                        } else if habit.isSkippedToday {
                            Text("Skipped today")
                                .font(.caption2)
                                .foregroundColor(.orange.opacity(0.8))
                        }
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // Priority/status background tint
                habitBackgroundColor
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(habit.isCompletedToday ? [.updatesFrequently] : [])
    }

    // MARK: - Reusable Components

    // MARK: Metadata Components

    @ViewBuilder
    private var alertRecurrenceIndicator: some View {
        if habit.hasAlert && habit.hasRecurrence {
            Image(systemName: "bell.badge.fill")
                .font(.body)
                .foregroundColor(.daisyWarning)
                .accessibilityLabel("Has reminder and recurring")
        } else if habit.hasAlert {
            Image(systemName: "bell.fill")
                .font(.body)
                .foregroundColor(.daisyWarning)
                .accessibilityLabel("Has reminder")
        } else if habit.hasRecurrence {
            Image(systemName: "repeat.circle.fill")
                .font(.body)
                .foregroundColor(.daisyHabit)
                .accessibilityLabel(habit.recurrenceRule?.displayDescription ?? "Recurring habit")
        }
    }

    // MARK: Background Color

    private var habitBackgroundColor: Color {
        // Use higher opacity in dark mode for better visibility
        let baseOpacity = colorScheme == .dark ? 0.15 : 0.08

        // Completed today: green background
        if habit.isCompletedToday {
            return Color.green.opacity(baseOpacity)
        }

        // Skipped today: orange background
        if habit.isSkippedToday {
            return Color.orange.opacity(baseOpacity)
        }

        // If priority backgrounds are disabled, use default gray
        guard appearanceManager.showPriorityBackgrounds else {
            return Color.daisyTextSecondary.opacity(baseOpacity)
        }

        // Active habits: priority-based colors
        switch habit.priority {
        case .none:
            return Color.daisyTextSecondary.opacity(baseOpacity)
        case .low:
            return appearanceManager.lowPriorityDisplayColor.opacity(baseOpacity)
        case .medium:
            return appearanceManager.mediumPriorityDisplayColor.opacity(baseOpacity)
        case .high:
            return appearanceManager.highPriorityDisplayColor.opacity(baseOpacity)
        }
    }

    // MARK: Completion Toggle

    private var completionToggle: some View {
        let systemName: String
        let color: Color

        if habit.isCompletedToday {
            systemName = "checkmark.circle.fill"
            color = .daisySuccess
        } else if habit.isSkippedToday {
            systemName = "forward.circle.fill"
            color = .orange
        } else {
            systemName = "circle"
            color = Colors.Primary.textTertiary
        }

        return Button(action: onMarkComplete) {
            Image(systemName: systemName)
                .font(.title2)
                .foregroundColor(color)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            habit.isCompletedToday ? "Mark as incomplete" :
            habit.isSkippedToday ? "Habit skipped today" :
            "Mark as complete"
        )
        .accessibilityAddTraits(.isButton)
        .frame(minWidth: 44, minHeight: 44) // Ensure 44pt touch target
        .disabled(habit.isSkippedToday) // Disable interaction if skipped
    }

    // MARK: Reorder Controls

    private var reorderControls: some View {
        VStack(spacing: 4) {
            Button(action: {
                onMoveUp?()
            }) {
                Image(systemName: "chevron.up.circle.fill")
                    .font(.title3)
                    .foregroundColor(canMoveUp ? .daisyHabit : .daisyTextSecondary.opacity(0.3))
            }
            .buttonStyle(.plain)
            .disabled(!canMoveUp)
            .frame(minWidth: 44, minHeight: 22)

            Button(action: {
                onMoveDown?()
            }) {
                Image(systemName: "chevron.down.circle.fill")
                    .font(.title3)
                    .foregroundColor(canMoveDown ? .daisyHabit : .daisyTextSecondary.opacity(0.3))
            }
            .buttonStyle(.plain)
            .disabled(!canMoveDown)
            .frame(minWidth: 44, minHeight: 22)
        }
        .frame(minWidth: 44, minHeight: 44) // Ensure consistent width with completion toggle
    }

    @ViewBuilder
    private var streakIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundColor(habit.currentStreak > 0 ? Color(.systemOrange) : .secondary)
                .font(.caption.weight(.medium))
            Text("\(habit.currentStreak) day streak")
                .foregroundColor(.daisyTextSecondary)
                .font(.caption2)
        }
        .lineLimit(1)
        .fixedSize()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Current streak: \(habit.currentStreak) days")
    }

    // MARK: - Accessibility Helpers

    private var accessibilityLabel: String {
        var label = habit.title
        if habit.isCompletedToday {
            label += ", completed today"
        } else if habit.isSkippedToday {
            label += ", skipped today"
        }
        if habit.priority != .medium {
            label += ", \(habit.priority.displayName.lowercased())"
        }
        // Always include streak (even if 0)
        label += ", \(habit.currentStreak) day streak"
        if let recurrenceRule = habit.recurrenceRule {
            label += ", recurring \(recurrenceRule.displayDescription.lowercased())"
        }
        if !(habit.tags ?? []).isEmpty {
            label += ", \((habit.tags ?? []).count) tag\((habit.tags ?? []).count == 1 ? "" : "s")"
        }
        return label
    }

    private var accessibilityHint: String {
        if habit.isCompletedToday {
            return "Double tap to mark as incomplete"
        } else if habit.isSkippedToday {
            return "Habit skipped for today"
        } else {
            return "Double tap to mark as complete"
        }
    }
}

// MARK: - Preview Providers

#Preview("Habit Row View") {
    HabitRowViewPreview()
}

#Preview("Accessibility") {
    HabitRowViewPreview()
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}

struct HabitRowViewPreview: View {
    var body: some View {
        let container = try! ModelContainer(
            for: Habit.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let tagManager = TagManager(modelContext: context)

        // Create sample data
        let workoutTag = tagManager.createTag(name: "Workout", sfSymbolName: "figure.run", colorName: "red")!
        let healthTag = tagManager.createTag(name: "Health", sfSymbolName: "heart", colorName: "green")!
        let mindfulTag = tagManager.createTag(name: "Mindful", sfSymbolName: "brain", colorName: "purple")!

        let habit = Habit(
            title: "Morning Exercise",
            habitDescription: "30 minutes of cardio or strength training to start the day",
            recurrenceRule: .daily()
        )
        habit.currentStreak = 14
        habit.longestStreak = 21
        context.insert(habit)
        _ = habit.addTag(workoutTag)
        _ = habit.addTag(healthTag)

        // Create completed habit
        let completedHabit = Habit(
            title: "Read for 20 minutes",
            habitDescription: "Read books, articles, or educational content",
            recurrenceRule: .daily()
        )
        completedHabit.currentStreak = 7
        completedHabit.longestStreak = 15
        completedHabit.lastCompletedDate = Date()
        _ = completedHabit.addTag(mindfulTag)
        context.insert(completedHabit)


        try! context.save()

        return VStack(spacing: 16) {
            HabitRowView(
                habit: habit,
                onMarkComplete: {
                    habit.markCompleted()
                },
                onEdit: {},
                onDelete: {},
                onSkip: {},
                onTagAssignment: {}
            )

            // Show completed version
            HabitRowView(
                habit: completedHabit,
                onMarkComplete: {
                    completedHabit.resetStreak()
                },
                onEdit: {},
                onDelete: {},
                onSkip: {}
            )

        }
        .modelContainer(container)
        .padding()
    }
}
