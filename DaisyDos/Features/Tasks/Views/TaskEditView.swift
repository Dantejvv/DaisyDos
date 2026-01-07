//
//  TaskEditView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI
import SwiftData
import PhotosUI
import QuickLook

struct TaskEditView: View {
    @Environment(TaskManager.self) private var taskManager
    @Environment(\.dismiss) private var dismiss

    let task: Task

    @State private var title: String
    @State private var taskDescriptionAttributed: AttributedString
    @State private var priority: Priority
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool
    @State private var selectedTags: [Tag]
    @State private var showingTagSelection = false
    @State private var recurrenceRule: RecurrenceRule?
    @State private var showingRecurrencePicker = false
    @State private var showingDatePicker = false
    @State private var showingPriorityPicker = false
    @State private var showingReminderPicker = false
    @State private var reminderDate: Date?
    @State private var showingUnsavedChangesAlert = false
    @State private var showingAttachmentSourcePicker = false
    @State private var showingPhotoPicker = false
    @State private var showingFilePicker = false
    @State private var attachmentToPreview: URL?
    @State private var stagedAttachments: [AttachmentItem] = []
    @State private var newSubtaskTitle = ""
    @State private var showSubtaskField = false
    @FocusState private var newSubtaskFocused: Bool
    @State private var stagedSubtasks: [SubtaskItem] = []

    // Subtask item for staging changes
    struct SubtaskItem: Identifiable, Equatable, SubtaskItemProtocol {
        let id: UUID
        var title: String
        var isCompleted: Bool
        var subtaskOrder: Int

        init(id: UUID = UUID(), title: String, isCompleted: Bool = false, subtaskOrder: Int = 0) {
            self.id = id
            self.title = title
            self.isCompleted = isCompleted
            self.subtaskOrder = subtaskOrder
        }

        static func == (lhs: SubtaskItem, rhs: SubtaskItem) -> Bool {
            lhs.id == rhs.id && lhs.title == rhs.title && lhs.isCompleted == rhs.isCompleted && lhs.subtaskOrder == rhs.subtaskOrder
        }
    }

    // Attachment item for staging changes
    struct AttachmentItem: Identifiable, Equatable {
        let id: UUID
        let attachmentId: UUID? // ID of existing TaskAttachment, nil if new
        let fileURL: URL
        var isMarkedForDeletion: Bool

        init(id: UUID = UUID(), attachmentId: UUID? = nil, fileURL: URL, isMarkedForDeletion: Bool = false) {
            self.id = id
            self.attachmentId = attachmentId
            self.fileURL = fileURL
            self.isMarkedForDeletion = isMarkedForDeletion
        }

        static func == (lhs: AttachmentItem, rhs: AttachmentItem) -> Bool {
            lhs.id == rhs.id && lhs.attachmentId == rhs.attachmentId && lhs.fileURL == rhs.fileURL && lhs.isMarkedForDeletion == rhs.isMarkedForDeletion
        }
    }

    init(task: Task) {
        self.task = task
        self._title = State(initialValue: task.title)
        self._taskDescriptionAttributed = State(initialValue: task.taskDescriptionAttributed)
        self._priority = State(initialValue: task.priority)
        self._dueDate = State(initialValue: task.dueDate)
        self._hasDueDate = State(initialValue: task.dueDate != nil)
        self._selectedTags = State(initialValue: task.tags ?? [])
        self._recurrenceRule = State(initialValue: task.recurrenceRule)
        self._reminderDate = State(initialValue: task.reminderDate)

        // Initialize staged attachments from existing task attachments
        // Convert existing attachments to temporary URLs for staging
        self._stagedAttachments = State(initialValue: (task.attachments ?? []).compactMap { attachment in
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(attachment.id.uuidString)
                .appendingPathExtension(attachment.fileExtension)

            // Write the attachment data to temp URL for staging
            try? attachment.fileData.write(to: tempURL)

            return AttachmentItem(
                attachmentId: attachment.id,
                fileURL: tempURL,
                isMarkedForDeletion: false
            )
        })

        // Initialize staged subtasks from existing task subtasks
        self._stagedSubtasks = State(initialValue: task.orderedSubtasks.map { subtask in
            SubtaskItem(
                id: subtask.id,
                title: subtask.title,
                isCompleted: subtask.isCompleted,
                subtaskOrder: subtask.subtaskOrder
            )
        })
    }

    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var titleCharacterCount: Int {
        title.count
    }

    private let maxTitleLength = DesignSystem.inputValidation.CharacterLimits.title
    private let maxDescriptionLength = Int.max

