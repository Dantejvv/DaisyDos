//
//  TaskDetailView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//  Refactored with tabbed interface on 10/1/25
//

import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(TaskManager.self) private var taskManager
    @Environment(\.dismiss) private var dismiss

    let task: Task
    let isLogbookMode: Bool

    @State private var selectedTab: DetailTab = .overview
    @State private var showingEditView = false
    @State private var showingTagAssignment = false
    @State private var showingDeleteConfirmation = false
    @State private var showingSubtaskCreation = false
    @State private var showingAttachmentPicker = false
    @State private var showingAttachmentDetail: TaskAttachment?
    @State private var showingTaskShare = false
    @State private var showingRecurrencePicker = false
    @State private var showingRecoverConfirmation = false

    // MARK: - Computed Properties

    private var canModify: Bool {
        !task.isCompleted || !isLogbookMode
    }

    // MARK: - Detail Tabs

    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case subtasks = "Subtasks"
        case attachments = "Attachments"

        var icon: String {
            switch self {
            case .overview: return "info.circle"
            case .subtasks: return "checklist"
            case .attachments: return "paperclip"
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

                    subtasksTab
                        .tag(DetailTab.subtasks)

                    attachmentsTab
                        .tag(DetailTab.attachments)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle(task.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
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

                        Button {
                            showingTaskShare = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
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
            .overlay(alignment: .bottomTrailing) {
                // Floating completion toggle (hidden in logbook mode)
                if !isLogbookMode {
                    Button(action: {
                        _ = taskManager.toggleTaskCompletionSafely(task)
                    }) {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 56))
                            .foregroundColor(task.isCompleted ? .daisySuccess : .daisyTask)
                            .background(
                                Circle()
                                    .fill(.regularMaterial)
                                    .shadow(radius: 8)
                            )
                    }
                    .padding()
                    .accessibilityLabel(task.isCompleted ? "Mark as incomplete" : "Mark as complete")
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            TaskEditView(task: task)
        }
        .sheet(isPresented: $showingTagAssignment) {
            TagAssignmentSheet.forTask(task: task) { newTags in
                updateTaskTags(newTags)
            }
        }
        .sheet(isPresented: $showingSubtaskCreation) {
            SubtaskCreationView(parentTask: task)
        }
        .sheet(isPresented: $showingAttachmentPicker) {
            AttachmentPickerSheet(task: task) { _ in
                // Refresh UI when attachment is added
            }
        }
        .sheet(item: $showingAttachmentDetail) { attachment in
            AttachmentDetailSheet(
                attachment: attachment,
                onDelete: {
                    deleteAttachment(attachment)
                    showingAttachmentDetail = nil
                },
                onShare: {
                    shareAttachment(attachment)
                }
            )
        }
        .sheet(isPresented: $showingTaskShare) {
            TaskShareSheet(task: task, includeAttachments: false)
        }
        .sheet(isPresented: $showingRecurrencePicker) {
            RecurrenceRulePickerView(recurrenceRule: .init(
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
            ))
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
                            .font(.system(size: 16, weight: .medium))

                        Text(tab.rawValue)
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(selectedTab == tab ? .daisyTask : .daisyTextSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .background(
                    Rectangle()
                        .fill(selectedTab == tab ? Color.daisyTask.opacity(0.1) : Color.clear)
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
                        .fill(Color.daisyTask)
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
                // Task Information Card
                taskInfoCard

                // Current Status Card
                currentStatusCard

                // Tags Section
                if !task.tags.isEmpty {
                    tagsCard
                }

                // Dates Card
                if task.dueDate != nil {
                    datesCard
                }

                // Recurrence Card
                if task.hasRecurrence {
                    recurrenceCard
                }
            }
            .padding()
        }
        .background(Color.daisyBackground)
    }

    @ViewBuilder
    private var taskInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("About")
                    .font(.headline)
                    .foregroundColor(.daisyText)
                Spacer()
                HStack(spacing: 6) {
                    task.priority.indicatorView()
                        .font(.caption)
                    Text(task.priority.displayName)
                        .font(.caption.weight(.medium))
                        .foregroundColor(.daisyTextSecondary)
                }
            }

            if !task.taskDescription.isEmpty {
                ScrollableDescriptionView(
                    text: task.taskDescriptionAttributed,
                    maxHeight: 200
                )
            }

            if let recurrenceRule = task.recurrenceRule {
                Label(
                    recurrenceRule.displayDescription,
                    systemImage: "repeat"
                )
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
            }

            // Metadata
            VStack(alignment: .leading, spacing: 4) {
                Label(
                    "Created \(task.createdDate.formatted(date: .abbreviated, time: .omitted))",
                    systemImage: "calendar"
                )
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)

                // Only show modified if different from created (more than 1 minute difference)
                if task.modifiedDate.timeIntervalSince(task.createdDate) > 60 {
                    Label(
                        "Modified \(task.modifiedDate.formatted(date: .abbreviated, time: .omitted))",
                        systemImage: "pencil.circle"
                    )
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var currentStatusCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Status")
                .font(.headline)

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

                Divider()
                    .frame(height: 40)

                // Subtask progress
                VStack(alignment: .leading, spacing: 4) {
                    Text("Subtasks")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                    if task.hasSubtasks {
                        HStack(spacing: 6) {
                            Image(systemName: "checklist")
                                .foregroundColor(.daisyTask)
                            Text("\(task.completedSubtaskCount)/\(task.subtaskCount)")
                                .font(.subheadline.weight(.medium))
                        }
                    } else {
                        Text("None")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.daisyTextSecondary)
                    }
                }

                if task.attachments.count > 0 {
                    Divider()
                        .frame(height: 40)

                    // Attachments count
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Attachments")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                        HStack(spacing: 6) {
                            Image(systemName: "paperclip")
                                .foregroundColor(.daisyTask)
                            Text("\(task.attachments.count)")
                                .font(.subheadline.weight(.medium))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var tagsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(.daisyText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(task.tags, id: \.id) { tag in
                        TagChipView(tag: tag)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var datesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Due Date")
                .font(.headline)

            VStack(spacing: 12) {
                if let dueDate = task.dueDate {
                    HStack {
                        Label("Due Date", systemImage: "calendar.badge.clock")
                            .font(.subheadline)
                            .foregroundColor(task.hasOverdueStatus ? .daisyError : .daisyTextSecondary)
                        Spacer()
                        Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(task.hasOverdueStatus ? .daisyError : .daisyText)
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
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var recurrenceCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recurrence")
                    .font(.headline)
                Spacer()
                Button("Edit") {
                    showingRecurrencePicker = true
                }
                .font(.caption)
                .foregroundColor(.daisyTask)
            }

            RecurrenceVisualizationView(
                recurrenceRule: task.recurrenceRule,
                onEdit: {
                    showingRecurrencePicker = true
                }
            )
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Subtasks Tab

    @ViewBuilder
    private var subtasksTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Progress Card
                if task.hasSubtasks {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Progress")
                            .font(.headline)

                        SubtaskProgressSummary(task: task, style: .detailed)
                    }
                    .padding()
                    .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
                }

                // Subtasks List
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("All Subtasks")
                            .font(.headline)
                        Spacer()
                        if canModify {
                            Button(action: {
                                showingSubtaskCreation = true
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.daisyTask)
                            }
                            .accessibilityLabel("Add subtask")
                        }
                    }

                    // Info banner when restricted
                    if !canModify && task.isCompleted {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.daisyTask)
                            Text("Completed tasks in Logbook cannot have new subtasks added")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.daisyTask.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }

                    if task.hasSubtasks {
                        SubtaskListView(parentTask: task, isReadOnly: isLogbookMode)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "checklist")
                                .font(.system(size: 48))
                                .foregroundColor(.daisyTextSecondary)

                            Text("No Subtasks Yet")
                                .font(.headline)
                                .foregroundColor(.daisyText)

                            if canModify {
                                Text("Break this task into smaller steps")
                                    .font(.subheadline)
                                    .foregroundColor(.daisyTextSecondary)
                                    .multilineTextAlignment(.center)

                                Button(action: {
                                    showingSubtaskCreation = true
                                }) {
                                    Label("Add Subtask", systemImage: "plus.circle.fill")
                                        .font(.subheadline.weight(.medium))
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.daisyTask)
                            } else {
                                Text("This completed task has no subtasks")
                                    .font(.subheadline)
                                    .foregroundColor(.daisyTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.vertical, 32)
                    }
                }
                .padding()
                .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
            }
            .padding()
        }
    }

    // MARK: - Attachments Tab

    @ViewBuilder
    private var attachmentsTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Info banner when restricted
                if !canModify && task.isCompleted {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.daisyTask)
                        Text("Completed tasks in Logbook cannot have new attachments added")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.daisyTask.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }

                // Storage Info Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Storage")
                        .font(.headline)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Size")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                            Text(task.totalAttachmentSize.formatted(.byteCount(style: .file)))
                                .font(.subheadline.weight(.medium))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Attachments")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                            Text("\(task.attachments.count)")
                                .font(.subheadline.weight(.medium))
                        }
                    }

                    // Progress bar for storage limit
                    let storagePercent = min(Double(task.totalAttachmentSize) / Double(200 * 1024 * 1024), 1.0)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.daisyBackground)
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(storagePercent > 0.8 ? Color.daisyError : Color.daisyTask)
                                .frame(width: geometry.size.width * storagePercent, height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        Text("\(Int(storagePercent * 100))% of 200MB limit")
                            .font(.caption2)
                            .foregroundColor(.daisyTextSecondary)
                        Spacer()
                    }
                }
                .padding()
                .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))

                // Attachments Gallery
                AttachmentGalleryView(
                    task: task,
                    onAttachmentTap: { attachment in
                        showingAttachmentDetail = attachment
                    },
                    onAddAttachment: canModify ? {
                        showingAttachmentPicker = true
                    } : nil,  // Disable add when !canModify
                    onShareAttachment: { attachment in
                        shareAttachment(attachment)
                    }
                )
            }
            .padding()
        }
    }

    // MARK: - Initializer

    init(task: Task, isLogbookMode: Bool = false) {
        self.task = task
        self.isLogbookMode = isLogbookMode
    }

    // MARK: - Helper Methods

    private func recoverTask() {
        let success = taskManager.recoverTaskSafely(task)
        if success {
            dismiss()  // Return to logbook after recovery
        }
    }

    private func updateTaskTags(_ newTags: [Tag]) {
        // Remove tags that are no longer selected
        for tag in task.tags {
            if !newTags.contains(tag) {
                _ = taskManager.removeTagSafely(tag, from: task)
            }
        }

        // Add newly selected tags
        for tag in newTags {
            if !task.tags.contains(tag) {
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

    private func deleteAttachment(_ attachment: TaskAttachment) {
        _ = taskManager.removeAttachmentSafely(attachment, from: task)
    }

    private func shareAttachment(_ attachment: TaskAttachment) {
        guard let fileURL = attachment.fullFilePath,
              FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        let activityVC = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = window
            activityVC.popoverPresentationController?.sourceRect = CGRect(
                x: window.bounds.midX,
                y: window.bounds.midY,
                width: 0,
                height: 0
            )
            rootVC.present(activityVC, animated: true)
        }
    }
}

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
