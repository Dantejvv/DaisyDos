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
    @State private var habitToDetail: Habit?
    @State private var isReorderMode = false
    @State private var showCompletedBeforeReorder = false
    @AppStorage("habitSortOption") private var sortOptionRaw: String = SortOption.custom.rawValue
    @AppStorage("habitShowCompleted") private var showCompletedHabits = false
    @State private var showingSortOptions = false

    private var currentSortOption: SortOption {
        SortOption(rawValue: sortOptionRaw) ?? .title
    }

    enum SortOption: String, CaseIterable {
        case title = "Title"
        case priority = "Priority"
        case streakLength = "Streak Length"
        case custom = "Custom"

        var systemImage: String {
            switch self {
            case .title: return "textformat.abc"
            case .priority: return "diamond"
            case .streakLength: return "flame"
            case .custom: return "arrow.up.arrow.down"
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
                        if isReorderMode {
                            Button("Done") {
                                withAnimation {
                                    isReorderMode = false
                                    // Restore previous showCompleted preference
                                    showCompletedHabits = showCompletedBeforeReorder
                                }
                            }
                        } else {
                            Button("Reorder") {
                                withAnimation {
                                    // Save current showCompleted preference
                                    showCompletedBeforeReorder = showCompletedHabits
                                    // Auto-show completed habits in reorder mode
                                    showCompletedHabits = true
                                    isReorderMode = true
                                }
                            }
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !isReorderMode {
                            // Show/Hide Completed toggle button
                            Button(action: {
                                withAnimation {
                                    showCompletedHabits.toggle()
                                }
                            }) {
                                Image(systemName: showCompletedHabits ? "eye.fill" : "eye.slash.fill")
                            }

                            // Sort picker button
                            Menu {
                                Text("Sort Habits By")
                                    .font(.headline)

                                Divider()

                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button(action: {
                                        sortOptionRaw = option.rawValue
                                    }) {
                                        Label(option.rawValue, systemImage: option.systemImage)
                                        if currentSortOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: currentSortOption.systemImage)
                            }

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
                TagSelectionView(selectedTags: Binding(
                    get: { Array(habit.tags ?? []) },
                    set: { newTags in
                        // Remove all current tags
                        let currentTags = Array(habit.tags ?? [])
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
                ))
            }
            .navigationDestination(item: $habitToDetail) { habit in
                HabitDetailView(habit: habit)
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
            .onDisappear {
                // Deactivate reorder mode when navigating away
                if isReorderMode {
                    isReorderMode = false
                    // Restore previous showCompleted preference
                    showCompletedHabits = showCompletedBeforeReorder
                }
            }
            .errorAlert(error: Binding(
                get: { habitManager.lastError },
                set: { habitManager.lastError = $0 }
            ))
        }
    }

    // MARK: - Computed Properties

    private var sortedHabits: [Habit] {
        let habits = Array(allHabits)

        // Optimize sorting for large datasets
        switch currentSortOption {
        case .title:
            return habits.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .priority:
            return habits.sorted { habit1, habit2 in
                if habit1.priority == habit2.priority {
                    return habit1.title.localizedCaseInsensitiveCompare(habit2.title) == .orderedAscending
                }
                return habit1.priority.sortOrder > habit2.priority.sortOrder
            }
        case .streakLength:
            return habits.sorted { $0.currentStreak > $1.currentStreak }
        case .custom:
            return habits.sorted { $0.habitOrder < $1.habitOrder }
        }
    }

    private var filteredHabits: [Habit] {
        // In reorder mode, always show habits in custom order
        let habitsToDisplay = isReorderMode ? Array(allHabits).sorted { $0.habitOrder < $1.habitOrder } : sortedHabits

        if showCompletedHabits {
            return habitsToDisplay
        } else {
            return habitsToDisplay.filter { !$0.isCompletedToday }
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
                habitRows(for: filteredHabits)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, isReorderMode ? .constant(.active) : .constant(.inactive))
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
    private func habitRows(for habits: [Habit]) -> some View {
        ForEach(habits) { habit in
            habitRowView(for: habit, in: habits)
                .overlay {
                    if habitToDelete?.id == habit.id {
                        Color.daisyBackground
                    }
                }
                .animation(.none, value: habitToDelete)
                .rowStyling(
                    isSelected: false,
                    accentColor: .daisyHabit,
                    onTap: {
                        if !isReorderMode {
                            habitToDetail = habit
                        }
                    }
                )
                .standardRowSwipeActions(
                    isMultiSelectMode: isReorderMode,
                    accentColor: .daisyHabit,
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
                    onEdit: {
                        habitToEdit = habit
                    },
                    leadingAction: {
                        SkipSwipeAction {
                            habitToSkip = habit
                        }
                    }
                )
        }
        .onMove(perform: isReorderMode ? moveHabits : nil)
    }

    @ViewBuilder
    private func habitRowView(for habit: Habit, in habits: [Habit]) -> some View {
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
            isReorderMode: isReorderMode,
            onMoveUp: {
                moveHabitUp(habit)
            },
            onMoveDown: {
                moveHabitDown(habit)
            },
            canMoveUp: canMoveUp(habit, in: habits),
            canMoveDown: canMoveDown(habit, in: habits)
        )
    }

    // MARK: - Helper Methods

    private func moveHabits(from source: IndexSet, to destination: Int) {
        // Create a mutable copy of the filtered habits for reordering
        var reorderedHabits = filteredHabits
        reorderedHabits.move(fromOffsets: source, toOffset: destination)

        // Update habitOrder for all habits in the reordered list
        _ = habitManager.reorderHabits(reorderedHabits)
    }

    private func moveHabitUp(_ habit: Habit) {
        let habits = filteredHabits
        guard let currentIndex = habits.firstIndex(where: { $0.id == habit.id }),
              currentIndex > 0 else { return }

        var reorderedHabits = habits
        reorderedHabits.swapAt(currentIndex, currentIndex - 1)

        _ = habitManager.reorderHabits(reorderedHabits)
    }

    private func moveHabitDown(_ habit: Habit) {
        let habits = filteredHabits
        guard let currentIndex = habits.firstIndex(where: { $0.id == habit.id }),
              currentIndex < habits.count - 1 else { return }

        var reorderedHabits = habits
        reorderedHabits.swapAt(currentIndex, currentIndex + 1)

        _ = habitManager.reorderHabits(reorderedHabits)
    }

    private func canMoveUp(_ habit: Habit, in habits: [Habit]) -> Bool {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return false }
        return index > 0
    }

    private func canMoveDown(_ habit: Habit, in habits: [Habit]) -> Bool {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return false }
        return index < habits.count - 1
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