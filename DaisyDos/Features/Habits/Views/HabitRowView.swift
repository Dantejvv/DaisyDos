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

    let habit: Habit
    let onMarkComplete: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSkip: () -> Void
    let onTagAssignment: (() -> Void)?

    let showsStreak: Bool
    let showsTagButton: Bool

    // MARK: - Initializers

    init(
        habit: Habit,
        onMarkComplete: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onTagAssignment: (() -> Void)? = nil,
        showsStreak: Bool = true,
        showsTagButton: Bool = true
    ) {
        self.habit = habit
        self.onMarkComplete = onMarkComplete
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onSkip = onSkip
        self.onTagAssignment = onTagAssignment
        self.showsStreak = showsStreak
        self.showsTagButton = showsTagButton
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            // Completion toggle
            completionToggle

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.title)
                    .font(.body)
                    .strikethrough(habit.isCompletedToday)
                    .foregroundColor(
                        habit.isCompletedToday ? .daisyTextSecondary :
                        habit.isSkippedToday ? .orange.opacity(0.8) :
                        .daisyText
                    )
                    .lineLimit(1)

                HStack(spacing: 4) {
                    // Tags (icon-only)
                    if !habit.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(habit.tags.prefix(3), id: \.id) { tag in
                                IconOnlyTagChipView(tag: tag)
                            }
                            if habit.tags.count > 3 {
                                Text("+\(habit.tags.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.daisyTextSecondary)
                            }
                        }
                    }

                    // Streak indicator
                    if showsStreak {
                        if !habit.tags.isEmpty {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.daisyTextSecondary)
                        }
                        streakIndicator
                            .font(.caption2)
                    }
                }
            }

            Spacer()

            // Indicators
            HStack(spacing: 4) {
                // Priority indicator (only when not medium)
                habit.priority.indicatorView()
                    .font(.caption2)

                // Due indicator based on recurrence
                if let _ = habit.recurrenceRule,
                   habit.isDueOn(date: Date()) {
                    Image(systemName: "repeat.circle.fill")
                        .foregroundColor(.daisyHabit)
                        .font(.caption2)
                        .accessibilityLabel("Due today")
                }

            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(habit.isCompletedToday ? [.updatesFrequently] : [])
    }

    // MARK: - Reusable Components

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

    @ViewBuilder
    private var streakIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundColor(habit.currentStreak > 0 ? Color(.systemOrange) : .secondary)
            Text("\(habit.currentStreak) day streak")
                .foregroundColor(.daisyTextSecondary)
        }
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
        if showsStreak {
            label += ", \(habit.currentStreak) day streak"
        }
        if let recurrenceRule = habit.recurrenceRule {
            label += ", recurring \(recurrenceRule.displayDescription.lowercased())"
        }
        if !habit.tags.isEmpty {
            label += ", \(habit.tags.count) tag\(habit.tags.count == 1 ? "" : "s")"
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