    private var showTitleError: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !title.isEmpty
    }

    private var titleCountColor: Color {
        return DesignSystem.inputValidation.characterCountColorExact(
            currentCount: titleCharacterCount,
            maxLength: maxTitleLength
        )
    }

    var hasChanges: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if subtasks have changed
        let currentSubtaskItems = task.orderedSubtasks.map { subtask in
            SubtaskItem(
                id: subtask.id,
                title: subtask.title,
                isCompleted: subtask.isCompleted,
                subtaskOrder: subtask.subtaskOrder
            )
        }
        let subtasksChanged = stagedSubtasks != currentSubtaskItems

        // Check if attachments have changed
        let currentAttachmentIds = Set((task.attachments ?? []).map(\.id))
        let stagedAttachmentIds = Set(stagedAttachments.compactMap(\.attachmentId))
        let hasNewAttachments = stagedAttachments.contains { $0.attachmentId == nil && !$0.isMarkedForDeletion }
        let hasDeletedAttachments = stagedAttachments.contains { $0.isMarkedForDeletion }
        let attachmentsChanged = hasNewAttachments || hasDeletedAttachments || currentAttachmentIds != stagedAttachmentIds

        return trimmedTitle != task.title ||
               taskDescriptionAttributed != task.taskDescriptionAttributed ||
               priority != task.priority ||
               (hasDueDate ? dueDate : nil) != task.dueDate ||
               recurrenceRule != task.recurrenceRule ||
               reminderDate != task.reminderDate ||
               Set(selectedTags.map(\.id)) != Set((task.tags ?? []).map(\.id)) ||
               subtasksChanged ||
               attachmentsChanged
    }

    private var formattedDueDate: String {
        guard let date = dueDate else { return "Due Date" }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let hasTime = components.hour != 0 || components.minute != 0

        if hasTime {
            return date.formatted(date: .abbreviated, time: .shortened)
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }

    private var formattedAttachmentSize: String {
        let totalBytes = (task.attachments ?? []).reduce(0) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
    }

    private var primaryFieldsSection: some View {
        VStack(spacing: Spacing.medium) {
            TitleFieldSection(
                title: $title,
                placeholder: "Task title",
                showError: showTitleError
            )

            DescriptionFieldSection(
                attributedText: $taskDescriptionAttributed
            )
        }
        .padding(Spacing.medium)
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, Spacing.medium)
    }

    private var subtasksSection: some View {
        Group {
            if stagedSubtasks.isEmpty && !showSubtaskField {
                // Empty state - just the add button
                SubtaskAddButton {
                    showSubtaskField = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        newSubtaskFocused = true
                    }
                }
                .background(Color.daisySurface)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 16)
            } else if !stagedSubtasks.isEmpty || showSubtaskField {
                // Populated state - list with add field
                VStack(spacing: 0) {
                    // Existing subtasks in List for reordering
                    if !stagedSubtasks.isEmpty {
                        ScrollViewReader { proxy in
                            List {
                                ForEach(stagedSubtasks) { subtask in
                                    SubtaskRowStaging(
                                        subtask: subtask,
                                        onToggle: {
                                            toggleSubtask(subtask)
                                        }
                                    )
                                    .id(subtask.id)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                deleteSubtask(subtask)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                                .onMove { from, to in
                                    moveSubtasks(from: from, to: to)
                                }
                            }
                            .listStyle(.plain)
                            .frame(height: CGFloat(min(stagedSubtasks.count, 6)) * 50)
                            .scrollDisabled(stagedSubtasks.count <= 6)
                            .environment(\.editMode, .constant(.active))
                            .accentColor(.daisyTextSecondary)
                            .font(.caption2)
                            .onChange(of: stagedSubtasks.count) { oldValue, newValue in
                                if newValue > 6, let lastSubtask = stagedSubtasks.last {
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
                        if showSubtaskField && !newSubtaskTitle.isEmpty {
                            addSubtask()
                        }
                        if !showSubtaskField {
                            showSubtaskField = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            newSubtaskFocused = true
                        }
                    }
                }
                .background(Color.daisySurface)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 16)
            }
        }
    }

    private var toolbarSection: some View {
        MetadataToolbar(
            config: .task,
            dueDate: dueDate,
            recurrenceRule: recurrenceRule,
            reminderDate: reminderDate,
            priority: priority,
            accentColor: .daisyTask,
            onDateTap: { showingDatePicker = true },
            onRecurrenceTap: { showingRecurrencePicker = true },
            onReminderTap: { showingReminderPicker = true },
            onPriorityTap: { showingPriorityPicker = true }
        )
        .padding(.horizontal)
        .padding(.top, Spacing.medium)
    }

    private var attachmentsSection: some View {
        AttachmentsSectionURL(
            attachments: Binding(
                get: { stagedAttachments.filter { !$0.isMarkedForDeletion }.map { $0.fileURL } },
                set: { _ in }
            ),
            accentColor: .daisyTask,
            onAdd: {
                showingAttachmentSourcePicker = true
            },
            onDelete: { url in
                if let index = stagedAttachments.firstIndex(where: { $0.fileURL == url }) {
                    stagedAttachments[index].isMarkedForDeletion = true
                }
            },
            onTap: { url in
                attachmentToPreview = url
            }
        )
    }

    private var tagsSection: some View {
        TagsSection(
            selectedTags: $selectedTags,
            maxTags: 5,
            onAddTags: {
                showingTagSelection = true
            }
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.daisyBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        primaryFieldsSection
                        subtasksSection
                        toolbarSection
                        tagsSection
                        attachmentsSection
                        Spacer(minLength: Spacing.extraLarge)
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
            .sheet(isPresented: $showingTagSelection) {
                TagSelectionView(selectedTags: $selectedTags)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(
                    selectedDate: $dueDate,
                    hasDate: $hasDueDate,
                    accentColor: .daisyTask
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingPriorityPicker) {
                PriorityPickerSheet(
                    selectedPriority: $priority,
                    accentColor: .daisyTask
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingReminderPicker) {
                ReminderPickerSheet(
                    reminderDate: $reminderDate,
                    accentColor: .daisyTask
                )
                .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showingRecurrencePicker) {
                RecurrenceRulePickerView(recurrenceRule: $recurrenceRule)
                    .presentationDetents([.large])
            }
            .confirmationDialog("Add Attachment", isPresented: $showingAttachmentSourcePicker, titleVisibility: .visible) {
                #if canImport(PhotosUI)
                Button("Photo Library") {
                    showingPhotoPicker = true
                }
                #endif

                Button("Files") {
                    showingFilePicker = true
                }

                Button("Cancel", role: .cancel) {}
            }
            #if canImport(PhotosUI)
            .sheet(isPresented: $showingPhotoPicker) {
                StagedMultiPhotoPickerView(
                    stagedAttachments: $stagedAttachments,
                    createAttachment: { attachmentId, fileURL, isMarkedForDeletion in
                        AttachmentItem(attachmentId: attachmentId, fileURL: fileURL, isMarkedForDeletion: isMarkedForDeletion)
                    }
                )
            }
            #endif
            .sheet(isPresented: $showingFilePicker) {
                StagedMultiFilePickerView(
                    stagedAttachments: $stagedAttachments,
                    createAttachment: { attachmentId, fileURL, isMarkedForDeletion in
                        AttachmentItem(attachmentId: attachmentId, fileURL: fileURL, isMarkedForDeletion: isMarkedForDeletion)
                    }
                )
            }
            .quickLookPreview($attachmentToPreview)
            .alert("Unsaved Changes", isPresented: $showingUnsavedChangesAlert) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Continue Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .errorAlert(error: Binding(
                get: { taskManager.lastError },
                set: { taskManager.lastError = $0 }
            ))
        }
    }

    private func saveChanges() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            showError("Task title cannot be empty")
            return
        }

        // Update task properties directly
        task.title = trimmedTitle
        task.taskDescriptionAttributed = taskDescriptionAttributed
        task.priority = priority
        task.dueDate = hasDueDate ? dueDate : nil
        task.recurrenceRule = recurrenceRule
        task.reminderDate = reminderDate
        task.modifiedDate = Date()

        // Update tags
        updateTaskTags()

        // Update subtasks
        updateTaskSubtasks()

        // Update attachments
        updateTaskAttachments()

        dismiss()
    }

    private func updateTaskTags() {
        // Remove tags that are no longer selected
        for tag in (task.tags ?? []) {
            if !selectedTags.contains(tag) {
                _ = taskManager.removeTagSafely(tag, from: task)
            }
        }

        // Add newly selected tags
        for tag in selectedTags {
            if !(task.tags ?? []).contains(tag) {
                _ = taskManager.addTagSafely(tag, to: task)
            }
        }
    }

    private func updateTaskSubtasks() {
        // Create a map of existing subtasks by ID for quick lookup
        var existingSubtasks = Dictionary(uniqueKeysWithValues: (task.subtasks ?? []).map { ($0.id, $0) })

        // Delete subtasks that are no longer in stagedSubtasks
        for subtask in (task.subtasks ?? []) {
            if !stagedSubtasks.contains(where: { $0.id == subtask.id }) {
                _ = taskManager.deleteTaskSafely(subtask)
                existingSubtasks.removeValue(forKey: subtask.id)
            }
        }

        // Add or update subtasks
        for stagedSubtask in stagedSubtasks {
            if let existingSubtask = existingSubtasks[stagedSubtask.id] {
                // Update existing subtask
                existingSubtask.title = stagedSubtask.title
                existingSubtask.isCompleted = stagedSubtask.isCompleted
                existingSubtask.subtaskOrder = stagedSubtask.subtaskOrder
                existingSubtask.modifiedDate = Date()
            } else {
                // Create new subtask
                let result = taskManager.createSubtask(
                    for: task,
                    title: stagedSubtask.title,
                    priority: .none
                )
                if case .success(let newSubtask) = result {
                    newSubtask.isCompleted = stagedSubtask.isCompleted
                    newSubtask.subtaskOrder = stagedSubtask.subtaskOrder
                }
            }
        }
    }

    private func updateTaskAttachments() {
        // Delete attachments that are marked for deletion
        for stagedAttachment in stagedAttachments where stagedAttachment.isMarkedForDeletion {
            if let attachmentId = stagedAttachment.attachmentId,
               let existingAttachment = (task.attachments ?? []).first(where: { $0.id == attachmentId }) {
                _ = taskManager.deleteAttachment(existingAttachment, from: task)
            }
        }

        // Add new attachments (those without an attachmentId)
        for stagedAttachment in stagedAttachments where !stagedAttachment.isMarkedForDeletion && stagedAttachment.attachmentId == nil {
            _ = taskManager.addAttachment(to: task, from: stagedAttachment.fileURL)
        }
    }

    private func showError(_ message: String) {
        taskManager.lastError = DaisyDosError.validationFailed(message)
    }

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                if hasChanges {
                    showingUnsavedChangesAlert = true
                } else {
                    dismiss()
                }
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                saveChanges()
            }
            .disabled(!isFormValid || !hasChanges)
        }
    }

    // MARK: - Subtask Management

    private func addSubtask() {
        let trimmedTitle = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let maxOrder = stagedSubtasks.map(\.subtaskOrder).max() ?? -1
        let newSubtask = SubtaskItem(title: trimmedTitle, subtaskOrder: maxOrder + 1)
        stagedSubtasks.append(newSubtask)
        newSubtaskTitle = ""
        // Keep focus for quick entry
        newSubtaskFocused = true
    }

    private func addSubtaskAndClose() {
        let trimmedTitle = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let maxOrder = stagedSubtasks.map(\.subtaskOrder).max() ?? -1
        let newSubtask = SubtaskItem(title: trimmedTitle, subtaskOrder: maxOrder + 1)
        stagedSubtasks.append(newSubtask)
        newSubtaskTitle = ""
        // Close the field and remove focus
        showSubtaskField = false
        newSubtaskFocused = false
    }

    private func toggleSubtask(_ subtask: SubtaskItem) {
        if let index = stagedSubtasks.firstIndex(where: { $0.id == subtask.id }) {
            stagedSubtasks[index].isCompleted.toggle()
        }
    }

    private func deleteSubtask(_ subtask: SubtaskItem) {
        stagedSubtasks.removeAll { $0.id == subtask.id }
    }

    private func moveSubtasks(from source: IndexSet, to destination: Int) {
        stagedSubtasks.move(fromOffsets: source, toOffset: destination)

        // Update the subtaskOrder property for each subtask to match new positions
        for (index, subtask) in stagedSubtasks.enumerated() {
            stagedSubtasks[index].subtaskOrder = index
        }
    }
}

