//
//  HabitDetailView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//  Refactored with vertical card layout on 11/10/25
//  Refactored with shared components on 11/11/25
//
//  FEATURE DIFFERENCES FROM TASKDETAILVIEW:
//  ════════════════════════════════════════════════════════════════════════════
//  1. DUE DATES: Habits don't have due dates; they use recurrence rules for scheduling
//     Rationale: Habits are about building consistent behaviors, not meeting deadlines
//
//  2. SKIP FUNCTIONALITY: Habits can be skipped with reasons; tasks are binary (done/not done)
//     Rationale: Life happens - users need flexibility without breaking streaks
//
//  3. COMPLETION TRACKING: Multiple completion entries with mood/duration; tasks have single state
//     Rationale: Track behavioral patterns and progress over time (see "Recent Activity" card)
//
//  4. STREAK DISPLAY: Shows current streak prominently; tasks don't track streaks
//     Rationale: Streaks motivate consistency in habit formation
//
//  5. COMPLETION TOAST: 5-second undo with HabitCompletionToastManager; tasks don't use toasts
//     Rationale: Quick undo prevents accidental completions in daily habit tracking
//
//  6. NO LOGBOOK: Habits maintain continuous history; no archival needed
//     Rationale: Habit tracking is ongoing; completion history never expires
//
//  SHARED BEHAVIORS:
//  ════════════════════════════════════════════════════════════════════════════
//  - Subtasks, tags, attachments, recurrence, alerts, priority
//  - Card-based layout using shared components (HistoryCard, TagsCard, DetailCard)
//  - Consistent tag/subtask management via manager methods
//  - Shared formatting utilities (DetailViewHelpers)
//

import SwiftUI
import SwiftData
import QuickLook

struct HabitDetailView: View {
    // MARK: - Properties

    @Environment(HabitManager.self) private var habitManager
    @Environment(AnalyticsManager.self) private var analyticsManager: AnalyticsManager?
    @Environment(\.dismiss) private var dismiss
    @Environment(HabitCompletionToastManager.self) private var toastManager

    let habit: Habit

    // Query subtasks directly from database to work around SwiftData relationship observation issues
    @Query private var allSubtasks: [HabitSubtask]

    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var showingSkipView = false
    @State private var showingTagAssignment = false
    @State private var showingRecurrencePicker = false
    @State private var showingAlertPicker = false
    @State private var showingPriorityPicker = false
    @State private var newSubtaskTitle = ""
    @State private var showSubtaskField = false
    @FocusState private var newSubtaskFocused: Bool
    @State private var attachmentToPreview: URL?
    @State private var selectedPeriod: AnalyticsPeriod = .sevenDays

    // MARK: - Computed Properties

