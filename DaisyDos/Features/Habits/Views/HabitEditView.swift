//
//  HabitEditView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//  Redesigned to match AddHabitView structure
//

import SwiftUI
import SwiftData
import QuickLook
#if canImport(PhotosUI)
import PhotosUI
#endif

struct HabitEditView: View {
    @Environment(HabitManager.self) private var habitManager
    @Environment(\.dismiss) private var dismiss

    let habit: Habit

    @State private var title: String
    @State private var habitDescriptionAttributed: AttributedString
    @State private var priority: Priority
    @State private var selectedTags: [Tag]
    @State private var showingTagSelection = false
    @State private var recurrenceRule: RecurrenceRule?
    @State private var showingRecurrencePicker = false
    @State private var showingPriorityPicker = false
    @State private var showingReminderPicker = false
    @State private var alertTimeHour: Int?
    @State private var alertTimeMinute: Int?
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
        var isCompletedToday: Bool
        var subtaskOrder: Int

        // SubtaskItemProtocol conformance
        var isCompleted: Bool {
            get { isCompletedToday }
            set { isCompletedToday = newValue }
        }

        init(id: UUID = UUID(), title: String, isCompletedToday: Bool = false, subtaskOrder: Int = 0) {
            self.id = id
            self.title = title
            self.isCompletedToday = isCompletedToday
            self.subtaskOrder = subtaskOrder
        }

