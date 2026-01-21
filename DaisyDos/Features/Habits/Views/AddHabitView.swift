//
//  AddHabitView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//  Redesigned with standardized components and progressive disclosure UX
//

import SwiftUI
import SwiftData
import QuickLook
#if canImport(PhotosUI)
import PhotosUI
#endif

struct AddHabitView: View {
    @Environment(HabitManager.self) private var habitManager
    @Environment(AppearanceManager.self) private var appearanceManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("habitSortOption") private var habitSortOption: String = "Creation Date"

    @State private var title = ""
    @State private var habitDescriptionAttributed = AttributedString("")
    @State private var priority: Priority = .none
    @State private var selectedTags: [Tag] = []
    @State private var showingTagSelection = false
    @State private var recurrenceRule: RecurrenceRule? = .daily()
    @State private var showingRecurrencePicker = false
    @State private var showingReminderPicker = false
    @State private var showingScheduledTimePicker = false
    @State private var reminderDate: Date?
    @State private var reminderOffset: TimeInterval?
    @State private var scheduledTimeHour: Int?
    @State private var scheduledTimeMinute: Int?
    @State private var showingPriorityPicker = false
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
        let trimmedDescription = String(habitDescriptionAttributed.characters).trimmingCharacters(in: .whitespacesAndNewlines)

        return !trimmedTitle.isEmpty ||
               !trimmedDescription.isEmpty ||
               priority != .none ||
               !selectedTags.isEmpty ||
               recurrenceRule != nil ||
               reminderDate != nil ||
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

