//
//  TaskDetailView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//  Refactored with vertical card layout on 11/8/25
//  Refactored with shared components on 11/11/25
//
//  FEATURE DIFFERENCES FROM HABITDETAILVIEW:
//  ════════════════════════════════════════════════════════════════════════════
//  1. DUE DATES: Tasks have due dates; habits focus on recurrence patterns
//     Rationale: Tasks are deadline-oriented work items; habits are continuous behaviors
//
//  2. LOGBOOK MODE: Tasks can be archived in logbook; habits track continuous history
//     Rationale: Completed tasks are archived after 90 days; habits maintain ongoing records
//
//  3. RECOVERY: Completed tasks can be recovered from logbook; habits don't need recovery
//     Rationale: Task archival is reversible; habit completions are permanent records
//
//  4. COMPLETION MODEL: Single completion state (done/not done); habits track multiple completions
//     Rationale: Tasks = discrete deliverables; habits = repeated behaviors with history
//
//  5. SKIP FUNCTIONALITY: Tasks don't have skip; habits allow skipping days with reasons
//     Rationale: Tasks are binary (done/pending); habits need flexibility for life circumstances
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

struct TaskDetailView: View {
    @Environment(TaskManager.self) private var taskManager
    @Environment(TaskCompletionToastManager.self) private var toastManager
    @Environment(\.dismiss) private var dismiss

    let task: Task
    let isLogbookMode: Bool

    // Query subtasks directly from database to work around SwiftData relationship observation issues
    @Query private var allSubtasks: [Task]

    @State private var showingEditView = false
    @State private var showingTagAssignment = false
    @State private var showingDeleteConfirmation = false
    @State private var showingRecurrencePicker = false
    @State private var showingRecoverConfirmation = false
    @State private var showingDatePicker = false
    @State private var showingReminderPicker = false
    @State private var showingPriorityPicker = false
    @State private var newSubtaskTitle = ""
    @State private var showSubtaskField = false
    @FocusState private var newSubtaskFocused: Bool
    @State private var attachmentToPreview: URL?

    // MARK: - Computed Properties

    private var canModify: Bool {
        !task.isCompleted || !isLogbookMode
    }

    // Get subtasks for this specific task from the query results
    private var taskSubtasks: [Task] {
        allSubtasks.filter { $0.parentTask?.id == task.id }
            .sorted { $0.subtaskOrder < $1.subtaskOrder }
    }

    // MARK: - Body

