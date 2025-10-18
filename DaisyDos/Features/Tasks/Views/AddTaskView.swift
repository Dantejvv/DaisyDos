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
    @State private var taskDescriptionAttributed = AttributedString("")
    @State private var priority: Priority = .none
    @State private var dueDate: Date?
    @State private var hasDueDate = false
    @State private var selectedTags: [Tag] = []
    @State private var showingTagSelection = false
    @State private var recurrenceRule: RecurrenceRule?
    @State private var showingRecurrencePicker = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Task Details") {
                    ValidatedTitleField(
                        text: $title,
                        placeholder: "Task title"
                    )

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

                Section("Priority") {
                    PriorityPicker(
                        priority: $priority,
                        accentColor: .daisyTask
                    )
                }

                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due date", selection: Binding(
                            get: { dueDate ?? Date() },
                            set: { dueDate = $0 }
                        ), displayedComponents: [.date])
                    }
                }

                Section(
                    content: {
                        TagSelectionRow(
                            selectedTags: $selectedTags,
                            accentColor: .daisyTask,
                            onShowTagSelection: { showingTagSelection = true }
                        )
                    },
                    header: {
                        Text("Tags")
                    },
                    footer: {
                        Text("Organize with up to 3 tags for easy filtering and grouping.")
                    }
                )

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

        // Create task with plain title first
        let result = taskManager.createTask(
            title: trimmedTitle,
            taskDescription: "", // Placeholder for backward compatibility
            priority: priority,
            dueDate: hasDueDate ? dueDate : nil,
            recurrenceRule: recurrenceRule
        )

        switch result {
        case .success(let createdTask):
            // Set rich text description
            createdTask.taskDescriptionAttributed = taskDescriptionAttributed

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