// MARK: - Compact Icon Button Component

// NOTE: CompactIconButton moved to Core/Design/Components/Shared/Buttons/CompactIconButton.swift
// Using shared component instead of private implementation

// MARK: - Wrapping HStack Layout

// NOTE: WrappingHStack moved to Core/Design/Components/Shared/Layout/WrappingHStack.swift
// Using shared component instead of private implementation

// MARK: - Attachment URL Preview

private struct AttachmentURLPreview: View {
    let fileURL: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            AttachmentURLPreviewController(fileURL: fileURL)
                .navigationTitle(fileURL.lastPathComponent)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

private struct AttachmentURLPreviewController: UIViewControllerRepresentable {
    let fileURL: URL

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(fileURL: fileURL)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let fileURL: URL

        init(fileURL: URL) {
            self.fileURL = fileURL
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            return fileURL as QLPreviewItem
        }
    }
}

// MARK: - Supporting Views for Edit
// NOTE: TaskEditPhotoPickerView and TaskEditFilePickerView moved to Core/Design/Components/Shared/Pickers/
// Using shared StagedMultiPhotoPickerView and StagedMultiFilePickerView components

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Task.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let taskManager = TaskManager(modelContext: container.mainContext)
    let tagManager = TagManager(modelContext: container.mainContext)

    // Create sample tags
    let workTag = tagManager.createTag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")!
    _ = tagManager.createTag(name: "Personal", sfSymbolName: "house", colorName: "green")

    // Create sample task
    let task = Task(
        title: "Sample Task to Edit",
        taskDescription: "This is a sample task with description for editing demo",
        priority: .high,
        dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())
    )
    _ = task.addTag(workTag)
    container.mainContext.insert(task)
    try! container.mainContext.save()

    return TaskEditView(task: task)
        .modelContainer(container)
        .environment(taskManager)
        .environment(tagManager)
}