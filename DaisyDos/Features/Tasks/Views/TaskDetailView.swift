//
//  TaskDetailView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI
import SwiftData

struct TaskDetailView: View {
    @Environment(TaskManager.self) private var taskManager
    @Environment(\.dismiss) private var dismiss

    let task: Task

    @State private var showingEditView = false
    @State private var showingTagAssignment = false
    @State private var showingDeleteConfirmation = false
    @State private var showingShareSheet = false
    @State private var showingSubtaskManagement = false
    @State private var showingSubtaskCreation = false
    @State private var showingAttachmentPicker = false
    @State private var showingAttachmentDetail: TaskAttachment?
    @State private var showingTaskShare = false
    @State private var showingRecurrencePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Task Header
                    taskHeaderSection

                    // MARK: - Task Details
                    taskDetailsSection

                    // MARK: - Tags Section
                    if !task.tags.isEmpty {
                        tagsSection
                    }

                    // MARK: - Dates Section
                    if task.dueDate != nil || task.startDate != nil {
                        datesSection
                    }

                    // MARK: - Recurrence Section
                    if task.hasRecurrence {
                        RecurrenceVisualizationView(
                            recurrenceRule: task.recurrenceRule,
                            onEdit: {
                                showingRecurrencePicker = true
                            }
                        )
                    }

                    // MARK: - Subtasks Section
                    enhancedSubtasksSection

                    // MARK: - Attachments Section
                    enhancedAttachmentsSection

                    // MARK: - Metadata Section
                    metadataSection

