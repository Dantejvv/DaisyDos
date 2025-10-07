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
    @State private var showingBulkDeleteConfirmation = false
    @State private var habitToSkip: Habit?
    @State private var habitToEdit: Habit?
    @State private var habitToAssignTags: Habit?
    @State private var habitToDetail: Habit?
    @State private var isMultiSelectMode = false
    @State private var selectedHabits: Set<Habit.ID> = []
    @State private var sortOption: SortOption = .creationDate
    @State private var sectionOption: SectionOption = .none
    @State private var showingSortOptions = false

    enum SortOption: String, CaseIterable {
        case creationDate = "Creation Date"
        case streakLength = "Streak Length"
        case priority = "Priority"
        case title = "Title"

        var systemImage: String {
            switch self {
            case .creationDate: return "calendar"
            case .streakLength: return "flame"
            case .priority: return "diamond"
            case .title: return "textformat.abc"
            }
        }
    }

    enum SectionOption: String, CaseIterable {
        case none = "None"
        case priority = "Priority"
        case tags = "Tags"
        case createdDate = "Created"
        case frequency = "Frequency"
        case streakStatus = "Streak Status"

        var systemImage: String {
            switch self {
            case .none: return "list.bullet"
            case .priority: return "exclamationmark.triangle"
            case .tags: return "tag"
            case .createdDate: return "clock"
            case .frequency: return "repeat"
            case .streakStatus: return "flame"
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
                ToolbarItem(placement: .navigationBarLeading) {
                    if !allHabits.isEmpty {
                        Button(isMultiSelectMode ? "Done" : "Select") {
                            withAnimation {
                                isMultiSelectMode.toggle()
                                if !isMultiSelectMode {
                                    selectedHabits.removeAll()
                                }
                            }
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !isMultiSelectMode && !allHabits.isEmpty {
                            // Sort picker button
                            Menu {
                                Text("Sort Habits By")
                                    .font(.headline)

                                Divider()

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
                                Image(systemName: sortOption.systemImage)
                                    .foregroundColor(.daisyToolbar)
                            }

                            // Section picker button
                            Menu {
                                Text("Group Habits By")
                                    .font(.headline)

                                Divider()

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
                                Image(systemName: sectionOption.systemImage)
                                    .foregroundColor(.daisyToolbar)
                            }
                        }

                        if isMultiSelectMode {
                            Menu {
                                Button("Select All") {
                                    selectedHabits = Set(allHabits.map(\.id))
                                }
                                .disabled(selectedHabits.count == allHabits.count)

                                Button("Select None") {
                                    selectedHabits.removeAll()
                                }
                                .disabled(selectedHabits.isEmpty)
                            } label: {
                                Image(systemName: "ellipsis")
                            }
                        } else {
                            Button(action: {
                                showingAddHabit = true
                            }) {
                                Image(systemName: "plus")
                            }
                        }
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
            .safeAreaInset(edge: .bottom) {
                if isMultiSelectMode && !selectedHabits.isEmpty {
                    bulkActionToolbar
                }
            }
            .navigationDestination(item: $habitToDetail) { habit in
                HabitDetailView(habit: habit, modelContext: modelContext)
            }
            .alert(
                "Delete Habit",
                isPresented: $showingDeleteConfirmation,
                presenting: habitToDelete
            ) { habit in
                Button("Delete", role: .destructive) {
                    _ = habitManager.deleteHabit(habit)
                    habitToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    habitToDelete = nil
                }
            } message: { habit in
                Text("Are you sure you want to delete '\(habit.title)'?")
            }
            .onChange(of: showingDeleteConfirmation) { _, isShowing in
                // Clear habitToDelete when confirmation is dismissed without deletion
                if !isShowing && habitToDelete != nil {
                    // Check if the habit still exists (wasn't deleted)
                    if allHabits.contains(where: { $0.id == habitToDelete?.id }) {
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            habitToDelete = nil
                        }
                    }
                }
            }
            .alert(
                "Delete \(selectedHabits.count) Habits",
                isPresented: $showingBulkDeleteConfirmation
            ) {
                Button("Delete \(selectedHabits.count) Habits", role: .destructive) {
                    bulkDelete()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete \(selectedHabits.count) selected habits? This action cannot be undone.")
            }
            .onDisappear {
                // Deactivate multi-select mode when navigating away
                if isMultiSelectMode {
                    isMultiSelectMode = false
                    selectedHabits.removeAll()
                }
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
        case .priority:
            return habits.sorted { habit1, habit2 in
                if habit1.priority == habit2.priority {
                    return habit1.createdDate > habit2.createdDate
                }
                return habit1.priority.sortOrder > habit2.priority.sortOrder
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

        case .priority:
            let grouped = HabitPriority.group(habits)
            var sections: [(String, [Habit])] = []

            // Order sections by priority (High → Medium → Low)
            for priority in HabitPriority.sortedByPriority {
                if let habitsForPriority = grouped[priority], !habitsForPriority.isEmpty {
                    let sectionTitle = "\(priority.displayName) (\(habitsForPriority.count))"
                    sections.append((sectionTitle, habitsForPriority))
                }
            }
            return sections

        case .tags:
            var taggedHabits: [(String, [Habit])] = []
            var untaggedHabits: [Habit] = []
            var usedTags: Set<String> = []

            for habit in habits {
                if habit.tags.isEmpty {
                    untaggedHabits.append(habit)
                } else {
                    for tag in habit.tags {
                        if !usedTags.contains(tag.name) {
                            usedTags.insert(tag.name)
                            let habitsWithThisTag = habits.filter { $0.tags.contains(tag) }
                            taggedHabits.append(("\(tag.name) (\(habitsWithThisTag.count))", habitsWithThisTag))
                        }
                    }
                }
            }

            // Sort tag sections alphabetically
            taggedHabits.sort { $0.0 < $1.0 }

            // Add untagged section at the end if there are untagged habits
            if !untaggedHabits.isEmpty {
                taggedHabits.append(("No Tags (\(untaggedHabits.count))", untaggedHabits))
            }

            return taggedHabits

        case .createdDate:
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let lastWeek = calendar.date(byAdding: .day, value: -7, to: today)!
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: today)!

            var todayHabits: [Habit] = []
            var yesterdayHabits: [Habit] = []
            var thisWeekHabits: [Habit] = []
            var thisMonthHabits: [Habit] = []
            var olderHabits: [Habit] = []

            for habit in habits {
                let createdDay = calendar.startOfDay(for: habit.createdDate)

                if createdDay == today {
                    todayHabits.append(habit)
                } else if createdDay == calendar.startOfDay(for: yesterday) {
                    yesterdayHabits.append(habit)
                } else if createdDay >= lastWeek {
                    thisWeekHabits.append(habit)
                } else if createdDay >= lastMonth {
                    thisMonthHabits.append(habit)
                } else {
                    olderHabits.append(habit)
                }
            }

            var sections: [(String, [Habit])] = []

            if !todayHabits.isEmpty {
                sections.append(("Today (\(todayHabits.count))", todayHabits))
            }
            if !yesterdayHabits.isEmpty {
                sections.append(("Yesterday (\(yesterdayHabits.count))", yesterdayHabits))
            }
            if !thisWeekHabits.isEmpty {
                sections.append(("This Week (\(thisWeekHabits.count))", thisWeekHabits))
            }
            if !thisMonthHabits.isEmpty {
                sections.append(("This Month (\(thisMonthHabits.count))", thisMonthHabits))
            }
            if !olderHabits.isEmpty {
                sections.append(("Older (\(olderHabits.count))", olderHabits))
            }

            return sections

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

        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private var habitListView: some View {
        VStack(spacing: 0) {
            // Overall progress indicator when not sectioned
            if !allHabits.isEmpty {
                overallProgressIndicator
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.daisySurface)
            }

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
            habitRowView(for: habit)
                .overlay {
                    if habitToDelete?.id == habit.id {
                        Color.daisyBackground
                    }
                }
                .animation(.none, value: habitToDelete)
                .listRowBackground(
                    // Selected row background and border accent
                    Group {
                        if isMultiSelectMode && selectedHabits.contains(habit.id) {
                            HStack(spacing: 0) {
                                // Left border accent
                                Rectangle()
                                    .fill(Color.daisyHabit)
                                    .frame(width: 6)

                                // Background tint
                                Color.daisyHabit.opacity(0.15)
                            }
                        } else {
                            Color.clear
                        }
                    }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if isMultiSelectMode {
                        toggleHabitSelection(habit)
                    } else {
                        habitToDetail = habit
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if !isMultiSelectMode {
                        Button(role: .destructive, action: {
                            var transaction = Transaction()
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                habitToDelete = habit
                            }
                            // Delay showing confirmation to let overlay render first
                            DispatchQueue.main.async {
                                showingDeleteConfirmation = true
                            }
                        }) {
                            Label("Delete", systemImage: "trash")
                        }

                        Button(action: {
                            habitToEdit = habit
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.daisyHabit)
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    if !isMultiSelectMode {
                        Button(action: {
                            habitToSkip = habit
                        }) {
                            Label("Skip", systemImage: "forward")
                        }
                        .tint(.orange)
                    }
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
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    habitToDelete = habit
                }
                // Delay showing confirmation to let overlay render first
                DispatchQueue.main.async {
                    showingDeleteConfirmation = true
                }
            },
            onSkip: {
                habitToSkip = habit
            },
            onTagAssignment: {
                habitToAssignTags = habit
            },
            displayMode: .compact
        )
    }

    // MARK: - Bulk Action Toolbar

    @ViewBuilder
    private var bulkActionToolbar: some View {
        HStack {
            Text("\(selectedHabits.count) selected")
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)

            Spacer()

            HStack(spacing: 20) {
                // Bulk completion
                Button(action: {
                    bulkMarkComplete()
                }) {
                    Label("Mark Complete", systemImage: "checkmark.circle")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                }
                .foregroundColor(.daisySuccess)

                // Bulk skip
                Button(action: {
                    bulkSkip()
                }) {
                    Label("Skip", systemImage: "forward")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                }
                .foregroundColor(.daisyWarning)

                // Bulk delete
                Button(action: {
                    showingBulkDeleteConfirmation = true
                }) {
                    Label("Delete", systemImage: "trash")
                        .labelStyle(.iconOnly)
                        .font(.title3)
                }
                .foregroundColor(.daisyError)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    // MARK: - Helper Methods

    private func toggleHabitSelection(_ habit: Habit) {
        if selectedHabits.contains(habit.id) {
            selectedHabits.remove(habit.id)
        } else {
            selectedHabits.insert(habit.id)
        }
    }

    private func bulkMarkComplete() {
        let habitsToComplete = allHabits.filter { selectedHabits.contains($0.id) }
        for habit in habitsToComplete {
            if !habit.isCompletedToday {
                let _ = habitManager.markHabitCompletedWithTracking(habit)
            }
        }
        selectedHabits.removeAll()
        isMultiSelectMode = false
    }

    private func bulkSkip() {
        let habitsToSkip = allHabits.filter { selectedHabits.contains($0.id) }
        for habit in habitsToSkip {
            let _ = habitManager.skipHabit(habit, reason: "Bulk skip")
        }
        selectedHabits.removeAll()
        isMultiSelectMode = false
    }

    private func bulkDelete() {
        let habitsToDelete = allHabits.filter { selectedHabits.contains($0.id) }
        _ = habitManager.deleteHabits(habitsToDelete)
        selectedHabits.removeAll()
        isMultiSelectMode = false
    }

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