        static func == (lhs: SubtaskItem, rhs: SubtaskItem) -> Bool {
            lhs.id == rhs.id && lhs.title == rhs.title && lhs.isCompletedToday == rhs.isCompletedToday && lhs.subtaskOrder == rhs.subtaskOrder
        }
    }

    // Attachment item for staging changes
    struct AttachmentItem: Identifiable, Equatable {
        let id: UUID
        let attachmentId: UUID? // ID of existing HabitAttachment, nil if new
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

    init(habit: Habit) {
        self.habit = habit
        self._title = State(initialValue: habit.title)
        self._habitDescriptionAttributed = State(initialValue: habit.habitDescriptionAttributed)
        self._priority = State(initialValue: habit.priority)
        self._selectedTags = State(initialValue: habit.tags ?? [])
        self._recurrenceRule = State(initialValue: habit.recurrenceRule)
        self._alertTimeHour = State(initialValue: habit.alertTimeHour)
        self._alertTimeMinute = State(initialValue: habit.alertTimeMinute)

        // Initialize staged attachments from existing habit attachments
        // Convert existing attachments to temporary URLs for staging
        self._stagedAttachments = State(initialValue: (habit.attachments ?? []).compactMap { attachment in
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

        // Initialize staged subtasks from existing habit subtasks
        self._stagedSubtasks = State(initialValue: habit.orderedSubtasks.map { subtask in
            SubtaskItem(
                id: subtask.id,
                title: subtask.title,
                isCompletedToday: subtask.isCompletedToday,
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
        let currentSubtaskItems = habit.orderedSubtasks.map { subtask in
            SubtaskItem(
                id: subtask.id,
                title: subtask.title,
                isCompletedToday: subtask.isCompletedToday,
                subtaskOrder: subtask.subtaskOrder
            )
        }
        let subtasksChanged = stagedSubtasks != currentSubtaskItems

        // Check if attachments have changed
        let currentAttachmentIds = Set((habit.attachments ?? []).map(\.id))
        let stagedAttachmentIds = Set(stagedAttachments.compactMap(\.attachmentId))
        let hasNewAttachments = stagedAttachments.contains { $0.attachmentId == nil && !$0.isMarkedForDeletion }
        let hasDeletedAttachments = stagedAttachments.contains { $0.isMarkedForDeletion }
        let attachmentsChanged = hasNewAttachments || hasDeletedAttachments || currentAttachmentIds != stagedAttachmentIds

        return trimmedTitle != habit.title ||
               habitDescriptionAttributed != habit.habitDescriptionAttributed ||
               priority != habit.priority ||
               recurrenceRule != habit.recurrenceRule ||
               alertTimeHour != habit.alertTimeHour ||
               alertTimeMinute != habit.alertTimeMinute ||
               Set(selectedTags.map(\.id)) != Set((habit.tags ?? []).map(\.id)) ||
               subtasksChanged ||
               attachmentsChanged
    }

    private var formattedAttachmentSize: String {
        let totalBytes = (habit.attachments ?? []).reduce(0) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
    }

    private var primaryFieldsSection: some View {
        VStack(spacing: Spacing.medium) {
            TitleFieldSection(
                title: $title,
                placeholder: "Habit title",
                showError: showTitleError
            )

            DescriptionFieldSection(
                attributedText: $habitDescriptionAttributed
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
                SubtaskAddButton(accentColor: .daisyHabit) {
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
                    SubtaskAddButton(accentColor: .daisyHabit) {
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
            config: .habit,
            recurrenceRule: recurrenceRule,
            alertTimeHour: alertTimeHour,
            alertTimeMinute: alertTimeMinute,
            priority: priority,
            accentColor: .daisyHabit,
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
            accentColor: .daisyHabit,
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
            accentColor: .daisyHabit,
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
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
            .sheet(isPresented: $showingTagSelection) {
                TagSelectionView(selectedTags: $selectedTags)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingPriorityPicker) {
                PriorityPickerSheet(
                    selectedPriority: $priority,
                    accentColor: .daisyHabit
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingRecurrencePicker) {
                RecurrenceRulePickerView(recurrenceRule: $recurrenceRule, allowsNone: false)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingReminderPicker) {
                HabitReminderPickerSheet(
                    alertTimeHour: $alertTimeHour,
                    alertTimeMinute: $alertTimeMinute,
                    accentColor: .daisyHabit
                )
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
                get: { habitManager.lastError },
                set: { habitManager.lastError = $0 }
            ))
            .onChange(of: recurrenceRule) { oldValue, newValue in
                // Handle recurrence removal: clear alert time if recurrence is removed
                if oldValue != nil && newValue == nil {
                    alertTimeHour = nil
                    alertTimeMinute = nil
                }
            }
        }
    }

    private func saveChanges() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            showError("Habit title cannot be empty")
            return
        }

        // Update habit properties directly
        habit.title = trimmedTitle
        habit.habitDescriptionAttributed = habitDescriptionAttributed
        habit.priority = priority
        habit.recurrenceRule = recurrenceRule
        habit.alertTimeHour = alertTimeHour
        habit.alertTimeMinute = alertTimeMinute
        habit.modifiedDate = Date()

        // Update tags
        updateHabitTags()

        // Update subtasks
        updateHabitSubtasks()

        // Update attachments
        updateHabitAttachments()

        // Explicit save to persist all direct property mutations
        try? habitManager.modelContext.save()

        // Notify to trigger notification scheduling for alert changes
        NotificationCenter.default.post(
            name: .habitDidChange,
            object: nil,
            userInfo: ["habitId": habit.id.uuidString]
        )

        dismiss()
    }

    private func updateHabitTags() {
        // Remove tags that are no longer selected
        for tag in (habit.tags ?? []) {
            if !selectedTags.contains(tag) {
                _ = habitManager.removeTag(tag, from: habit)
            }
        }

        // Add newly selected tags
        for tag in selectedTags {
            if !(habit.tags ?? []).contains(tag) {
                _ = habitManager.addTag(tag, to: habit)
            }
        }
    }

    private func updateHabitSubtasks() {
        // Create a map of existing subtasks by ID for quick lookup
        var existingSubtasks = Dictionary(uniqueKeysWithValues: (habit.subtasks ?? []).map { ($0.id, $0) })

        // Delete subtasks that are no longer in stagedSubtasks
        for subtask in (habit.subtasks ?? []) {
            if !stagedSubtasks.contains(where: { $0.id == subtask.id }) {
                _ = habitManager.deleteHabitSubtask(subtask, from: habit)
                existingSubtasks.removeValue(forKey: subtask.id)
            }
        }

        // Add or update subtasks
        for stagedSubtask in stagedSubtasks {
            if let existingSubtask = existingSubtasks[stagedSubtask.id] {
                // Update existing subtask
                existingSubtask.title = stagedSubtask.title
                existingSubtask.isCompletedToday = stagedSubtask.isCompletedToday
                existingSubtask.subtaskOrder = stagedSubtask.subtaskOrder
                existingSubtask.modifiedDate = Date()
            } else {
                // Create new subtask
                let result = habitManager.createHabitSubtask(for: habit, title: stagedSubtask.title)
                if case .success(let newSubtask) = result {
                    newSubtask.isCompletedToday = stagedSubtask.isCompletedToday
                    newSubtask.subtaskOrder = stagedSubtask.subtaskOrder
                }
            }
        }
    }

    private func updateHabitAttachments() {
        // Delete attachments that are marked for deletion
        for stagedAttachment in stagedAttachments where stagedAttachment.isMarkedForDeletion {
            if let attachmentId = stagedAttachment.attachmentId,
               let existingAttachment = (habit.attachments ?? []).first(where: { $0.id == attachmentId }) {
                _ = habitManager.deleteAttachment(existingAttachment, from: habit)
            }
        }

        // Add new attachments (those without an attachmentId)
        for stagedAttachment in stagedAttachments where !stagedAttachment.isMarkedForDeletion && stagedAttachment.attachmentId == nil {
            _ = habitManager.addAttachment(to: habit, from: stagedAttachment.fileURL)
        }
    }

    private func showError(_ message: String) {
        habitManager.lastError = DaisyDosError.validationFailed(message)
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
            .foregroundColor(.daisyTextSecondary)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                saveChanges()
            }
            .disabled(!isFormValid || !hasChanges)
            .fontWeight(.semibold)
            .foregroundColor(isFormValid && hasChanges ? .daisyHabit : .daisyTextSecondary)
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
            stagedSubtasks[index].isCompletedToday.toggle()
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

// MARK: - Supporting Views for Edit
// NOTE: HabitEditPhotoPickerView and HabitEditFilePickerView moved to Core/Design/Components/Shared/Pickers/
// Using shared StagedMultiPhotoPickerView and StagedMultiFilePickerView components

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Habit.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let habitManager = HabitManager(modelContext: container.mainContext)
    let tagManager = TagManager(modelContext: container.mainContext)

    // Create some sample tags
    let healthTag = tagManager.createTag(name: "Health", sfSymbolName: "heart", colorName: "red")!
    let fitnessTag = tagManager.createTag(name: "Fitness", sfSymbolName: "figure.run", colorName: "green")!

    let habit = Habit(
        title: "Morning Exercise",
        habitDescription: "30 minutes of cardio to start the day",
        recurrenceRule: .daily(),
        priority: .high
    )
    _ = habit.addTag(healthTag)
    _ = habit.addTag(fitnessTag)
    container.mainContext.insert(habit)

    return HabitEditView(habit: habit)
        .modelContainer(container)
        .environment(habitManager)
        .environment(tagManager)
}