    var body: some View {
        // Note: No NavigationStack here - this view is pushed onto the existing
        // NavigationStack from ContentView via navigationDestination
        ScrollView {
            VStack(spacing: 20) {
                // Hero Card - Task Overview (title, description, priority)
                taskOverviewCard

                // Subtasks Section - Always shown
                subtasksCard

                // Metadata Card (dates, recurrence, alerts) - Always shown
                metadataCard

                // Tags Section - Always shown
                tagsCard

                // Attachments Section - Always shown
                attachmentsCard

                // Status & Progress Card
                statusAndProgressCard

                // History Card (created, modified, completion)
                historyCard
            }
            .padding()
        }
        .background(Color.daisyBackground)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    // Completion toggle at the top (hidden in logbook mode)
                    if !isLogbookMode {
                        Button {
                            _ = taskManager.toggleTaskCompletionSafely(task)

                            // Show undo toast if task was completed
                            if task.isCompleted {
                                toastManager.showCompletionToast(for: task) {
                                    _ = taskManager.toggleTaskCompletionSafely(task)
                                }
                            }
                        } label: {
                            if task.isCompleted {
                                Label("Mark as Incomplete", systemImage: "circle")
                            } else {
                                Label("Mark as Complete", systemImage: "checkmark.circle.fill")
                            }
                        }

                        Divider()
                    }

                    // Only show Edit if task can be modified
                    if canModify {
                        Button {
                            showingEditView = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Divider()
                    }

                    Button {
                        duplicateTask()
                    } label: {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }

                    // Add Recover option for completed tasks in logbook mode
                    if isLogbookMode && task.isCompleted {
                        Divider()

                        Button {
                            showingRecoverConfirmation = true
                        } label: {
                            Label("Recover Task", systemImage: "arrow.uturn.backward.circle")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            TaskEditView(task: task)
        }
        .sheet(isPresented: $showingTagAssignment) {
            TagSelectionView(selectedTags: .init(
                get: { task.tags ?? [] },
                set: { newTags in
                    updateTaskTags(newTags)
                }
            ))
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingRecurrencePicker) {
            RecurrenceRulePickerView(
                recurrenceRule: .init(
                    get: { task.recurrenceRule },
                    set: { newRule in
                        let _ = taskManager.updateTask(
                            task,
                            title: task.title,
                            taskDescription: task.taskDescription,
                            priority: task.priority,
                            dueDate: task.dueDate,
                            recurrenceRule: newRule
                        )
                    }
                ),
                allowsNone: true
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerSheet(
                selectedDate: .init(
                    get: { task.dueDate },
                    set: { newDate in
                        task.dueDate = newDate
                        task.modifiedDate = Date()
                        // Explicit save to persist due date change
                        try? taskManager.modelContext.save()
                    }
                ),
                hasDate: .constant(task.dueDate != nil),
                accentColor: .daisyTask
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showingReminderPicker) {
            ReminderPickerSheet(
                reminderDate: .init(
                    get: { task.reminderDate },
                    set: { newDate in
                        task.reminderDate = newDate
                        task.modifiedDate = Date()
                        // Explicit save to persist reminder change
                        try? taskManager.modelContext.save()
                        // Notify to trigger notification scheduling
                        NotificationCenter.default.post(
                            name: .taskDidChange,
                            object: nil,
                            userInfo: ["taskId": task.id.uuidString]
                        )
                    }
                ),
                accentColor: .daisyTask
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showingPriorityPicker) {
            PriorityPickerSheet(
                selectedPriority: .init(
                    get: { task.priority },
                    set: { newPriority in
                        let _ = taskManager.updateTask(
                            task,
                            title: task.title,
                            taskDescription: task.taskDescription,
                            priority: newPriority,
                            dueDate: task.dueDate,
                            recurrenceRule: task.recurrenceRule
                        )
                    }
                ),
                accentColor: .daisyTask
            )
            .presentationDetents([.medium])
        }
        .alert("Delete Task", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text("Are you sure you want to delete '\(task.title)'? This action cannot be undone.")
        }
        .alert("Recover Task", isPresented: $showingRecoverConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Recover") {
                recoverTask()
            }
        } message: {
            Text("This task will be moved back to your active tasks list and marked as incomplete.")
        }
        .quickLookPreview($attachmentToPreview)
        .errorAlert(error: Binding(
            get: { taskManager.lastError },
            set: { taskManager.lastError = $0 }
        ))
    }

    // MARK: - Hero Card - Task Overview

    @ViewBuilder
    private var taskOverviewCard: some View {
        OverviewCard(
            title: task.title,
            description: task.taskDescriptionAttributed
        )
    }

    // MARK: - Status & Progress Card

    @ViewBuilder
    private var statusAndProgressCard: some View {
        StatusProgressCard(
            hasSubtasks: task.hasSubtasks,
            completedSubtaskCount: task.completedSubtaskCount,
            totalSubtaskCount: task.subtaskCount,
            accentColor: .daisyTask
        ) {
            HStack(spacing: 20) {
                // Completion status
                VStack(alignment: .leading, spacing: 4) {
                    Text("Completion")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                    HStack(spacing: 6) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(task.isCompleted ? .daisySuccess : .daisyTextSecondary)
                        Text(task.isCompleted ? "Complete" : "Incomplete")
                            .font(.subheadline.weight(.medium))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 40)

                // Subtask progress
                SubtaskStatusSection(
                    hasSubtasks: task.hasSubtasks,
                    completedCount: task.completedSubtaskCount,
                    totalCount: task.subtaskCount,
                    accentColor: .daisyTask
                )
            }
        }
    }

    // MARK: - Tags Card

    @ViewBuilder
    private var tagsCard: some View {
        TagsCard(
            tags: task.tags ?? [],
            accentColor: .daisyTask,
            canModify: canModify,
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
                // Due Date - Always shown
                Button(action: {
                    if canModify {
                        showingDatePicker = true
                    }
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Due Date", systemImage: "calendar.badge.clock")
                                .font(.subheadline)
                                .foregroundColor(.daisyTextSecondary)
                            Spacer()
                            HStack(spacing: 4) {
                                if let dueDate = task.dueDate {
                                    Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(task.hasOverdueStatus ? .daisyError : .daisyText)
                                } else {
                                    Text("None")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.daisyTextSecondary)
                                }

                                if canModify {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.daisyTextSecondary)
                                }
                            }
                        }

                        if task.hasOverdueStatus {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.daisyError)
                                Text("This task is overdue")
                                    .font(.caption)
                                    .foregroundColor(.daisyError)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Colors.Accent.errorBackground, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .buttonStyle(.plain)

                Divider()

                // Recurrence - Always shown
                Button(action: {
                    if canModify {
                        showingRecurrencePicker = true
                    }
                }) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Recurrence", systemImage: "repeat")
                                .font(.subheadline)
                                .foregroundColor(.daisyTextSecondary)
                            Spacer()
                            HStack(spacing: 4) {
                                if task.recurrenceRule == nil {
                                    Text("None")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.daisyTextSecondary)
                                }
                                if canModify {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.daisyTextSecondary)
                                }
                            }
                        }

                        // Pattern description (only shown if recurrence exists)
                        if let recurrenceRule = task.recurrenceRule {
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
                                            .foregroundColor(.daisyTask)
                                    }
                                }
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                Divider()

                // Reminder - Always shown
                Button(action: {
                    if canModify {
                        showingReminderPicker = true
                    }
                }) {
                    HStack {
                        Label("Reminder", systemImage: "bell.fill")
                            .font(.subheadline)
                            .foregroundColor(.daisyTextSecondary)
                        Spacer()
                        HStack(spacing: 4) {
                            if let displayText = task.reminderDisplayText {
                                Text(displayText)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.daisyText)
                            } else {
                                Text("None")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.daisyTextSecondary)
                            }

                            if canModify {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.daisyTextSecondary)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)

                Divider()

                // Priority - Always shown
                Button(action: {
                    if canModify {
                        showingPriorityPicker = true
                    }
                }) {
                    HStack {
                        Label("Priority", systemImage: "flag.fill")
                            .font(.subheadline)
                            .foregroundColor(.daisyTextSecondary)
                        Spacer()
                        HStack(spacing: 4) {
                            if task.priority != .none {
                                task.priority.indicatorView()
                                    .font(.caption)
                                Text(task.priority.displayName)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.daisyText)
                            } else {
                                Text("None")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(.daisyTextSecondary)
                            }

                            if canModify {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.daisyTextSecondary)
                            }
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

            if taskSubtasks.isEmpty && !showSubtaskField {
                // Empty state - button to show field
                if canModify {
                    SubtaskAddButton {
                        showSubtaskField = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            newSubtaskFocused = true
                        }
                    }
                } else {
                    // Read-only empty state
                    HStack {
                        Text("None")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.daisyTextSecondary)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                }
            }

            // Subtasks list or field showing
            if !taskSubtasks.isEmpty || showSubtaskField {
                VStack(spacing: 0) {
                    // Existing subtasks list
                    if !taskSubtasks.isEmpty {
                        ScrollViewReader { proxy in
                            List {
                                ForEach(taskSubtasks) { subtask in
                                    SubtaskRow(
                                        subtask: subtask,
                                        accentColor: .daisyTask,
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
                            .frame(height: CGFloat(min(taskSubtasks.count, 6)) * 50)
                            .scrollDisabled(taskSubtasks.count <= 6)
                            .onChange(of: taskSubtasks.count) { oldValue, newValue in
                                if newValue > 6, let lastSubtask = taskSubtasks.last {
                                    withAnimation {
                                        proxy.scrollTo(lastSubtask.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }

                    // Add new subtask field
                    if showSubtaskField && canModify {
                        SubtaskInputField(
                            text: $newSubtaskTitle,
                            isFocused: $newSubtaskFocused,
                            onAdd: {
                                addSubtaskAndClose()
                            }
                        )
                    }

                    // Always-visible + button (when can modify)
                    if canModify {
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
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Attachments Card

    @ViewBuilder
    private var attachmentsCard: some View {
        AttachmentPreviewSection(
            attachments: task.attachments ?? [],
            accentColor: .daisyTask,
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
        HistoryCard(
            createdDate: task.createdDate,
            modifiedDate: task.modifiedDate,
            completionInfo: task.isCompleted && task.completedDate != nil
                ? .single(task.completedDate!)
                : nil
        )
    }

    // MARK: - Initializer

    init(task: Task, isLogbookMode: Bool = false) {
        self.task = task
        self.isLogbookMode = isLogbookMode
    }

    // MARK: - Helper Methods
    // Note: Formatting methods now use DetailViewHelpers for consistency

    private func formatReminderDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today at' h:mm a"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow at' h:mm a"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE 'at' h:mm a"
        } else {
            formatter.dateFormat = "MMM d 'at' h:mm a"
        }

        return formatter.string(from: date)
    }

    private func formatRelativeDate(_ date: Date) -> String {
        DetailViewHelpers.formatRelativeDate(date)
    }

    private func recoverTask() {
        let success = taskManager.recoverTaskSafely(task)
        if success {
            dismiss()  // Return to logbook after recovery
        }
    }

    private func updateTaskTags(_ newTags: [Tag]) {
        // Remove tags that are no longer selected
        for tag in (task.tags ?? []) {
            if !newTags.contains(tag) {
                _ = taskManager.removeTagSafely(tag, from: task)
            }
        }

        // Add newly selected tags
        for tag in newTags {
            if !(task.tags ?? []).contains(tag) {
                _ = taskManager.addTagSafely(tag, to: task)
            }
        }
    }

    private func duplicateTask() {
        _ = taskManager.duplicateTaskSafely(task)
    }

    private func deleteTask() {
        let success = taskManager.deleteTaskSafely(task)
        if success {
            dismiss()
        }
    }

    private func removeTag(_ tag: Tag) {
        _ = taskManager.removeTagSafely(tag, from: task)
    }

    private func toggleSubtask(_ subtask: Task) {
        if canModify {
            _ = taskManager.toggleSubtask(subtask)
        }
    }

    private func addSubtask() {
        let trimmedTitle = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let result = taskManager.createSubtask(
            for: task,
            title: trimmedTitle,
            priority: .none
        )

        if case .success = result {
            newSubtaskTitle = ""
        }
    }

    private func addSubtaskAndClose() {
        addSubtask()
        showSubtaskField = false
        newSubtaskFocused = false
    }
}

// MARK: - Task Detail Subtask Row
// TaskDetailSubtaskRow removed - now using shared SubtaskRow component from Core/Design/Components/Shared/Rows/


#Preview {
    let container = try! ModelContainer(
        for: Task.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let taskManager = TaskManager(modelContext: container.mainContext)
    let tagManager = TagManager(modelContext: container.mainContext)

    // Create sample tags
    let workTag = tagManager.createTag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")!
    let urgentTag = tagManager.createTag(name: "Urgent", sfSymbolName: "exclamationmark", colorName: "red")!

    // Create sample task with full features
    let task = Task(
        title: "Complete Quarterly Report",
        taskDescription: "Prepare the comprehensive quarterly report including all metrics, analysis, and recommendations for the executive team. This is a critical deliverable for the company.",
        priority: .high,
        dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
    )
    _ = task.addTag(workTag)
    _ = task.addTag(urgentTag)

    // Add subtasks
    let subtask1 = task.createSubtask(title: "Gather data from all departments")
    let subtask2 = task.createSubtask(title: "Analyze quarterly metrics")
    let subtask3 = task.createSubtask(title: "Create charts and visualizations")
    subtask1.setCompleted(true)

    container.mainContext.insert(task)
    container.mainContext.insert(subtask1)
    container.mainContext.insert(subtask2)
    container.mainContext.insert(subtask3)
    try! container.mainContext.save()

    return TaskDetailView(task: task)
        .modelContainer(container)
        .environment(taskManager)
        .environment(tagManager)
}

// MARK: - Wrapping HStack Layout

// NOTE: WrappingHStack moved to Core/Design/Components/Shared/Layout/WrappingHStack.swift
// Using shared component instead of private implementation