    // Get subtasks for this specific habit from the query results
    private var habitSubtasks: [HabitSubtask] {
        allSubtasks.filter { $0.parentHabit?.id == habit.id }
            .sorted { $0.subtaskOrder < $1.subtaskOrder }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero Card - Habit Overview (title, description, priority)
                    habitOverviewCard

                    // Subtasks Section - Always shown
                    subtasksCard

                    // Metadata Card (recurrence) - Always shown
                    metadataCard

                    // Tags Section - Always shown
                    tagsCard

                    // Attachments Section - Always shown
                    attachmentsCard

                    // Status & Progress Card
                    statusAndProgressCard

                    // History Card (created, modified, completion history)
                    historyCard

                    // Analytics Card (habit-specific analytics)
                    analyticsCard
                }
                .padding()
            }
            .background(Color.daisyBackground)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Completion toggle at the top
                        Button {
                            if habit.isCompletedToday {
                                _ = habitManager.undoHabitCompletion(habit)
                            } else {
                                if let _ = habitManager.markHabitCompletedWithTracking(habit) {
                                    toastManager.showCompletionToast(for: habit) {
                                        _ = habitManager.undoHabitCompletion(habit)
                                    }
                                }
                            }
                        } label: {
                            if habit.isCompletedToday {
                                Label("Mark as Incomplete", systemImage: "circle")
                            } else {
                                Label("Mark as Complete", systemImage: "checkmark.circle.fill")
                            }
                        }

                        Divider()

                        Button {
                            showingEditView = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Divider()

                        Button {
                            showingSkipView = true
                        } label: {
                            Label("Skip Today", systemImage: "forward.end")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            HabitEditView(habit: habit)
        }
        .sheet(isPresented: $showingSkipView) {
            SimpleHabitSkipView(
                habit: habit,
                onSkip: { reason in
                    _ = habitManager.skipHabit(habit, reason: reason)
                }
            )
        }
        .sheet(isPresented: $showingTagAssignment) {
            TagSelectionView(selectedTags: .init(
                get: { habit.tags ?? [] },
                set: { newTags in
                    updateHabitTags(newTags)
                }
            ))
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingRecurrencePicker) {
            RecurrenceRulePickerView(recurrenceRule: .init(
                get: { habit.recurrenceRule },
                set: { newRule in
                    habit.recurrenceRule = newRule
                    habit.modifiedDate = Date()
                }
            ))
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingAlertPicker) {
            AlertPickerSheet(
                selectedAlert: .init(
                    get: {
                        if let interval = habit.alertTimeInterval {
                            return AlertOption.allCases.first { $0.timeInterval == interval }
                        }
                        return nil
                    },
                    set: { newAlert in
                        habit.alertTimeInterval = newAlert?.timeInterval
                        habit.modifiedDate = Date()
                    }
                ),
                accentColor: .daisyHabit
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingPriorityPicker) {
            PriorityPickerSheet(
                selectedPriority: .init(
                    get: { habit.priority },
                    set: { newPriority in
                        habit.priority = newPriority
                        habit.modifiedDate = Date()
                    }
                ),
                accentColor: .daisyHabit
            )
            .presentationDetents([.medium])
        }
        .alert("Delete Habit", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteHabit()
            }
        } message: {
            Text("Are you sure you want to delete '\(habit.title)'? This action cannot be undone.")
        }
        .quickLookPreview($attachmentToPreview)
        .errorAlert(error: Binding(
            get: { habitManager.lastError },
            set: { habitManager.lastError = $0 }
        ))
    }

    // MARK: - Hero Card - Habit Overview

    @ViewBuilder
    private var habitOverviewCard: some View {
        OverviewCard(
            title: habit.title,
            description: habit.habitDescriptionAttributed
        )
    }

    // MARK: - Status & Progress Card

    @ViewBuilder
    private var statusAndProgressCard: some View {
        StatusProgressCard(
            hasSubtasks: habit.hasSubtasks,
            completedSubtaskCount: habit.completedSubtaskCount,
            totalSubtaskCount: habit.subtaskCount,
            accentColor: .daisyHabit
        ) {
            HStack(spacing: 20) {
                // Today's completion
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                    HStack(spacing: 6) {
                        Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(habit.isCompletedToday ? .daisySuccess : .daisyTextSecondary)
                        Text(habit.isCompletedToday ? "Complete" : "Incomplete")
                            .font(.subheadline.weight(.medium))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 40)

                // Current Streak
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Streak")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(habit.currentStreak)")
                            .font(.subheadline.weight(.medium))
                        Text("days")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 40)

                // Subtask progress
                SubtaskStatusSection(
                    hasSubtasks: habit.hasSubtasks,
                    completedCount: habit.completedSubtaskCount,
                    totalCount: habit.subtaskCount,
                    accentColor: .daisyHabit
                )
            }
        }
    }

    // MARK: - Tags Card

    @ViewBuilder
    private var tagsCard: some View {
        TagsCard(
            tags: habit.tags ?? [],
            accentColor: .daisyHabit,
            canModify: true,
            maxTags: 5,
            onAddTags: {
                showingTagAssignment = true
            },
            onRemoveTag: { tag in
                removeTag(tag)
            }
        )
    }

    // MARK: - Metadata Card

    @ViewBuilder
    private var metadataCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
                .foregroundColor(.daisyText)

            VStack(spacing: 12) {
                // Recurrence - Always shown
                Button(action: {
                    showingRecurrencePicker = true
                }) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Recurrence", systemImage: "repeat")
                                .font(.subheadline)
                                .foregroundColor(.daisyTextSecondary)
                            Spacer()
                            HStack(spacing: 4) {
                                if habit.recurrenceRule == nil {
                                    Text("None")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.daisyTextSecondary)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.daisyTextSecondary)
                            }
                        }

                        // Pattern description (only shown if recurrence exists)
                        if let recurrenceRule = habit.recurrenceRule {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recurrenceRule.displayDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.daisyTextSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.daisyBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                            }

                            // Next occurrence info
                            if let nextDate = recurrenceRule.nextOccurrence(after: Date()) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Next")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.daisyTextSecondary)

                                    HStack {
                                        Text(nextDate, style: .date)
                                            .font(.subheadline)
                                            .foregroundColor(.daisyText)

                                        Spacer()

                                        Text(formatRelativeDate(nextDate))
                                            .font(.caption)
                                            .foregroundColor(.daisyHabit)
                                    }
                                }
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                Divider()

                // Alert - Always shown
                Button(action: {
                    showingAlertPicker = true
                }) {
                    HStack {
                        Label("Alert", systemImage: "bell.fill")
                            .font(.subheadline)
                            .foregroundColor(.daisyTextSecondary)
                        Spacer()
                        HStack(spacing: 4) {
                            if let alertInterval = habit.alertTimeInterval {
                                Text(formatAlertInterval(alertInterval))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.daisyText)
                            } else {
                                Text("None")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.daisyTextSecondary)
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Divider()

                // Priority - Always shown
                Button(action: {
                    showingPriorityPicker = true
                }) {
                    HStack {
                        Label("Priority", systemImage: "flag.fill")
                            .font(.subheadline)
                            .foregroundColor(.daisyTextSecondary)
                        Spacer()
                        HStack(spacing: 4) {
                            if habit.priority != .none {
                                habit.priority.indicatorView()
                                    .font(.caption)
                                Text(habit.priority.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.daisyText)
                            } else {
                                Text("None")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.daisyTextSecondary)
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Subtasks Section

    @ViewBuilder
    private var subtasksCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Subtasks")
                .font(.headline)
                .foregroundColor(.daisyText)

            if habitSubtasks.isEmpty && !showSubtaskField {
                // Empty state - button to show field
                SubtaskAddButton {
                    showSubtaskField = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        newSubtaskFocused = true
                    }
                }
            }

            // Subtasks list or field showing
            if !habitSubtasks.isEmpty || showSubtaskField {
                VStack(spacing: 0) {
                    // Existing subtasks list
                    if !habitSubtasks.isEmpty {
                        ScrollViewReader { proxy in
                            List {
                                ForEach(habitSubtasks) { subtask in
                                    SubtaskRow(
                                        subtask: subtask,
                                        accentColor: .daisyHabit,
                                        onToggle: {
                                            toggleSubtask(subtask)
                                        }
                                    )
                                    .id(subtask.id)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                }
                            }
                            .listStyle(.plain)
                            .frame(height: CGFloat(min(habitSubtasks.count, 6)) * 50)
                            .scrollDisabled(habitSubtasks.count <= 6)
                            .onChange(of: habitSubtasks.count) { oldValue, newValue in
                                if newValue > 6, let lastSubtask = habitSubtasks.last {
                                    withAnimation {
                                        proxy.scrollTo(lastSubtask.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }

                    // Add new subtask field
                    if showSubtaskField {
                        SubtaskInputField(
                            text: $newSubtaskTitle,
                            isFocused: $newSubtaskFocused,
                            onAdd: {
                                addSubtaskAndClose()
                            }
                        )
                    }

                    // Always-visible + button
                    SubtaskAddButton {
                        // If field is showing and has text, add the subtask first
                        if showSubtaskField && !newSubtaskTitle.isEmpty {
                            addSubtask()
                        }

                        // Show field if hidden
                        if !showSubtaskField {
                            showSubtaskField = true
                        }

                        // Always focus the field
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            newSubtaskFocused = true
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Attachments Card

    @ViewBuilder
    private var attachmentsCard: some View {
        AttachmentPreviewSection(
            attachments: habit.attachments ?? [],
            accentColor: .daisyHabit,
            onTap: { attachment in
                // Create temporary URL from attachment data for QuickLook preview
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(attachment.id.uuidString)
                    .appendingPathExtension(attachment.fileExtension)

                do {
                    try attachment.fileData.write(to: tempURL)
                    attachmentToPreview = tempURL
                } catch {
                    // Silently fail - could add error handling if needed
                    print("Failed to create temporary file for preview: \(error)")
                }
            }
        )
    }

    // MARK: - History Card

    @ViewBuilder
    private var historyCard: some View {
        let sortedCompletions = (habit.completionEntries ?? [])
            .sorted { $0.completedDate > $1.completedDate }

        VStack(spacing: 20) {
            // Main history card (created, modified, completion stats)
            HistoryCard(
                createdDate: habit.createdDate,
                modifiedDate: habit.modifiedDate,
                completionInfo: !sortedCompletions.isEmpty
                    ? .multiple(count: sortedCompletions.count, lastDate: sortedCompletions.first!.completedDate)
                    : nil
            )

            // Additional habit-specific completion details (last 5 entries)
            if sortedCompletions.count > 1 {
                DetailCard(title: "Recent Activity") {
                    VStack(spacing: 4) {
                        ForEach(sortedCompletions.prefix(5), id: \.id) { completion in
                            CompletionRowView(completion: completion, showDetails: false)
                        }

                        if sortedCompletions.count > 5 {
                            Text("+ \(sortedCompletions.count - 5) more")
                                .font(.caption2)
                                .foregroundColor(.daisyTextSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 4)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Analytics Card

    @ViewBuilder
    private var analyticsCard: some View {
        if let analyticsManager = analyticsManager {
            let analytics = analyticsManager.getHabitAnalytics(for: selectedPeriod)

            VStack(spacing: Spacing.medium) {
            // Header with period selector
            VStack(spacing: Spacing.small) {
                HStack {
                    Text("Analytics")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.daisyText)

                    Spacer()
                }

                PeriodSelector(selectedPeriod: $selectedPeriod)
            }

            // Summary stats
            HStack(spacing: Spacing.small) {
                StatCard(
                    title: "Current Streak",
                    value: "\(habit.currentStreak)",
                    subtitle: "Best: \(habit.longestStreak)",
                    icon: "flame.fill",
                    accentColor: .orange
                )

                StatCard(
                    title: "Completion Rate",
                    value: String(format: "%.0f%%", habit.completionRate(over: selectedPeriod.days) * 100),
                    subtitle: "Last \(selectedPeriod.days) days",
                    icon: "chart.bar.fill",
                    accentColor: .green
                )
            }

            // Charts
            if analytics.hasData {
                VStack(spacing: Spacing.medium) {
                    WeeklyCompletionChart(
                        data: analytics.weeklyCompletions,
                        period: selectedPeriod
                    )

                    if !analytics.moodTrends.isEmpty {
                        MoodTrendsChart(
                            data: analytics.moodTrends,
                            period: selectedPeriod,
                            averageMood: analytics.averageMood
                        )
                    }
                }
            } else {
                // Empty state
                VStack(spacing: Spacing.medium) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 48))
                        .foregroundColor(.daisyTextSecondary.opacity(0.5))

                    Text("No analytics data yet")
                        .font(.headline)
                        .foregroundColor(.daisyTextSecondary)

                    Text("Complete this habit to start seeing analytics")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.extraLarge)
            }
            }
        }
    }

    // MARK: - Initializer

    init(habit: Habit) {
        self.habit = habit
    }

    // MARK: - Helper Methods
    // Note: Formatting methods now use DetailViewHelpers for consistency

    private func formatRelativeDate(_ date: Date) -> String {
        DetailViewHelpers.formatRelativeDate(date)
    }

    private func formatAlertInterval(_ interval: TimeInterval) -> String {
        DetailViewHelpers.formatAlertInterval(interval)
    }

    private func updateHabitTags(_ newTags: [Tag]) {
        // Remove tags that are no longer selected
        for tag in (habit.tags ?? []) {
            if !newTags.contains(tag) {
                _ = habitManager.removeTag(tag, from: habit)
            }
        }

        // Add newly selected tags
        for tag in newTags {
            if !(habit.tags ?? []).contains(tag) {
                _ = habitManager.addTag(tag, to: habit)
            }
        }
    }

    private func deleteHabit() {
        _ = habitManager.deleteHabit(habit)
        dismiss()
    }

    private func removeTag(_ tag: Tag) {
        _ = habitManager.removeTag(tag, from: habit)
    }

    private func toggleSubtask(_ subtask: HabitSubtask) {
        _ = habitManager.toggleHabitSubtaskCompletion(subtask)
    }

    private func addSubtask() {
        let trimmedTitle = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        // Create subtask directly on the habit model
        _ = habit.createSubtask(title: trimmedTitle)
        newSubtaskTitle = ""
    }

    private func addSubtaskAndClose() {
        addSubtask()
        showSubtaskField = false
        newSubtaskFocused = false
    }
}

// MARK: - Supporting Views

private struct CompletionRowView: View {
    let completion: HabitCompletion
    var showDetails: Bool = false

    var body: some View {
        HStack {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(DateFormatter.mediumDate.string(from: completion.completedDate))
                    .font(.caption.weight(.medium))
                    .foregroundColor(.daisyText)

                if showDetails {
                    Text(completion.timeOfDay.displayName)
                        .font(.caption2)
                        .foregroundColor(.daisyTextSecondary)
                }
            }

            Spacer()

            // Mood
            HStack(spacing: 4) {
                Text(completion.mood.emoji)
                    .font(.caption)

                if showDetails {
                    Text(completion.mood.displayName)
                        .font(.caption2)
                        .foregroundColor(.daisyTextSecondary)
                }
            }

            // Duration
            if let duration = completion.formattedDuration {
                Text(duration)
                    .font(.caption2)
                    .foregroundColor(.daisyTextSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.daisyBackground, in: Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Habit Detail Subtask Row
// HabitDetailSubtaskRow removed - now using shared SubtaskRow component from Core/Design/Components/Shared/Rows/


// MARK: - Date Formatters

private extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}

// MARK: - Preview

#Preview("Habit Detail") {
    HabitDetailPreview()
}

struct HabitDetailPreview: View {
    var body: some View {
        let container = try! ModelContainer(
            for: Habit.self, HabitCompletion.self, HabitStreak.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let habitManager = HabitManager(modelContext: container.mainContext)
        let tagManager = TagManager(modelContext: container.mainContext)
        let toastManager = HabitCompletionToastManager()

        // Create sample tags
        let workoutTag = tagManager.createTag(name: "Workout", sfSymbolName: "figure.run", colorName: "red")!
        let healthTag = tagManager.createTag(name: "Health", sfSymbolName: "heart", colorName: "green")!

        // Create sample habit
        let habit = Habit(
            title: "Morning Exercise",
            habitDescription: "30 minutes of cardio or strength training to energize the day and maintain physical health",
            recurrenceRule: .daily(),
            priority: .high
        )
        habit.currentStreak = 15
        habit.longestStreak = 32
        _ = habit.addTag(workoutTag)
        _ = habit.addTag(healthTag)
        container.mainContext.insert(habit)

        // Add subtasks
        let subtask1 = habit.createSubtask(title: "Warm up stretches")
        let subtask2 = habit.createSubtask(title: "Main workout routine")
        let subtask3 = habit.createSubtask(title: "Cool down and hydrate")
        subtask1.setCompleted(true)

        container.mainContext.insert(subtask1)
        container.mainContext.insert(subtask2)
        container.mainContext.insert(subtask3)

        // Add sample completions
        let calendar = Calendar.current
        for i in 0..<30 {
            if Int.random(in: 0...100) < 80 { // 80% completion rate
                let date = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
                let completion = HabitCompletion(
                    habit: habit,
                    completedDate: date,
                    mood: HabitCompletion.Mood.allCases.randomElement() ?? .neutral,
                    duration: TimeInterval.random(in: 1200...2400) // 20-40 minutes
                )
                container.mainContext.insert(completion)
            }
        }

        try! container.mainContext.save()

        return HabitDetailView(habit: habit)
            .modelContainer(container)
            .environment(habitManager)
            .environment(tagManager)
            .environment(toastManager)
    }
}