//
//  AddTaskView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(TaskManager.self) private var taskManager
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var taskDescription = ""
    @State private var priority: Priority = .none
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var startDate: Date?
    @State private var hasStartDate = false
    @State private var selectedTags: [Tag] = []
    @State private var showingTagSelection = false
    @State private var recurrenceRule: RecurrenceRule?
    @State private var showingRecurrencePicker = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasValidDates
    }

    var hasValidDates: Bool {
        guard hasStartDate && hasDueDate,
              let start = startDate,
              let due = dueDate else {
            return true
        }
        return start <= due
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
                            .autocorrectionDisabled(true)
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

                Section(content: {
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
                }, header: {
                    Text("Tags")
                }, footer: {
                    Text("Organize with up to 3 tags for easy filtering and grouping.")
                })

                Section("Recurrence") {
                    RecurrenceToggleRow(
                        recurrenceRule: $recurrenceRule,
                        showingPicker: $showingRecurrencePicker
                    )
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTask()
                    }
                    .disabled(!isFormValid)
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
            .alert("Error Creating Task", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func createTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            showError("Task title cannot be empty")
            return
        }

        let result = taskManager.createTask(
            title: trimmedTitle,
            taskDescription: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            startDate: hasStartDate ? startDate : nil,
            recurrenceRule: recurrenceRule
        )

        switch result {
        case .success(let createdTask):
            // Add selected tags
            for tag in selectedTags {
                _ = taskManager.addTagSafely(tag, to: createdTask)
            }
            dismiss()
        case .failure(let error):
            showError(error.wrapped.userMessage)
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

    // Create some sample tags
    let _ = tagManager.createTag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")
    let _ = tagManager.createTag(name: "Personal", sfSymbolName: "house", colorName: "green")

    AddTaskView()
        .modelContainer(container)
        .environment(taskManager)
        .environment(tagManager)
}