                    VStack(spacing: Spacing.small) {
                        MetadataToolbar(
                            config: .habit,
                            recurrenceRule: recurrenceRule,
                            reminderDate: reminderDate,
                            reminderOffset: reminderOffset,
                            priority: priority,
                            accentColor: .daisyHabit,
                            onRecurrenceTap: { showingRecurrencePicker = true },
                            onReminderTap: { showingReminderPicker = true },
                            onPriorityTap: { showingPriorityPicker = true }
                        )

                        // Scheduled time picker (only shown when recurrence is set)
                        if recurrenceRule != nil {
                            scheduledTimeRow
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, Spacing.medium)

                    // MARK: - Tags Section

                    TagsSection(
                        selectedTags: $selectedTags,
                        maxTags: 5,
                        accentColor: .daisyHabit,
                        onAddTags: {
                            showingTagSelection = true
                        }
                    )

                    // MARK: - Attachments Section

                    AttachmentsSectionURL(
                        attachments: $attachments,
                        accentColor: .daisyHabit,
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
            .navigationTitle("New Habit")
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
                        createHabit()
                    }
                    .disabled(!isFormValid)
                    .fontWeight(.semibold)
                    .foregroundColor(isFormValid ? .daisyHabit : .daisyTextSecondary)
                }
            }
            // MARK: - Sheets
            .sheet(isPresented: $showingTagSelection) {
                TagSelectionView(selectedTags: $selectedTags)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingRecurrencePicker) {
                RecurrenceRulePickerView(
                    recurrenceRule: $recurrenceRule
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingReminderPicker) {
                ReminderPickerSheet(
                    reminderDate: $reminderDate,
                    reminderOffset: $reminderOffset,
                    hasRecurrence: recurrenceRule != nil,
                    accentColor: .daisyHabit
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingScheduledTimePicker) {
                ScheduledTimePickerSheet(
                    scheduledTimeHour: $scheduledTimeHour,
                    scheduledTimeMinute: $scheduledTimeMinute,
                    accentColor: .daisyHabit
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingPriorityPicker) {
                PriorityPickerSheet(
                    selectedPriority: $priority,
                    accentColor: .daisyHabit
                )
                .presentationDetents([.medium])
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
                get: { habitManager.lastError },
                set: { habitManager.lastError = $0 }
            ))
            .onChange(of: recurrenceRule) { oldValue, newValue in
                // Handle recurrence changes: clear the inappropriate reminder type
                let hadRecurrence = oldValue != nil
                let hasRecurrence = newValue != nil

                if hadRecurrence && !hasRecurrence {
                    // Recurrence was removed: clear relative reminders
                    reminderOffset = nil
                    scheduledTimeHour = nil
                    scheduledTimeMinute = nil
                } else if !hadRecurrence && hasRecurrence {
                    // Recurrence was added: clear absolute reminder
                    reminderDate = nil
                }
            }
            .tint(appearanceManager.currentAccentColor)
        }
    }

    // MARK: - View Components

    /// Row for setting scheduled time (shown for recurring habits)
    private var scheduledTimeRow: some View {
        Button(action: {
            showingScheduledTimePicker = true
        }) {
            HStack(spacing: Spacing.small) {
                Image(systemName: "clock")
                    .font(.body)
                    .foregroundColor(scheduledTimeHour != nil ? .daisyHabit : .daisyTextSecondary)

                Text(scheduledTimeDisplayText)
                    .font(.subheadline)
                    .foregroundColor(scheduledTimeHour != nil ? .daisyText : .daisyTextSecondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
            }
            .padding()
            .background(Color.daisySurface)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    /// Display text for scheduled time
    private var scheduledTimeDisplayText: String {
        guard let hour = scheduledTimeHour, let minute = scheduledTimeMinute else {
            return "Set Scheduled Time"
        }

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        guard let date = Calendar.current.date(from: components) else {
            return "Set Scheduled Time"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "Scheduled at \(formatter.string(from: date))"
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
            if subtasks.isEmpty && !showSubtaskField {
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
            } else if !subtasks.isEmpty || showSubtaskField {
                // Populated state - list with add field
                VStack(spacing: 0) {
                    // Existing subtasks in List for reordering
                    if !subtasks.isEmpty {
                        ScrollViewReader { proxy in
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
                                    .id(subtask.id)
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
                            .frame(height: CGFloat(min(subtasks.count, 6)) * 50)
                            .scrollDisabled(subtasks.count <= 6)
                            .environment(\.editMode, .constant(.active))
                            .accentColor(.daisyTextSecondary)
                            .font(.caption2)
                            .onChange(of: subtasks.count) { oldValue, newValue in
                                if newValue > 6, let lastSubtask = subtasks.last {
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

    private func createHabit() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        // Convert AttributedString to String for habit description
        let habitDescriptionString = String(habitDescriptionAttributed.characters)

        // Create habit with custom sort state
        let isCustomSortActive = habitSortOption == "Custom"
        let result = habitManager.createHabit(
            title: trimmedTitle,
            habitDescription: habitDescriptionString,
            isCustomSortActive: isCustomSortActive
        )

        switch result {
        case .success(let habit):
            // Set priority
            habit.priority = priority

            // Set recurrence rule if provided
            if let rule = recurrenceRule {
                habit.recurrenceRule = rule
            }

            // Set reminder if provided
            // For recurring habits, use reminderOffset and scheduledTime; for non-recurring, use reminderDate
            habit.reminderDate = reminderDate
            habit.reminderOffset = reminderOffset
            habit.scheduledTimeHour = scheduledTimeHour
            habit.scheduledTimeMinute = scheduledTimeMinute

            // Notify to trigger notification scheduling if reminder was set
            if reminderDate != nil || reminderOffset != nil {
                NotificationCenter.default.post(
                    name: .habitDidChange,
                    object: nil,
                    userInfo: ["habitId": habit.id.uuidString]
                )
            }

            // Add tags
            for tag in selectedTags {
                if !(habit.tags ?? []).contains(tag) {
                    if habit.tags == nil { habit.tags = [] }
                    habit.tags!.append(tag)
                }
            }

            // Add subtasks using batch method (follows SwiftData best practices)
            if !subtasks.isEmpty {
                let subtaskTitles = subtasks.enumerated().map { (index, item) in
                    (title: item.title, order: index)
                }
                _ = habitManager.createHabitSubtasks(for: habit, titles: subtaskTitles)
            }

            // Add attachments
            for fileURL in attachments {
                _ = habitManager.addAttachment(to: habit, from: fileURL)
            }

            dismiss()

        case .failure(let error):
            habitManager.lastError = error
        }
    }
}

// MARK: - Supporting Views
// NOTE: PhotoPickerView and FilePickerView moved to Core/Design/Components/Shared/Pickers/
// Using shared MultiPhotoPickerView and MultiFilePickerView components

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Habit.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let habitManager = HabitManager(modelContext: container.mainContext)
    let tagManager = TagManager(modelContext: container.mainContext)

    // Create some sample tags
    let _ = tagManager.createTag(name: "Health", sfSymbolName: "heart", colorName: "red")
    let _ = tagManager.createTag(name: "Fitness", sfSymbolName: "figure.run", colorName: "green")

    return AddHabitView()
        .modelContainer(container)
        .environment(habitManager)
        .environment(tagManager)
}
