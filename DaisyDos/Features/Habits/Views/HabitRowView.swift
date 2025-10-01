//
//  HabitRowView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI
import SwiftData

// MARK: - HabitRowDisplayMode

enum HabitRowDisplayMode {
    case compact    // Minimal info for dense lists
    case detailed   // Full information display
    case today      // Today-specific optimizations
}

// MARK: - HabitRowView

struct HabitRowView: View {
    // MARK: - Properties

    let habit: Habit
    let onMarkComplete: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSkip: () -> Void
    let onTagAssignment: (() -> Void)?

    let displayMode: HabitRowDisplayMode
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
        displayMode: HabitRowDisplayMode = .detailed,
        showsStreak: Bool = true,
        showsTagButton: Bool = true
    ) {
        self.habit = habit
        self.onMarkComplete = onMarkComplete
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onSkip = onSkip
        self.onTagAssignment = onTagAssignment
        self.displayMode = displayMode
        self.showsStreak = showsStreak
        self.showsTagButton = showsTagButton
    }

    // MARK: - Body

    var body: some View {
        switch displayMode {
        case .compact:
            compactView
        case .detailed:
            detailedView
        case .today:
            todayView
        }
    }

    // MARK: - Display Mode Views

    @ViewBuilder
    private var compactView: some View {
        HStack(spacing: 12) {
            // Completion toggle
            completionToggle

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(habit.title)
                    .font(.body)
                    .strikethrough(habit.isCompletedToday)
                    .foregroundColor(
                        habit.isCompletedToday ? .daisyTextSecondary :
                        habit.isSkippedToday ? .orange.opacity(0.8) :
                        .daisyText
                    )
                    .lineLimit(1)

                if showsStreak {
                    streakIndicator
                        .font(.caption2)
                }
            }

            Spacer()

            // Indicators
            HStack(spacing: 4) {
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

    @ViewBuilder
    private var detailedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Habit header
            HStack {
                completionToggle

                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(.headline)
                        .strikethrough(habit.isCompletedToday)
                        .foregroundColor(
                            habit.isCompletedToday ? .daisyTextSecondary :
                            habit.isSkippedToday ? .orange.opacity(0.8) :
                            .daisyText
                        )

                    if !habit.habitDescription.isEmpty {
                        Text(habit.habitDescription)
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Indicators
                VStack(spacing: 4) {
                    // Recurrence indicator
                    if let recurrenceRule = habit.recurrenceRule {
                        Image(systemName: "repeat.circle.fill")
                            .foregroundColor(.daisyHabit)
                            .font(.caption)
                            .accessibilityLabel("Recurring habit: \(recurrenceRule.displayDescription)")
                    }

                }
            }

            // Tags section
            if !habit.tags.isEmpty {
                tagsSection
            }

            // Metadata footer
            metadataFooter
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    @ViewBuilder
    private var todayView: some View {
        HStack(spacing: 12) {
            // Completion toggle
            completionToggle

            // Content optimized for today view
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(habit.title)
                        .font(.body.weight(.medium))
                        .strikethrough(habit.isCompletedToday)
                        .foregroundColor(
                            habit.isCompletedToday ? .daisyTextSecondary :
                            habit.isSkippedToday ? .orange.opacity(0.8) :
                            .daisyText
                        )
                        .lineLimit(1)

                    Spacer()

                    // Today-specific indicators
                    HStack(spacing: 4) {
                        // Recurrence indicator
                        if habit.isDueOn(date: Date()) {
                            Image(systemName: "repeat.circle.fill")
                                .foregroundColor(.daisyHabit)
                                .font(.caption)
                                .accessibilityLabel("Due today")
                        }

                    }
                }

                // Streak display for today view
                if showsStreak {
                    HStack(spacing: 4) {
                        streakIndicator
                            .font(.caption)

                        // Next milestone teaser
                        if let nextMilestone = nextMilestoneText {
                            Text("• \(nextMilestone)")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                        }
                    }
                }

                // Tags for today view (more compact)
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
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
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

    @ViewBuilder
    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(habit.tags, id: \.id) { tag in
                    IconOnlyTagChipView(tag: tag)
                }
            }
            .padding(.horizontal, 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tags: " + habit.tags.map(\.name).joined(separator: ", "))
    }

    @ViewBuilder
    private var metadataFooter: some View {
        HStack {
            // Streak details
            if showsStreak {
                VStack(alignment: .leading, spacing: 2) {
                    streakIndicator

                    if habit.longestStreak > habit.currentStreak {
                        Text("Best: \(habit.longestStreak) days")
                            .font(.caption2)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
            }

            // Recurrence info
            if let recurrenceRule = habit.recurrenceRule {
                Label(
                    recurrenceRule.displayDescription,
                    systemImage: "repeat"
                )
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
                .accessibilityLabel("Recurrence: \(recurrenceRule.displayDescription)")
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                // Skip button
                Button(action: onSkip) {
                    Image(systemName: "forward.end")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Skip habit")
                .frame(minWidth: 44, minHeight: 44)

                if showsTagButton, let onTagAssignment = onTagAssignment {
                    Button(action: onTagAssignment) {
                        Image(systemName: "tag")
                            .font(.caption)
                            .foregroundColor(.daisyTag)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Assign tags")
                    .frame(minWidth: 44, minHeight: 44)
                }

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.daisyHabit)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit habit")
                .frame(minWidth: 44, minHeight: 44)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.daisyError)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Delete habit")
                .frame(minWidth: 44, minHeight: 44)
            }
        }
    }

    // MARK: - Helper Properties

    private var nextMilestoneText: String? {
        let milestones = [7, 14, 21, 30, 50, 75, 100]
        for milestone in milestones {
            if habit.currentStreak < milestone {
                let remaining = milestone - habit.currentStreak
                return "Next: \(remaining) to \(milestone)"
            }
        }
        return nil
    }

    // MARK: - Accessibility Helpers

    private var accessibilityLabel: String {
        var label = habit.title
        if habit.isCompletedToday {
            label += ", completed today"
        } else if habit.isSkippedToday {
            label += ", skipped today"
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

#Preview("Detailed Mode") {
    HabitRowViewPreview(displayMode: .detailed)
}

#Preview("Compact Mode") {
    HabitRowViewPreview(displayMode: .compact)
}

#Preview("Today Mode") {
    HabitRowViewPreview(displayMode: .today)
}

#Preview("Accessibility") {
    HabitRowViewPreview(displayMode: .detailed)
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
}

struct HabitRowViewPreview: View {
    let displayMode: HabitRowDisplayMode

    init(displayMode: HabitRowDisplayMode = .detailed) {
        self.displayMode = displayMode
    }

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
                onEdit: {
                    print("Edit tapped")
                },
                onDelete: {
                    print("Delete tapped")
                },
                onSkip: {
                    print("Skip tapped")
                },
                onTagAssignment: {
                    print("Tag assignment tapped")
                },
                displayMode: displayMode
            )

            // Show completed version
            HabitRowView(
                habit: completedHabit,
                onMarkComplete: {
                    completedHabit.resetStreak()
                },
                onEdit: {},
                onDelete: {},
                onSkip: {},
                displayMode: displayMode
            )

        }
        .modelContainer(container)
        .padding()
    }
}