//
//  HabitsView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(HabitManager.self) private var habitManager
    @Environment(HabitCompletionToastManager.self) private var toastManager
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Habit.createdDate, order: .reverse) private var allHabits: [Habit]
    @State private var searchText = ""
    @State private var showingAddHabit = false
    @State private var habitToDelete: Habit?
    @State private var showingDeleteConfirmation = false
    @State private var habitToSkip: Habit?
    @State private var habitToEdit: Habit?
    @State private var habitToAssignTags: Habit?
    @State private var sortOption: SortOption = .creationDate
    @State private var sectionOption: SectionOption = .none
    @State private var showingSortOptions = false

    enum SortOption: String, CaseIterable {
        case creationDate = "Creation Date"
        case streakLength = "Streak Length"
        case completionRate = "Completion Rate"
        case title = "Title"

        var systemImage: String {
            switch self {
            case .creationDate: return "calendar"
            case .streakLength: return "flame"
            case .completionRate: return "chart.bar"
            case .title: return "textformat.abc"
            }
        }
    }

    enum SectionOption: String, CaseIterable {
        case none = "None"
        case frequency = "Frequency"
        case streakStatus = "Streak Status"
        case tags = "Tags"

        var systemImage: String {
            switch self {
            case .none: return "list.bullet"
            case .frequency: return "repeat"
            case .streakStatus: return "flame"
            case .tags: return "tag"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                if allHabits.isEmpty {
                    // Empty state
                    Spacer()
                    VStack(spacing: 20) {
                        Image(systemName: "repeat.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)

                        Text("No Habits Yet")
                            .font(.title2.bold())

                        Text("Build positive routines by creating your first habit. Consistency is key to success!")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text("Tap the + button to create your first habit!")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                            .padding(.horizontal)
                    }
                    Spacer()

                } else {
                    // Habit list
                    habitListView
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddHabit = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .sheet(item: $habitToSkip) { habit in
                SimpleHabitSkipView(
                    habit: habit,
                    onSkip: { reason in
                        let _ = habitManager.skipHabit(habit, reason: reason)
                        self.habitToSkip = nil
                    }
                )
                .environment(habitManager)
            }
            .sheet(item: $habitToEdit) { habit in
                HabitEditView(habit: habit)
                    .environment(habitManager)
            }
            .sheet(item: $habitToAssignTags) { habit in
                TagAssignmentSheet(
                    title: "Habit Tags",
                    selectedTags: Binding(
                        get: { Array(habit.tags) },
                        set: { newTags in
                            // Remove all current tags
                            let currentTags = Array(habit.tags)
                            for tag in currentTags {
                                habit.removeTag(tag)
                            }
                            // Add new tags
                            for tag in newTags {
                                _ = habit.addTag(tag)
                            }
                            // Save changes
                            try? modelContext.save()
                        }
                    ),
                    onSave: { _ in
                        self.habitToAssignTags = nil
                    }
                )
            }
            .alert(
                "Delete Habit",
                isPresented: $showingDeleteConfirmation,
                presenting: habitToDelete
            ) { habit in
                Button("Delete", role: .destructive) {
                    habitManager.deleteHabit(habit)
                }
                Button("Cancel", role: .cancel) { }
            } message: { habit in
                Text("Are you sure you want to delete '\(habit.title)'?")
            }
        }
    }

    // MARK: - Computed Properties

    private var sortedHabits: [Habit] {
        let habits = Array(allHabits)

        // Optimize sorting for large datasets
        switch sortOption {
        case .creationDate:
            return habits.sorted { $0.createdDate > $1.createdDate }
        case .streakLength:
            return habits.sorted { $0.currentStreak > $1.currentStreak }
        case .completionRate:
            // Cache completion rates to avoid repeated calculations
            let completionRates = habits.reduce(into: [Habit.ID: Double]()) { result, habit in
                result[habit.id] = habitManager.getCompletionRate(for: habit, period: .month)
            }
            return habits.sorted {
                (completionRates[$0.id] ?? 0) > (completionRates[$1.id] ?? 0)
            }
        case .title:
            return habits.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        }
    }

    private var sectionedHabits: [(String, [Habit])] {
        let habits = sortedHabits

        switch sectionOption {
        case .none:
            return [("", habits)]

        case .frequency:
            let grouped = Dictionary(grouping: habits) { habit in
                habit.recurrenceRule?.frequency.rawValue.capitalized ?? "Daily"
            }
            return grouped.sorted { $0.key < $1.key }

        case .streakStatus:
            let grouped = Dictionary(grouping: habits) { habit in
                switch habit.currentStreak {
                case 0:
                    return "New Habits"
                case 1...6:
                    return "Building (1-6 days)"
                case 7...20:
                    return "Established (7-20 days)"
                case 21...66:
                    return "Strong (21-66 days)"
                default:
                    return "Mastered (66+ days)"
                }
            }
            let order = ["New Habits", "Building (1-6 days)", "Established (7-20 days)", "Strong (21-66 days)", "Mastered (66+ days)"]
            return order.compactMap { key in
                guard let habits = grouped[key], !habits.isEmpty else { return nil }
                return (key, habits)
            }

        case .tags:
            var taggedHabits: [(String, [Habit])] = []
            var untaggedHabits: [Habit] = []

            for habit in habits {
                if habit.tags.isEmpty {
                    untaggedHabits.append(habit)
                } else {
                    for tag in habit.tags {
                        let tagName = tag.name
                        if let index = taggedHabits.firstIndex(where: { $0.0 == tagName }) {
                            taggedHabits[index].1.append(habit)
                        } else {
                            taggedHabits.append((tagName, [habit]))
                        }
                    }
                }
            }

            taggedHabits.sort { $0.0 < $1.0 }
            if !untaggedHabits.isEmpty {
                taggedHabits.append(("No Tags", untaggedHabits))
            }

            return taggedHabits
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private var habitListView: some View {
        VStack(spacing: 0) {
            // Sort and Section Controls
            sortAndSectionControls

            // Habit List (optimized for large datasets)
            List {
                ForEach(sectionedHabits, id: \.0) { sectionTitle, habits in
                    if sectionOption != .none {
                        Section(header: sectionHeaderView(title: sectionTitle, count: habits.count)) {
                            habitRows(for: habits)
                        }
                        .listSectionSpacing(.compact)
                    } else {
                        habitRows(for: habits)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable {
                // Refresh is handled automatically by @Query
            }
        }
    }

    @ViewBuilder
    private var sortAndSectionControls: some View {
        VStack(spacing: 8) {
            HStack {
                // Sort Button
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: {
                            sortOption = option
                        }) {
                            Label(option.rawValue, systemImage: option.systemImage)
                            if sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: sortOption.systemImage)
                        Text("Sort")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(.daisyText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.daisyBackground, in: Capsule())
                }

                Spacer()

                // Section Button
                Menu {
                    ForEach(SectionOption.allCases, id: \.self) { option in
                        Button(action: {
                            sectionOption = option
                        }) {
                            Label(option.rawValue, systemImage: option.systemImage)
                            if sectionOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: sectionOption.systemImage)
                        Text("Group")
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(.daisyText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.daisyBackground, in: Capsule())
                }
            }

            // Overall progress indicator when not sectioned
            if sectionOption == .none && !allHabits.isEmpty {
                overallProgressIndicator
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.daisySurface)
    }

    @ViewBuilder
    private var overallProgressIndicator: some View {
        let completedToday = allHabits.filter { $0.isCompletedToday }.count
        let totalHabits = allHabits.count
        let progressPercent = totalHabits > 0 ? Double(completedToday) / Double(totalHabits) : 0

        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Progress")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.daisyText)

                HStack(spacing: 8) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.daisyBackground)
                                .frame(height: 6)

                            // Progress fill
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.daisySuccess)
                                .frame(width: geometry.size.width * progressPercent, height: 6)
                        }
                    }
                    .frame(height: 6)

                    // Progress text
                    Text("\(completedToday)/\(totalHabits)")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.daisyText)
                        .monospacedDigit()

                    // Percentage
                    Text("\(Int(progressPercent * 100))%")
                        .font(.caption2)
                        .foregroundColor(.daisyTextSecondary)
                }
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func sectionHeaderView(title: String, count: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.daisyText)

                if sectionOption != .none {
                    let sectionHabits = sectionedHabits.first(where: { $0.0 == title })?.1 ?? []
                    progressIndicator(for: sectionHabits)
                }
            }

            Spacer()

            Text("\(count)")
                .font(.caption.weight(.medium))
                .foregroundColor(.daisyTextSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.daisyBackground, in: Capsule())
        }
    }

    @ViewBuilder
    private func progressIndicator(for habits: [Habit]) -> some View {
        let completedToday = habits.filter { $0.isCompletedToday }.count
        let totalHabits = habits.count
        let progressPercent = totalHabits > 0 ? Double(completedToday) / Double(totalHabits) : 0

        HStack(spacing: 6) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.daisyBackground)
                        .frame(height: 4)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.daisySuccess)
                        .frame(width: geometry.size.width * progressPercent, height: 4)
                }
            }
            .frame(width: 60, height: 4)

            // Progress text
            Text("\(completedToday)/\(totalHabits)")
                .font(.caption2)
                .foregroundColor(.daisyTextSecondary)
                .monospacedDigit()
        }
    }

    @ViewBuilder
    private func habitRows(for habits: [Habit]) -> some View {
        ForEach(habits) { habit in
            NavigationLink(destination: HabitDetailView(habit: habit, modelContext: modelContext)) {
                habitRowView(for: habit)
            }
        }
    }

    @ViewBuilder
    private func habitRowView(for habit: Habit) -> some View {
        HabitRowView(
            habit: habit,
            onMarkComplete: {
                handleHabitCompletion(habit)
            },
            onEdit: {
                habitToEdit = habit
            },
            onDelete: {
                habitToDelete = habit
                showingDeleteConfirmation = true
            },
            onSkip: {
                habitToSkip = habit
            },
            onTagAssignment: {
                habitToAssignTags = habit
            }
        )
    }

    // MARK: - Helper Methods

    private func handleHabitCompletion(_ habit: Habit) {
        if habit.isCompletedToday {
            // Undo completion directly
            let _ = habitManager.undoHabitCompletion(habit)
        } else {
            // Mark complete and show undo toast
            if let _ = habitManager.markHabitCompletedWithTracking(habit) {
                toastManager.showCompletionToast(for: habit) {
                    let _ = habitManager.undoHabitCompletion(habit)
                }
            }
        }
    }
}


#Preview {
    let container = try! ModelContainer(for: Habit.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return HabitsView()
        .modelContainer(container)
        .environment(HabitManager(modelContext: container.mainContext))
}