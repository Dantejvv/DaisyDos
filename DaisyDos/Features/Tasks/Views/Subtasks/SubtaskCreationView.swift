//
//  SubtaskCreationView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI
import SwiftData

struct SubtaskCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskManager.self) private var taskManager

    let parentTask: Task

    @State private var title = ""
    @State private var taskDescriptionAttributed = AttributedString()
    @State private var priority: Priority = .none
    @State private var inheritDueDate = true
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var isFormValid: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let parentIsRootTask = parentTask.parentTask == nil
        return !trimmedTitle.isEmpty && parentIsRootTask
    }

    private var titleCountColor: Color {
        return DesignSystem.inputValidation.characterCountColorExact(
            currentCount: title.count,
            maxLength: DesignSystem.inputValidation.CharacterLimits.title
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                // Parent validation warning section
                if parentTask.parentTask != nil {
                    parentValidationWarningSection
                }

                // Subtask details section
                subtaskDetailsSection

                // Settings section
                settingsSection

                // Parent context section
                parentContextSection
            }
            .navigationTitle("New Subtask")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createSubtask()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Error Creating Subtask", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var parentValidationWarningSection: some View {
        Section {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.daisyError)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Cannot Add Subtask")
                        .font(.headline)
                        .foregroundColor(.daisyError)

                    Text("Only tasks can have subtasks. '\(parentTask.title)' is already a subtask and cannot have subtasks of its own.")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var subtaskDetailsSection: some View {
        Section("Subtask Details") {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Title", text: $title)
                    .accessibilityLabel("Subtask title")
                    .onChange(of: title) { _, newValue in
                        DesignSystem.inputValidation.enforceCharacterLimit(
                            &title,
                            newValue: newValue,
                            maxLength: DesignSystem.inputValidation.CharacterLimits.title
                        )
                    }

                HStack {
                    Spacer()
                    Text("\(title.count)/\(DesignSystem.inputValidation.CharacterLimits.title)")
                        .font(.caption2)
                        .foregroundColor(titleCountColor)
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("Description (optional)")
                    .font(.subheadline)
                    .foregroundColor(.daisyTextSecondary)
                    .padding(.bottom, Spacing.extraSmall)

                RichTextEditor(
                    attributedText: $taskDescriptionAttributed,
                    placeholder: "Add details, notes, or formatting...",
                    maxLength: DesignSystem.inputValidation.CharacterLimits.description
                )
            }
        }
    }

    @ViewBuilder
    private var settingsSection: some View {
        Section("Settings") {
            // Priority selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Priority")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.daisyText)

                priorityPicker
            }

            // Due date inheritance
            if parentTask.dueDate != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Inherit due date from parent", isOn: $inheritDueDate)

                    if inheritDueDate {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.daisyTextSecondary)
                            Text("Due \(parentTask.dueDate!, style: .date)")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                        }
                    } else {
                        customDueDatePicker
                    }
                }
            } else {
                customDueDatePicker
            }
        }
    }

    @ViewBuilder
    private var priorityPicker: some View {
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

    @ViewBuilder
    private var customDueDatePicker: some View {
        Toggle("Set custom due date", isOn: $hasDueDate)

        if hasDueDate {
            DatePicker("Due date", selection: Binding(
                get: { dueDate ?? Date() },
                set: { dueDate = $0 }
            ), displayedComponents: [.date])
        }
    }

    @ViewBuilder
    private var parentContextSection: some View {
        Section("Parent Task") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.up")
                        .foregroundColor(.daisyTextSecondary)
                    Text(parentTask.title)
                        .font(.body)
                        .foregroundColor(.daisyText)
                        .lineLimit(2)
                    Spacer()
                }

                // Parent subtask count
                if parentTask.hasSubtasks {
                    HStack {
                        Text("Current subtasks:")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)

                        Spacer()

                        Text("\(parentTask.subtaskCount)")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func setupInitialValues() {
        // Priority defaults to .none (no inheritance)
        priority = .none
        dueDate = parentTask.dueDate
    }

    private func createSubtask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            showError("Subtask title cannot be empty")
            return
        }

        // Validation for parent being a root task is handled in isFormValid and TaskManager
        guard parentTask.parentTask == nil else {
            showError("Only tasks can have subtasks. This task is already a subtask.")
            return
        }

        let finalDueDate: Date?

        if inheritDueDate && parentTask.dueDate != nil {
            finalDueDate = parentTask.dueDate
        } else if hasDueDate {
            finalDueDate = dueDate
        } else {
            finalDueDate = nil
        }

        // Extract plain text from attributed string for the model
        let descriptionText = AttributedString.extractText(from: taskDescriptionAttributed.toData() ?? Data())

        let result = taskManager.createSubtask(
            for: parentTask,
            title: trimmedTitle,
            taskDescription: descriptionText,
            priority: priority
        )

        switch result {
        case .success(let createdSubtask):
            // Set due date if specified
            if let finalDueDate = finalDueDate {
                _ = taskManager.updateTaskSafely(
                    createdSubtask,
                    dueDate: finalDueDate
                )
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

// MARK: - Quick Add Variant

struct QuickSubtaskAddView: View {
    let parentTask: Task
    let onSubtaskCreated: (Task) -> Void

    @Environment(TaskManager.self) private var taskManager
    @State private var title = ""
    @State private var isCreating = false

    var body: some View {
        HStack(spacing: 12) {
            TextField("Add a subtask...", text: $title)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    createQuickSubtask()
                }

            Button(action: createQuickSubtask) {
                if isCreating {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.daisyTask)
                }
            }
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func createQuickSubtask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        isCreating = true

        let result = taskManager.createSubtask(
            for: parentTask,
            title: trimmedTitle,
            priority: .none
        )

        switch result {
        case .success(let createdSubtask):
            onSubtaskCreated(createdSubtask)
            title = ""
        case .failure:
            // Handle error silently for quick add
            break
        }

        isCreating = false
    }
}

#Preview("Subtask Creation") {
    let container = try! ModelContainer(
        for: Task.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let taskManager = TaskManager(modelContext: container.mainContext)

    let parentTask = Task(
        title: "Build Mobile App",
        taskDescription: "Complete iOS application development",
        priority: .high,
        dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())
    )

    container.mainContext.insert(parentTask)

    return SubtaskCreationView(parentTask: parentTask)
        .modelContainer(container)
        .environment(taskManager)
}

#Preview("Quick Add") {
    let container = try! ModelContainer(
        for: Task.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let taskManager = TaskManager(modelContext: container.mainContext)

    let parentTask = Task(title: "Parent Task", priority: .medium)
    container.mainContext.insert(parentTask)

    return QuickSubtaskAddView(parentTask: parentTask) { subtask in
        print("Created subtask: \(subtask.title)")
    }
    .modelContainer(container)
    .environment(taskManager)
    .padding()
}