//
//  AddTaskView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//  Redesigned with standardized components and progressive disclosure UX
//

import SwiftUI
import SwiftData
import PhotosUI
import QuickLook

struct AddTaskView: View {
    @Environment(TaskManager.self) private var taskManager
    @Environment(AppearanceManager.self) private var appearanceManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var taskDescriptionAttributed = AttributedString("")
    @State private var priority: Priority = .none
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool = false
    @State private var selectedTags: [Tag] = []
    @State private var showingTagSelection = false
    @State private var recurrenceRule: RecurrenceRule?
    @State private var showingRecurrencePicker = false
    @State private var showingDatePicker = false
    @State private var showingPriorityPicker = false
    @State private var showingAlertPicker = false
    @State private var selectedAlert: AlertOption?
    @State private var showingUnsavedChangesAlert = false
    @State private var subtasks: [SubtaskItem] = []
    @State private var newSubtaskTitle = ""
    @State private var showSubtaskField = false
    @FocusState private var newSubtaskFocused: Bool
    @FocusState private var titleFieldFocused: Bool

    // Attachments
    @State private var attachments: [URL] = []
    @State private var showingAttachmentSourcePicker = false
    @State private var showingPhotoPicker = false
    @State private var showingFilePicker = false
    @State private var attachmentToPreview: URL?

    // MARK: - Subtask Item Model

    struct SubtaskItem: Identifiable, Equatable, SubtaskItemProtocol {
        let id: UUID
        var title: String
        var isCompleted: Bool

        init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
            self.id = id
            self.title = title
            self.isCompleted = isCompleted
        }

        static func == (lhs: SubtaskItem, rhs: SubtaskItem) -> Bool {
            lhs.id == rhs.id
        }
    }

    // MARK: - Computed Properties

    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var titleCharacterCount: Int {
        title.count
    }

    private let maxTitleLength = DesignSystem.inputValidation.CharacterLimits.title

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
        let trimmedDescription = String(taskDescriptionAttributed.characters).trimmingCharacters(in: .whitespacesAndNewlines)

        return !trimmedTitle.isEmpty ||
               !trimmedDescription.isEmpty ||
               priority != .none ||
               hasDueDate ||
               !selectedTags.isEmpty ||
               recurrenceRule != nil ||
               selectedAlert != nil ||
               !subtasks.isEmpty ||
               !attachments.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - Primary Fields

                    primaryFieldsSection

                    // MARK: - Subtasks Section

                    subtasksSection

                    // MARK: - Metadata Toolbar

                    MetadataToolbar(
                        config: .task,
                        dueDate: dueDate,
                        recurrenceRule: recurrenceRule,
                        alert: selectedAlert,
                        priority: priority,
                        accentColor: .daisyTask,
                        onDateTap: { showingDatePicker = true },
                        onRecurrenceTap: { showingRecurrencePicker = true },
                        onAlertTap: { showingAlertPicker = true },
                        onPriorityTap: { showingPriorityPicker = true }
                    )
                    .padding(.horizontal)
                    .padding(.top, Spacing.medium)

                    // MARK: - Tags Section

                    TagsSection(
                        selectedTags: $selectedTags,
                        maxTags: 5,
                        onAddTags: {
                            showingTagSelection = true
                        }
                    )

                    // MARK: - Attachments Section

                    AttachmentsSectionURL(
                        attachments: $attachments,
                        accentColor: .daisyTask,
                        onAdd: {
                            showingAttachmentSourcePicker = true
                        },
                        onDelete: { url in
                            attachments.removeAll { $0 == url }
                        },
                        onTap: { url in
                            attachmentToPreview = url
                        }
                    )

                    Spacer(minLength: 40)
                }
            }
            .background(Color.daisyBackground)
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
                    Button("Create") {
                        createTask()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? .daisyTask : .daisyTextSecondary)
                }
            }
            // MARK: - Sheets
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
            .sheet(isPresented: $showingRecurrencePicker) {
                RecurrenceRulePickerView(
                    recurrenceRule: $recurrenceRule
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingAlertPicker) {
                AlertPickerSheet(
                    selectedAlert: $selectedAlert,
                    accentColor: .daisyTask
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingPriorityPicker) {
                PriorityPickerSheet(
                    selectedPriority: $priority,
                    accentColor: .daisyTask
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
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
                MultiPhotoPickerView(selectedURLs: $attachments)
            }
            #endif
            .sheet(isPresented: $showingFilePicker) {
                MultiFilePickerView(selectedURLs: $attachments)
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
            .tint(appearanceManager.currentAccentColor)
        }
    }

    // MARK: - View Components

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
            if subtasks.isEmpty && !showSubtaskField {
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
            } else if !subtasks.isEmpty || showSubtaskField {
                // Populated state - list with add field
                VStack(spacing: 0) {
                    // Existing subtasks in List for reordering
                    if !subtasks.isEmpty {
                        List {
                            ForEach(subtasks) { subtask in
                                SubtaskRowStaging(
                                    subtask: subtask,
                                    onToggle: {
                                        if let index = subtasks.firstIndex(where: { $0.id == subtask.id }) {
                                            subtasks[index].isCompleted.toggle()
                                        }
                                    }
                                )
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            subtasks.removeAll { $0.id == subtask.id }
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                            .onMove { from, to in
                                subtasks.move(fromOffsets: from, toOffset: to)
                            }
                        }
                        .listStyle(.plain)
                        .frame(height: CGFloat(subtasks.count) * 44)
                        .scrollDisabled(true)
                        .environment(\.editMode, .constant(.active))
                        .accentColor(.daisyTextSecondary)
                        .font(.caption2)
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

    // MARK: - Actions

    private func addSubtask() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        subtasks.append(SubtaskItem(title: trimmed))
        newSubtaskTitle = ""
        // Keep focus for quick entry
        newSubtaskFocused = true
    }

    private func addSubtaskAndClose() {
        let trimmed = newSubtaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        subtasks.append(SubtaskItem(title: trimmed))
        newSubtaskTitle = ""
        // Close the field and remove focus
        showSubtaskField = false
        newSubtaskFocused = false
    }

    private func createTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        // Convert AttributedString to String for task description
        let taskDescriptionString = String(taskDescriptionAttributed.characters)

        // Create task
        let result = taskManager.createTask(
            title: trimmedTitle,
            taskDescription: taskDescriptionString,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            recurrenceRule: recurrenceRule
        )

        switch result {
        case .success(let task):
            // Add tags
            for tag in selectedTags {
                if !(task.tags ?? []).contains(tag) {
                    if task.tags == nil { task.tags = [] }
                    task.tags!.append(tag)
                }
            }

            // Add alert if set
            if let alertInterval = selectedAlert?.timeInterval {
                task.alertTimeInterval = alertInterval
            }

            // Add subtasks
            for (index, subtaskItem) in subtasks.enumerated() {
                if case .success(let subtask) = taskManager.createSubtask(
                    for: task,
                    title: subtaskItem.title
                ) {
                    subtask.subtaskOrder = index
                }
            }

            // Add attachments
            for fileURL in attachments {
                _ = taskManager.addAttachment(to: task, from: fileURL)
            }

            dismiss()

        case .failure(let error):
            taskManager.lastError = error
        }
    }
}

// MARK: - Supporting Views
// NOTE: PhotoPickerView and FilePickerView moved to Core/Design/Components/Shared/Pickers/
// Using shared MultiPhotoPickerView and MultiFilePickerView components

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Task.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let taskManager = TaskManager(modelContext: container.mainContext)

    return AddTaskView()
        .environment(taskManager)
}
