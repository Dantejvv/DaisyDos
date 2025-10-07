//
//  TaskEditView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI
import SwiftData

struct TaskEditView: View {
    @Environment(TaskManager.self) private var taskManager
    @Environment(\.dismiss) private var dismiss

    let task: Task

    @State private var title: String
    @State private var taskDescription: String
    @State private var priority: Priority
    @State private var dueDate: Date?
    @State private var hasDueDate: Bool
    @State private var startDate: Date?
    @State private var hasStartDate: Bool
    @State private var selectedTags: [Tag]
    @State private var showingTagSelection = false
    @State private var recurrenceRule: RecurrenceRule?
    @State private var showingRecurrencePicker = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingUnsavedChangesAlert = false

    init(task: Task) {
        self.task = task
        self._title = State(initialValue: task.title)
        self._taskDescription = State(initialValue: task.taskDescription)
        self._priority = State(initialValue: task.priority)
        self._dueDate = State(initialValue: task.dueDate)
        self._hasDueDate = State(initialValue: task.dueDate != nil)
        self._startDate = State(initialValue: task.startDate)
        self._hasStartDate = State(initialValue: task.startDate != nil)
        self._selectedTags = State(initialValue: task.tags)
        self._recurrenceRule = State(initialValue: task.recurrenceRule)
    }

    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasValidDates
    }

    var titleCharacterCount: Int {
        title.count
    }

    var descriptionCharacterCount: Int {
        taskDescription.count
    }

    private let maxTitleLength = DesignSystem.inputValidation.CharacterLimits.title
    private let maxDescriptionLength = DesignSystem.inputValidation.CharacterLimits.description

    private var showTitleError: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !title.isEmpty
    }

    private var titleCountColor: Color {
        return DesignSystem.inputValidation.characterCountColorExact(
            currentCount: titleCharacterCount,
            maxLength: maxTitleLength
        )
    }

    private var descriptionCountColor: Color {
        return DesignSystem.inputValidation.characterCountColorExact(
            currentCount: descriptionCharacterCount,
            maxLength: maxDescriptionLength
        )
    }

    var hasChanges: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmedTitle != task.title ||
               trimmedDescription != task.taskDescription ||
               priority != task.priority ||
               (hasDueDate ? dueDate : nil) != task.dueDate ||
               (hasStartDate ? startDate : nil) != task.startDate ||
               Set(selectedTags.map(\.id)) != Set(task.tags.map(\.id))
    }

    var hasValidDates: Bool {
        guard hasStartDate && hasDueDate,
              let start = startDate,
              let due = dueDate else {
            return true
        }
        return start <= due
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Title", text: $title)
                            .autocorrectionDisabled(true)
                            .accessibilityLabel("Task title")
                            .onChange(of: title) { _, newValue in
                                DesignSystem.inputValidation.enforceCharacterLimit(
                                    &title,
                                    newValue: newValue,
                                    maxLength: maxTitleLength
                                )
                            }

                        HStack {
                            if showTitleError {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.daisyError)
                                    Text("Title cannot be empty")
                                        .font(.caption)
                                        .foregroundColor(.daisyError)
                                }
                            }

                            Spacer()

                            Text("\(titleCharacterCount)/\(maxTitleLength)")
                                .font(.caption)
                                .foregroundColor(titleCountColor)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Description (optional)", text: $taskDescription, axis: .vertical)
                            .lineLimit(3...6)
                            .accessibilityLabel("Task description")
                            .onChange(of: taskDescription) { _, newValue in
                                DesignSystem.inputValidation.enforceCharacterLimit(
                                    &taskDescription,
                                    newValue: newValue,
                                    maxLength: maxDescriptionLength
                                )
                            }

                        HStack {
                            Spacer()
                            Text("\(descriptionCharacterCount)/\(maxDescriptionLength)")
                                .font(.caption)
                                .foregroundColor(descriptionCountColor)
                        }
                    }
                }

                Section("Priority") {
                    HStack(spacing: 0) {
                        ForEach(Priority.allCases, id: \.self) { priorityOption in
                            Button(action: {
                                priority = priorityOption
                            }) {
                                VStack(spacing: 4) {
                                    // Use fixed height for icon area to ensure consistent button sizes
                                    Group {
                                        if priorityOption.sfSymbol != nil {
                                            priorityOption.indicatorView()
                                                .font(.caption)
                                        } else {
                                            Color.clear
                                                .frame(width: 1, height: 1)
                                        }
                                    }
                                    .frame(height: 16) // Fixed height for icon area

                                    Text(priorityOption.rawValue)
                                        .font(.caption2)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(priority == priorityOption ? Color.daisyTask.opacity(0.2) : Color.clear)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.daisyTask, lineWidth: priority == priorityOption ? 2 : 0.5)
                                )
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(priority == priorityOption ? .daisyTask : .daisyText)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                Section("Dates") {
                    // Start Date
                    Toggle("Set start date", isOn: $hasStartDate)

                    if hasStartDate {
                        DatePicker("Start date", selection: Binding(
                            get: { startDate ?? Date() },
                            set: { startDate = $0 }
                        ), displayedComponents: [.date])
                    }

                    // Due Date
                    Toggle("Set due date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due date", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ), displayedComponents: [.date])
                    }

                    // Date validation warning
                    if !hasValidDates {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.daisyError)
                            Text("Start date must be before due date")
                                .font(.caption)
                                .foregroundColor(.daisyError)
                        }
                    }
                }

                Section("Tags") {
                    if selectedTags.isEmpty {
                        Button("Add Tags") {
                            showingTagSelection = true
                        }
                        .foregroundColor(.daisyTask)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedTags, id: \.id) { tag in
                                    TagChipView(
                                        tag: tag,
                                        isSelected: true,
                                        isRemovable: true,
                                        onRemove: {
                                            selectedTags.removeAll { $0.id == tag.id }
                                        }
                                    )
                                }

                                if selectedTags.count < 3 {
                                    Button(action: {
                                        showingTagSelection = true
                                    }) {
                                        Image(systemName: "plus.circle")
                                            .font(.title2)
                                            .foregroundColor(.daisyTask)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Add more tags")
                                }
                            }
                            .padding(.horizontal, 4)
                        }

                        if selectedTags.count == 3 {
                            Text("Maximum tags reached (3/3)")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                        }
                    }
                }

                Section("Recurrence") {
                    RecurrenceToggleRow(
                        recurrenceRule: $recurrenceRule,
                        showingPicker: $showingRecurrencePicker
                    )
                }
            }
            .navigationTitle("Edit Task")
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
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid || !hasValidDates || !hasChanges)
                }
            }
            .sheet(isPresented: $showingTagSelection) {
                NavigationStack {
                    TagSelectionView(selectedTags: $selectedTags)
                        .navigationTitle("Select Tags")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showingTagSelection = false
                                }
                            }
                        }
                }
            }
            .sheet(isPresented: $showingRecurrencePicker) {
                RecurrenceRulePickerView(recurrenceRule: $recurrenceRule)
            }
            .alert("Unsaved Changes", isPresented: $showingUnsavedChangesAlert) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Continue Editing", role: .cancel) { }
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .alert("Error Saving Task", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveChanges() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            showError("Task title cannot be empty")
            return
        }

        guard hasValidDates else {
            showError("Start date must be before due date")
            return
        }

        let result = taskManager.updateTask(
            task,
            title: trimmedTitle,
            taskDescription: trimmedDescription,
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            startDate: hasStartDate ? startDate : nil,
            recurrenceRule: recurrenceRule
        )

        switch result {
        case .success:
            // Update tags
            updateTaskTags()
            dismiss()
        case .failure(let error):
            showError(error.wrapped.userMessage)
        }
    }

    private func updateTaskTags() {
        // Remove tags that are no longer selected
        for tag in task.tags {
            if !selectedTags.contains(tag) {
                _ = taskManager.removeTagSafely(tag, from: task)
            }
        }

        // Add newly selected tags
        for tag in selectedTags {
            if !task.tags.contains(tag) {
                _ = taskManager.addTagSafely(tag, to: task)
            }
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
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
    _ = tagManager.createTag(name: "Personal", sfSymbolName: "house", colorName: "green")

    // Create sample task
    let task = Task(
        title: "Sample Task to Edit",
        taskDescription: "This is a sample task with description for editing demo",
        priority: .high,
        dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
        startDate: Date()
    )
    _ = task.addTag(workTag)
    container.mainContext.insert(task)
    try! container.mainContext.save()

    return TaskEditView(task: task)
        .modelContainer(container)
        .environment(taskManager)
        .environment(tagManager)
}