                    Spacer(minLength: 100) // Space for floating action button
                }
                .padding()
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showingEditView = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(action: {
                            duplicateTask()
                        }) {
                            Label("Duplicate", systemImage: "plus.square.on.square")
                        }

                        Button(action: {
                            showingTagAssignment = true
                        }) {
                            Label("Manage Tags", systemImage: "tag")
                        }

                        Divider()

                        Button(action: {
                            showingTaskShare = true
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }

                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .foregroundColor(.daisyError)

                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                // Floating completion toggle
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
            .sheet(isPresented: $showingEditView) {
                TaskEditView(task: task)
            }
            .sheet(isPresented: $showingTagAssignment) {
                TagAssignmentSheet.forTask(task: task) { newTags in
                    updateTaskTags(newTags)
                }
            }
            .alert(
                "Delete Task",
                isPresented: $showingDeleteConfirmation
            ) {
                Button("Delete", role: .destructive) {
                    deleteTask()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete '\(task.title)'? This action cannot be undone.")
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var taskHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.title.bold())
                        .foregroundColor(task.isCompleted ? .daisyTextSecondary : .daisyText)
                        .strikethrough(task.isCompleted)

                    if task.priority != .medium {
                        HStack(spacing: 6) {
                            task.priority.indicatorView()
                                .font(.caption)
                            Text("\(task.priority.displayName) Priority")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.daisyTextSecondary)
                        }
                    }
                }

                Spacer()

                if task.isCompleted {
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.daisySuccess)
                        Text("Complete")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.daisySuccess)
                    }
                } else if task.hasOverdueStatus {
                    VStack(alignment: .trailing, spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundColor(.daisyError)
                        Text("Overdue")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.daisyError)
                    }
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Task Details Section

    @ViewBuilder
    private var taskDetailsSection: some View {
        if !task.taskDescription.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Description")
                        .font(.headline)
                    Spacer()
                }

                Text(task.taskDescription)
                    .font(.body)
                    .foregroundColor(.daisyText)
            }
            .padding()
            .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Tags Section

    @ViewBuilder
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tags")
                    .font(.headline)
                Spacer()
                Button("Manage") {
                    showingTagAssignment = true
                }
                .font(.caption)
                .foregroundColor(.daisyTask)
            }

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

    // MARK: - Dates Section

    @ViewBuilder
    private var datesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dates")
                .font(.headline)

            VStack(spacing: 8) {
                if let startDate = task.startDate {
                    HStack {
                        Label("Start Date", systemImage: "calendar.badge.plus")
                            .font(.subheadline)
                            .foregroundColor(.daisyTextSecondary)
                        Spacer()
                        Text(startDate.formatted(date: .complete, time: .omitted))
                            .font(.subheadline)
                    }
                }

                if let dueDate = task.dueDate {
                    HStack {
                        Label("Due Date", systemImage: "calendar.badge.clock")
                            .font(.subheadline)
                            .foregroundColor(task.hasOverdueStatus ? .daisyError : .daisyTextSecondary)
                        Spacer()
                        Text(dueDate.formatted(date: .complete, time: .omitted))
                            .font(.subheadline)
                            .foregroundColor(task.hasOverdueStatus ? .daisyError : .daisyText)
                    }
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Enhanced Subtasks Section

    @ViewBuilder
    private var enhancedSubtasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with actions
            HStack {
                Text("Subtasks")
                    .font(.headline)

                Spacer()

                if task.hasSubtasks {
                    Button(action: {
                        withAnimation(.spring(response: 0.4)) {
                            showingSubtaskManagement.toggle()
                        }
                    }) {
                        Text(showingSubtaskManagement ? "Collapse" : "Manage")
                            .font(.caption)
                            .foregroundColor(.daisyTask)
                    }
                }

                Button(action: {
                    showingSubtaskCreation = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.daisyTask)
                }
                .accessibilityLabel("Add subtask")
            }

            // Progress overview
            if task.hasSubtasks {
                SubtaskProgressSummary(task: task, style: .detailed)
            }

            // Subtask management or preview
            if showingSubtaskManagement || !task.hasSubtasks {
                SubtaskListView(parentTask: task, nestingLevel: 0)
            } else if task.hasSubtasks {
                // Compact preview of subtasks
                subtaskPreview
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $showingSubtaskCreation) {
            SubtaskCreationView(parentTask: task)
        }
        .sheet(isPresented: $showingAttachmentPicker) {
            AttachmentPickerSheet(task: task) { attachment in
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
                        startDate: task.startDate,
                        recurrenceRule: newRule
                    )
                }
            ))
        }
    }

    @ViewBuilder
    private var subtaskPreview: some View {
        VStack(spacing: 8) {
            ForEach(task.orderedSubtasks.prefix(3), id: \.id) { subtask in
                HStack {
                    Button(action: {
                        toggleSubtaskCompletion(subtask)
                    }) {
                        Image(systemName: subtask.isCompleted ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(subtask.isCompleted ? .daisySuccess : .daisyTextSecondary)
                    }
                    .buttonStyle(.plain)

                    Text(subtask.title)
                        .font(.subheadline)
                        .strikethrough(subtask.isCompleted)
                        .foregroundColor(subtask.isCompleted ? .daisyTextSecondary : .daisyText)
                        .lineLimit(1)

                    Spacer()

                    if subtask.hasSubtasks {
                        Text("\(subtask.completedSubtaskCount)/\(subtask.subtaskCount)")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showingSubtaskManagement = true
                }
            }

            if task.subtaskCount > 3 {
                Button(action: {
                    showingSubtaskManagement = true
                }) {
                    HStack {
                        Text("+ \(task.subtaskCount - 3) more subtasks")
                            .font(.caption)
                            .foregroundColor(.daisyTask)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.daisyTask)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Enhanced Attachments Section

    @ViewBuilder
    private var enhancedAttachmentsSection: some View {
        AttachmentGalleryView(
            task: task,
            onAttachmentTap: { attachment in
                showingAttachmentDetail = attachment
            },
            onAddAttachment: {
                showingAttachmentPicker = true
            },
            onShareAttachment: { attachment in
                shareAttachment(attachment)
            }
        )
    }

    // MARK: - Metadata Section

    @ViewBuilder
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)

            VStack(spacing: 8) {
                HStack {
                    Text("Created")
                        .font(.subheadline)
                        .foregroundColor(.daisyTextSecondary)
                    Spacer()
                    Text(task.createdDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                }

                HStack {
                    Text("Modified")
                        .font(.subheadline)
                        .foregroundColor(.daisyTextSecondary)
                    Spacer()
                    Text(task.modifiedDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                }

                if task.isCompleted, let completedDate = task.completedDate {
                    HStack {
                        Text("Completed")
                            .font(.subheadline)
                            .foregroundColor(.daisySuccess)
                        Spacer()
                        Text(completedDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.daisySuccess)
                    }
                }

                if task.hasRecurrence {
                    HStack {
                        Text("Recurring")
                            .font(.subheadline)
                            .foregroundColor(.daisyTextSecondary)
                        Spacer()
                        Image(systemName: "repeat")
                            .font(.subheadline)
                            .foregroundColor(.daisyTask)
                    }
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }


    // MARK: - Helper Methods

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

    private func toggleSubtaskCompletion(_ subtask: Task) {
        _ = taskManager.toggleSubtaskCompletionSafely(subtask)
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
        dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
        startDate: Date()
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