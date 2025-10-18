//
//  HabitDetailView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI
import SwiftData

struct HabitDetailView: View {
    // MARK: - Properties

    @Bindable var habit: Habit
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(HabitCompletionToastManager.self) private var toastManager

    @State private var habitManager: HabitManager
    @State private var selectedTab: DetailTab = .overview
    @State private var showingEditView = false
    @State private var showingDeleteAlert = false
    @State private var showingSkipView = false

    // MARK: - Initializer

    init(habit: Habit, modelContext: ModelContext) {
        self.habit = habit
        self._habitManager = State(initialValue: HabitManager(modelContext: modelContext))
    }

    // MARK: - Detail Tabs

    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case analytics = "Analytics"
        case history = "History"

        var icon: String {
            switch self {
            case .overview: return "info.circle"
            case .analytics: return "chart.bar"
            case .history: return "calendar"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Tab Picker
                tabPicker

                // Tab Content
                TabView(selection: $selectedTab) {
                    overviewTab
                        .tag(DetailTab.overview)

                    analyticsTab
                        .tag(DetailTab.analytics)

                    historyTab
                        .tag(DetailTab.history)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(habit.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingEditView = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Divider()

                        // Quick Actions
                        if habit.isCompletedToday {
                            Button {
                                let _ = habitManager.undoHabitCompletion(habit)
                            } label: {
                                Label("Mark Incomplete", systemImage: "minus.circle")
                            }
                        } else {
                            Button {
                                if let _ = habitManager.markHabitCompletedWithTracking(habit) {
                                    toastManager.showCompletionToast(for: habit) {
                                        let _ = habitManager.undoHabitCompletion(habit)
                                    }
                                }
                            } label: {
                                Label("Mark Complete", systemImage: "checkmark.circle")
                            }
                        }

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
                    let _ = habitManager.skipHabit(habit, reason: reason)
                }
            )
        }
        .alert("Delete Habit", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteHabit()
            }
        } message: {
            Text("Are you sure you want to delete '\(habit.title)'? This action cannot be undone.")
        }
    }

    // MARK: - Tab Picker

    @ViewBuilder
    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.body.weight(.medium))

                        Text(tab.rawValue)
                            .font(.caption.weight(.medium))
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .foregroundColor(selectedTab == tab ? .daisyHabit : .daisyTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .background(
                    Rectangle()
                        .fill(selectedTab == tab ? Color.daisyHabit.opacity(0.1) : Color.clear)
                        .animation(.easeInOut(duration: 0.3), value: selectedTab)
                )
            }
        }
        .background(Color.daisySurface)
        .overlay(
            // Selection indicator
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.daisyHabit)
                        .frame(width: geometry.size.width / CGFloat(DetailTab.allCases.count), height: 2)
                        .offset(x: tabIndicatorOffset(for: geometry.size.width))
                        .animation(.easeInOut(duration: 0.3), value: selectedTab)
                }
            }
        )
    }

    private func tabIndicatorOffset(for totalWidth: CGFloat) -> CGFloat {
        let tabWidth = totalWidth / CGFloat(DetailTab.allCases.count)
        let index = DetailTab.allCases.firstIndex(of: selectedTab) ?? 0
        return CGFloat(index) * tabWidth
    }

    // MARK: - Overview Tab

    @ViewBuilder
    private var overviewTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Habit Information Card
                habitInfoCard

                // Current Status Card
                currentStatusCard

                // Tags Section
                if !habit.tags.isEmpty {
                    tagsCard
                }

            }
            .padding()
        }
        .background(Color.daisyBackground)
        .overlay(alignment: .bottomTrailing) {
            // Floating completion toggle
            Button(action: {
                if habit.isCompletedToday {
                    let _ = habitManager.undoHabitCompletion(habit)
                } else {
                    if let _ = habitManager.markHabitCompletedWithTracking(habit) {
                        toastManager.showCompletionToast(for: habit) {
                            let _ = habitManager.undoHabitCompletion(habit)
                        }
                    }
                }
            }) {
                Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundColor(habit.isCompletedToday ? .daisySuccess : .daisyHabit)
                    .background(
                        Circle()
                            .fill(.regularMaterial)
                            .shadow(radius: 8)
                    )
            }
            .frame(minWidth: 64, minHeight: 64)
            .padding()
            .accessibilityLabel(habit.isCompletedToday ? "Mark as incomplete" : "Mark as complete")
            .accessibilityHint("Double tap to toggle completion status")
        }
    }

    // MARK: - Analytics Tab

    @ViewBuilder
    private var analyticsTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Progress Chart
                HabitProgressChart(
                    habit: habit,
                    timeframe: .month,
                    habitManager: habitManager
                )

                // Streak Visualization
                StreakVisualizationView(
                    habit: habit,
                    habitManager: habitManager
                )

            }
            .padding()
        }
        .background(Color.daisyBackground)
    }

    // MARK: - History Tab

    @ViewBuilder
    private var historyTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Heatmap
                let endDate = Date()
                let startDate = Calendar.current.date(byAdding: .month, value: -6, to: endDate) ?? endDate

                HabitHeatmapView(
                    habit: habit,
                    habitManager: habitManager,
                    dateRange: startDate...endDate
                )

                // Completion History List
                completionHistoryCard
            }
            .padding()
        }
        .background(Color.daisyBackground)
    }

    // MARK: - Overview Cards

    @ViewBuilder
    private var habitInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("About")
                    .font(.headline)
                    .foregroundColor(.daisyText)
                Spacer()
                if habit.priority != .none {
                    HStack(spacing: 6) {
                        habit.priority.indicatorView()
                            .font(.caption)
                        Text(habit.priority.displayName)
                            .font(.caption.weight(.medium))
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
            }

            if !habit.habitDescription.isEmpty {
                ScrollableDescriptionView(
                    text: habit.habitDescriptionAttributed,
                    maxHeight: 200
                )
            }

            if let recurrenceRule = habit.recurrenceRule {
                Label(
                    recurrenceRule.displayDescription,
                    systemImage: "repeat"
                )
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Label(
                    "Created \(habit.createdDate.formatted(date: .abbreviated, time: .omitted))",
                    systemImage: "calendar"
                )
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)

                // Only show modified if different from created (more than 1 minute difference)
                if habit.modifiedDate.timeIntervalSince(habit.createdDate) > 60 {
                    Label(
                        "Modified \(habit.modifiedDate.formatted(date: .abbreviated, time: .omitted))",
                        systemImage: "pencil.circle"
                    )
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var currentStatusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Status")
                .font(.headline)
                .foregroundColor(.daisyText)

            HStack {
                // Current Streak
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)

                        Text("\(habit.currentStreak)")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.daisyText)

                        Text("days")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }

                    Text("Current Streak")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }

                Spacer()

                // Completion Status
                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: habit.isCompletedToday ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(habit.isCompletedToday ? .daisySuccess : .daisyTextSecondary)

                    Text(habit.isCompletedToday ? "Completed Today" : "Not Completed")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }

        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var tagsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(.daisyText)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(habit.tags, id: \.id) { tag in
                    TagChipView(tag: tag)
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
    }



    // MARK: - History Cards

    @ViewBuilder
    private var completionHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Completion History")
                .font(.headline)
                .foregroundColor(.daisyText)

            let sortedCompletions = habit.completionEntries
                .sorted { $0.completedDate > $1.completedDate }

            if sortedCompletions.isEmpty {
                Text("No completions recorded yet")
                    .font(.body)
                    .foregroundColor(.daisyTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(sortedCompletions.prefix(20), id: \.id) { completion in
                        CompletionRowView(completion: completion, showDetails: true)
                    }

                    if sortedCompletions.count > 20 {
                        Text("\(sortedCompletions.count - 20) more completions")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                            .padding(.top, 8)
                    }
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helper Methods

    private func deleteHabit() {
        _ = habitManager.deleteHabit(habit)
        dismiss()
    }
}

// MARK: - Supporting Views

struct CompletionRowView: View {
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

struct MetricTile: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 60)
        .padding()
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

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
    HabitDetailViewPreview()
}

struct HabitDetailViewPreview: View {
    var body: some View {
        let container = try! ModelContainer(
            for: Habit.self, HabitCompletion.self, HabitStreak.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let tagManager = TagManager(modelContext: context)

        // Create sample tags
        let workoutTag = tagManager.createTag(name: "Workout", sfSymbolName: "figure.run", colorName: "red")!
        let healthTag = tagManager.createTag(name: "Health", sfSymbolName: "heart", colorName: "green")!

        // Create sample habit
        let habit = Habit(
            title: "Morning Exercise",
            habitDescription: "30 minutes of cardio or strength training to energize the day and maintain physical health",
            recurrenceRule: .daily(),
        )
        habit.currentStreak = 15
        habit.longestStreak = 32
        _ = habit.addTag(workoutTag)
        _ = habit.addTag(healthTag)
        context.insert(habit)

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
                context.insert(completion)
            }
        }

        try! context.save()

        return HabitDetailView(habit: habit, modelContext: context)
            .modelContainer(container)
    }
}