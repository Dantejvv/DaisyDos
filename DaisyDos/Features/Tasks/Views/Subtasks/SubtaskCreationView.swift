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
    @State private var taskDescription = ""
    @State private var priority: Priority = .none
    @State private var inheritFromParent = true
    @State private var inheritDueDate = true
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var showingError = false
    @State private var errorMessage = ""

    private var maxNestingDepth: Int { 10 }
    private var currentNestingLevel: Int { parentTask.nestingLevel + 1 }
    private var canCreateSubtask: Bool { currentNestingLevel < maxNestingDepth }

    var isFormValid: Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedTitle.isEmpty && canCreateSubtask
    }

    var body: some View {
        NavigationStack {
            Form {
                // Nesting warning section
                if !canCreateSubtask {
                    nestingWarningSection
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
    private var nestingWarningSection: some View {
        Section {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.daisyError)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Maximum Nesting Reached")
                        .font(.headline)
                        .foregroundColor(.daisyError)

                    Text("You've reached the maximum nesting depth of \(maxNestingDepth) levels. Consider reorganizing your task structure.")
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
                    .disabled(!canCreateSubtask)

                if !title.isEmpty && title.count > 50 {
                    Text("\(title.count)/100 characters")
                        .font(.caption)
                        .foregroundColor(title.count > 80 ? .daisyError : .daisyTextSecondary)
                }
            }

            TextField("Description (optional)", text: $taskDescription, axis: .vertical)
                .lineLimit(2...4)
                .accessibilityLabel("Subtask description")
                .disabled(!canCreateSubtask)
        }
    }

    @ViewBuilder
    private var settingsSection: some View {
        Section("Settings") {
            // Priority inheritance
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Inherit priority from parent", isOn: $inheritFromParent)
                    .disabled(!canCreateSubtask)

                if inheritFromParent {
                    HStack {
                        parentTask.priority.indicatorView()
                        Text("Will use \(parentTask.priority.displayName) priority")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }
                } else {
                    priorityPicker
                }
            }

            // Due date inheritance
            if parentTask.dueDate != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Inherit due date from parent", isOn: $inheritDueDate)
                        .disabled(!canCreateSubtask)

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
                .disabled(!canCreateSubtask)
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var customDueDatePicker: some View {
        Toggle("Set custom due date", isOn: $hasDueDate)
            .disabled(!canCreateSubtask)

        if hasDueDate {
            DatePicker("Due date", selection: Binding(
                get: { dueDate ?? Date() },
                set: { dueDate = $0 }
            ), displayedComponents: [.date])
            .disabled(!canCreateSubtask)
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

                // Nesting level indicator
                HStack {
                    Text("Nesting Level:")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)

                    Spacer()

                    HStack(spacing: 4) {
                        ForEach(0..<currentNestingLevel, id: \.self) { level in
                            Circle()
                                .fill(level < maxNestingDepth ? Color.daisyTask : Color.daisyError)
                                .frame(width: 8, height: 8)
                        }

                        Text("\(currentNestingLevel)/\(maxNestingDepth)")
                            .font(.caption)
                            .foregroundColor(currentNestingLevel < maxNestingDepth ? .daisyTextSecondary : .daisyError)
                    }
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
        priority = parentTask.priority
        dueDate = parentTask.dueDate
    }

    private func createSubtask() {
        guard canCreateSubtask else {
            showError("Cannot create subtask: maximum nesting depth reached")
            return
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            showError("Subtask title cannot be empty")
            return
        }

        let finalPriority = inheritFromParent ? parentTask.priority : priority
        let finalDueDate: Date?

        if inheritDueDate && parentTask.dueDate != nil {
            finalDueDate = parentTask.dueDate
        } else if hasDueDate {
            finalDueDate = dueDate
        } else {
            finalDueDate = nil
        }

        let result = taskManager.createSubtask(
            for: parentTask,
            title: trimmedTitle,
            taskDescription: trimmedDescription,
            priority: finalPriority
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
            priority: parentTask.priority
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