//
//  TodayView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//  Rebuilt on 1/2/25 - Unified task/habit list with time-based sorting
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(TaskManager.self) private var taskManager
    @Environment(HabitManager.self) private var habitManager
    @Environment(TagManager.self) private var tagManager
    @Environment(TaskCompletionToastManager.self) private var taskToastManager
    @Environment(HabitCompletionToastManager.self) private var habitToastManager
    @Environment(NavigationManager.self) private var navigationManager

    // SwiftData queries for automatic updates
    @Query(sort: [SortDescriptor(\Task.createdDate, order: .reverse)])
    private var allTasks: [Task]

    @Query(sort: [SortDescriptor(\Habit.createdDate, order: .reverse)])
    private var allHabits: [Habit]

    // ViewModel for unified list
    @State private var viewModel = TodayViewModel()

    // Multi-select and UI states
    @State private var isMultiSelectMode = false
    @State private var selectedItems: Set<UUID> = []
    @State private var searchText = ""
    @State private var isSearchPresented = false
    @AppStorage("todaySortOption") private var sortOptionRaw: String = SortOption.title.rawValue
    @AppStorage("todayShowCompleted") private var showCompletedItems = false

    private var sortOption: SortOption {
        get { SortOption(rawValue: sortOptionRaw) ?? .title }
    }

    // Sheet states
    @State private var showingAddTask = false
    @State private var showingAddHabit = false
    @State private var showingRescheduleSheet = false
    @State private var showingSkipReasonSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingBulkDeleteConfirmation = false
    @State private var itemToDelete: TodayItem?
    @State private var taskToReschedule: Task?
    @State private var habitToSkip: Habit?
    @State private var skipReason: String = ""
    @State private var rescheduleDate: Date = Date()

    // Detail navigation
    @State private var taskToDetail: Task?
    @State private var habitToDetail: Habit?

    // Edit sheets
    @State private var taskToEdit: Task?
    @State private var habitToEdit: Habit?

    // MARK: - Sort and Section Options

    enum SortOption: String, CaseIterable {
        case title = "Title"
        case priority = "Priority"
        case creationDate = "Creation Date"
        case dueDate = "Due Date"

        var systemImage: String {
            switch self {
            case .title: return "textformat.abc"
            case .priority: return "exclamationmark.triangle"
            case .creationDate: return "calendar"
            case .dueDate: return "calendar.badge.clock"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.todayItems.isEmpty {
                    emptyStateView
                } else if filteredItems.isEmpty && !searchText.isEmpty {
                    // No search results state
                    noSearchResultsView
                } else {
                    todayItemsList
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, isPresented: $isSearchPresented, prompt: "Search today's items...")
            .navigationTabCleanup(
                navigationManager: navigationManager,
                currentTab: .today,
                searchText: $searchText,
                isSearchPresented: $isSearchPresented,
                isMultiSelectMode: $isMultiSelectMode,
                selectedItems: $selectedItems
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.todayItems.isEmpty {
                        Button(isMultiSelectMode ? "Done" : "Select") {
                            withAnimation {
                                isMultiSelectMode.toggle()
                                if !isMultiSelectMode {
                                    selectedItems.removeAll()
                                }
                            }
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if !isMultiSelectMode {
                            // Show/Hide Completed toggle button
                            Button(action: {
                                withAnimation {
                                    showCompletedItems.toggle()
                                }
                            }) {
                                Image(systemName: showCompletedItems ? "eye.fill" : "eye.slash.fill")
                            }

                            // Sort picker button
                            Menu {
                                Text("Sort Today By")
                                    .font(.headline)

                                Divider()

                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button(action: {
                                        sortOptionRaw = option.rawValue
                                    }) {
                                        Label(option.rawValue, systemImage: option.systemImage)
                                        if sortOption == option {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: sortOption.systemImage)
                            }
                        }

                        if isMultiSelectMode {
                            Menu {
                                Button("Select All") {
                                    selectedItems = Set(sortedItems.map(\.id))
                                }
                                .disabled(selectedItems.count == sortedItems.count)

                                Button("Select None") {
                                    selectedItems.removeAll()
                                }
                                .disabled(selectedItems.isEmpty)
                            } label: {
                                Image(systemName: "ellipsis")
                            }
                        } else {
                            // Quick add button
                            Menu {
                                Button(action: {
                                    showingAddTask = true
                                }) {
                                    Label("Add Task", systemImage: "checkmark.circle")
                                }

                                Button(action: {
                                    showingAddHabit = true
                                }) {
                                    Label("Add Habit", systemImage: "repeat.circle")
                                }
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isMultiSelectMode && !selectedItems.isEmpty {
                    bulkActionToolbar
                }
            }
            .onAppear {
                updateTodayItems()
            }
            .onChange(of: allTasks) {
                updateTodayItems()
            }
            .onChange(of: allHabits) {
                updateTodayItems()
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView()
            }
            .sheet(item: $taskToEdit) { task in
                TaskEditView(task: task)
            }
            .sheet(item: $habitToEdit) { habit in
                HabitEditView(habit: habit)
            }
            .sheet(isPresented: $showingRescheduleSheet) {
                if let task = taskToReschedule {
                    rescheduleSheet(for: task)
                }
            }
            .sheet(isPresented: $showingSkipReasonSheet) {
                if let habit = habitToSkip {
                    skipReasonSheet(for: habit)
                }
            }
            .navigationDestination(item: $taskToDetail) { task in
                TaskDetailView(task: task)
            }
            .navigationDestination(item: $habitToDetail) { habit in
                HabitDetailView(habit: habit)
            }
            .alert(
                "Delete \(selectedItems.count) Items",
                isPresented: $showingBulkDeleteConfirmation
            ) {
                Button("Delete \(selectedItems.count) Items", role: .destructive) {
                    bulkDelete()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete \(selectedItems.count) selected items? This action cannot be undone.")
            }
            .alert(
                itemToDelete?.asTask != nil ? "Delete Task" : "Delete Habit",
                isPresented: $showingDeleteConfirmation
            ) {
                Button("Delete", role: .destructive) {
                    if let item = itemToDelete {
                        performDelete(for: item)
                    }
                    itemToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    itemToDelete = nil
                }
            } message: {
                if let item = itemToDelete {
                    Text("Are you sure you want to delete \"\(item.title)\"? This action cannot be undone.")
                }
            }
            .onChange(of: showingDeleteConfirmation) { _, isShowing in
                // Clear itemToDelete when confirmation is dismissed without deletion
                if !isShowing {
                    itemToDelete = nil
                }
            }
            .errorAlert(error: Binding(
                get: { taskManager.lastError },
                set: { taskManager.lastError = $0 }
            ))
            .errorAlert(error: Binding(
                get: { habitManager.lastError },
                set: { habitManager.lastError = $0 }
            ))
        }
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyStateView: some View {
        VStack {
            Spacer()
            VStack(spacing: 20) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)

                Text("All Clear!")
                    .font(.title2.bold())

                Text("No tasks or habits due today.\nCheck back tomorrow or add something new.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("Tap + to add items for today!")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                    .padding(.horizontal)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var noSearchResultsView: some View {
        SearchEmptyStateView(searchText: searchText)
    }

    // MARK: - Computed Properties

    private var filteredItems: [TodayItem] {
        var items = viewModel.todayItems

        // Filter by completion status
        if !showCompletedItems {
            items = items.filter { !$0.isCompletedToday }
        }

        // Filter by search text
        if !searchText.isEmpty {
            items = items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText)
            }
        }

        return items
    }

    private var sortedItems: [TodayItem] {
        let items = filteredItems

        switch sortOption {
        case .title:
            return items.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .priority:
            return items.sorted { item1, item2 in
                if item1.priority == item2.priority {
                    return item1.title < item2.title
                }
                return item1.priority.sortOrder > item2.priority.sortOrder
            }
        case .creationDate:
            return items.sorted { item1, item2 in
                if item1.createdDate == item2.createdDate {
                    return item1.title < item2.title
                }
                return item1.createdDate > item2.createdDate // Newest first
            }
        case .dueDate:
            return items.sorted { item1, item2 in
                let date1 = item1.dueDate
                let date2 = item2.dueDate

                // Items with due dates come before items without
                switch (date1, date2) {
                case (nil, nil): return item1.title < item2.title
                case (nil, _): return false
                case (_, nil): return true
                case (let d1?, let d2?): return d1 < d2
                }
            }
        }
    }


    // MARK: - Today Items List

    @ViewBuilder
    private var todayItemsList: some View {
        List {
            ForEach(sortedItems) { item in
                todayRow(for: item)
            }
        }
        .listStyle(PlainListStyle())
    }

    @ViewBuilder
    private func todayRow(for item: TodayItem) -> some View {
                UnifiedTodayRow(
                    item: item,
                    onToggleCompletion: {
                        if !isMultiSelectMode {
                            handleToggleCompletion(for: item)
                        }
                    },
                    onEdit: {
                        if !isMultiSelectMode {
                            handleEdit(for: item)
                        }
                    },
                    onDelete: {
                        if !isMultiSelectMode {
                            handleDelete(for: item)
                        }
                    },
                    onSkip: item.asHabit != nil ? {
                        if !isMultiSelectMode {
                            handleSkip(for: item)
                        }
                    } : nil,
                    onReschedule: item.asTask != nil ? {
                        if !isMultiSelectMode {
                            handleReschedule(for: item)
                        }
                    } : nil
                )
                .rowStyling(
                    isSelected: isMultiSelectMode && selectedItems.contains(item.id),
                    accentColor: .daisyTask,
                    onTap: {
                        if isMultiSelectMode {
                            toggleItemSelection(item)
                        } else {
                            navigateToDetail(for: item)
                        }
                    }
                )
                .standardRowSwipeActions(
                    isMultiSelectMode: isMultiSelectMode,
                    accentColor: item.asTask != nil ? .daisyTask : .daisyHabit,
                    onDelete: {
                        handleDelete(for: item)
                    },
                    onEdit: {
                        handleEdit(for: item)
                    },
                    leadingAction: {
                        if let task = item.asTask {
                            DuplicateSwipeAction {
                                _ = taskManager.duplicateTaskSafely(task)
                            }
                        } else if item.asHabit != nil {
                            SkipSwipeAction {
                                handleSkip(for: item)
                            }
                        }
                    }
                )
    }

    // MARK: - Bulk Action Toolbar

    @ViewBuilder
    private var bulkActionToolbar: some View {
        BulkActionToolbar(selectedCount: selectedItems.count) {
            // Bulk completion toggle
            Button(action: {
                bulkToggleCompletion()
            }) {
                Label("Toggle Complete", systemImage: "checkmark.circle")
                    .labelStyle(.iconOnly)
                    .font(.title3)
            }
            .foregroundColor(.daisySuccess)

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

    // MARK: - Reschedule Sheet

    @ViewBuilder
    private func rescheduleSheet(for task: Task) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Reschedule Task")
                    .font(.headline)
                    .padding(.top, 20)

                DatePicker(
                    "New Due Date",
                    selection: $rescheduleDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)

                HStack(spacing: 16) {
                    Button("Cancel") {
                        showingRescheduleSheet = false
                        taskToReschedule = nil
                    }
                    .buttonStyle(.bordered)

                    Button("Reschedule") {
                        let result = taskManager.updateTask(
                            task,
                            dueDate: rescheduleDate
                        )

                        if case .success = result {
                            showingRescheduleSheet = false
                            taskToReschedule = nil
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Reschedule")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }

    // MARK: - Skip Reason Sheet

    @ViewBuilder
    private func skipReasonSheet(for habit: Habit) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Why are you skipping this habit?")
                    .font(.headline)
                    .padding(.top, 20)

                TextField("Reason (optional)", text: $skipReason, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .padding(.horizontal)

                HStack(spacing: 16) {
                    Button("Skip Without Reason") {
                        _ = habitManager.skipHabit(habit, reason: nil)
                        showingSkipReasonSheet = false
                        habitToSkip = nil
                        skipReason = ""
                    }
                    .buttonStyle(.bordered)

                    Button("Skip With Reason") {
                        let reason = skipReason.isEmpty ? nil : skipReason
                        _ = habitManager.skipHabit(habit, reason: reason)
                        showingSkipReasonSheet = false
                        habitToSkip = nil
                        skipReason = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(skipReason.isEmpty)
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Skip Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingSkipReasonSheet = false
                        habitToSkip = nil
                        skipReason = ""
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Helper Methods

    private func updateTodayItems() {
        viewModel.buildTodayItems(from: allTasks, habits: allHabits)
    }

    private func toggleItemSelection(_ item: TodayItem) {
        selectedItems.toggleMembership(item.id)
    }

    private func navigateToDetail(for item: TodayItem) {
        switch item {
        case .task(let task):
            taskToDetail = task
        case .habit(let habit):
            habitToDetail = habit
        }
    }

    private func handleToggleCompletion(for item: TodayItem) {
        switch item {
        case .task(let task):
            toggleTaskCompletion(task)
        case .habit(let habit):
            toggleHabitCompletion(habit)
        }
    }

    private func toggleTaskCompletion(_ task: Task) {
        _ = taskManager.toggleTaskCompletionSafely(task)

        if task.isCompleted {
            taskToastManager.showCompletionToast(for: task) {
                _ = taskManager.toggleTaskCompletionSafely(task)
            }
        }
    }

    private func toggleHabitCompletion(_ habit: Habit) {
        if habit.isCompletedToday {
            // Undo completion directly
            _ = habitManager.undoHabitCompletion(habit)
        } else {
            // Mark complete and show undo toast
            _ = habitManager.markHabitCompleted(habit)

            if habit.isCompletedToday {
                habitToastManager.showCompletionToast(for: habit) {
                    _ = habitManager.undoHabitCompletion(habit)
                }
            }
        }
    }

    private func handleEdit(for item: TodayItem) {
        switch item {
        case .task(let task):
            taskToEdit = task
        case .habit(let habit):
            habitToEdit = habit
        }
    }

    private func handleDelete(for item: TodayItem) {
        itemToDelete = item
        showingDeleteConfirmation = true
    }

    private func performDelete(for item: TodayItem) {
        switch item {
        case .task(let task):
            _ = taskManager.deleteTask(task)
        case .habit(let habit):
            _ = habitManager.deleteHabit(habit)
        }
    }

    private func handleReschedule(for item: TodayItem) {
        if let task = item.asTask {
            taskToReschedule = task
            rescheduleDate = task.dueDate ?? Date()
            showingRescheduleSheet = true
        }
    }

    private func handleSkip(for item: TodayItem) {
        if let habit = item.asHabit {
            habitToSkip = habit
            showingSkipReasonSheet = true
        }
    }

    private func bulkToggleCompletion() {
        let itemsToUpdate = sortedItems.filter { selectedItems.contains($0.id) }
        var completedTasks: [Task] = []
        var completedHabits: [Habit] = []

        for item in itemsToUpdate {
            switch item {
            case .task(let task):
                _ = taskManager.toggleTaskCompletionSafely(task)
                if task.isCompleted {
                    completedTasks.append(task)
                }
            case .habit(let habit):
                if !habit.isCompletedToday {
                    _ = habitManager.markHabitCompleted(habit)
                    if habit.isCompletedToday {
                        completedHabits.append(habit)
                    }
                }
            }
        }

        // Show toast for completed tasks if any
        if let lastTask = completedTasks.last {
            taskToastManager.showCompletionToast(for: lastTask) { [completedTasks] in
                // Undo all completed tasks
                for task in completedTasks {
                    _ = taskManager.toggleTaskCompletionSafely(task)
                }
            }
        }

        // Show toast for completed habits if any
        if let lastHabit = completedHabits.last {
            habitToastManager.showCompletionToast(for: lastHabit) { [completedHabits] in
                // Undo all completed habits
                for habit in completedHabits {
                    _ = habitManager.undoHabitCompletion(habit)
                }
            }
        }

        selectedItems.removeAll()
        isMultiSelectMode = false
    }

    private func bulkDelete() {
        let itemsToDelete = sortedItems.filter { selectedItems.contains($0.id) }

        for item in itemsToDelete {
            switch item {
            case .task(let task):
                _ = taskManager.deleteTask(task)
            case .habit(let habit):
                _ = habitManager.deleteHabit(habit)
            }
        }

        selectedItems.removeAll()
        isMultiSelectMode = false
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Task.self, Habit.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    TodayView()
        .modelContainer(container)
        .environment(TaskManager(modelContext: container.mainContext))
        .environment(HabitManager(modelContext: container.mainContext))
        .environment(TagManager(modelContext: container.mainContext))
        .environment(TaskCompletionToastManager())
        .environment(HabitCompletionToastManager())
        .environment(NavigationManager())
}
