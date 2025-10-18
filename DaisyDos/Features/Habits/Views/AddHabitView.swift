//
//  AddHabitView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI
import SwiftData

struct AddHabitView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(HabitManager.self) private var habitManager
    @Environment(TagManager.self) private var tagManager

    // MARK: - State Properties

    @State private var habitTitle = ""
    @State private var habitDescriptionAttributed = AttributedString("")
    @State private var recurrenceRule: RecurrenceRule?
    @State private var selectedTags: [Tag] = []
    @State private var selectedPriority: Priority = .none

    // UI State
    @State private var showingRecurrencePicker = false
    @State private var showingTagAssignment = false
    @State private var validationErrors: Set<ValidationError> = []

    // MARK: - Validation

    enum ValidationError: CaseIterable {
        case emptyTitle
        case titleTooLong
        case descriptionTooLong
        case tooManyTags

        var message: String {
            switch self {
            case .emptyTitle:
                return "Habit title is required"
            case .titleTooLong:
                return "Habit title must be \(DesignSystem.inputValidation.CharacterLimits.title) characters or less"
            case .descriptionTooLong:
                return "Description must be \(DesignSystem.inputValidation.CharacterLimits.description) characters or less"
            case .tooManyTags:
                return "Maximum 3 tags allowed"
            }
        }

        var severity: ValidationSeverity {
            switch self {
            case .emptyTitle:
                return .error
            case .titleTooLong, .descriptionTooLong:
                return .warning
            case .tooManyTags:
                return .error
            }
        }
    }

    enum ValidationSeverity {
        case error, warning

        var color: Color {
            switch self {
            case .error: return .daisyError
            case .warning: return .orange
            }
        }

        var icon: String {
            switch self {
            case .error: return "exclamationmark.triangle.fill"
            case .warning: return "exclamationmark.circle.fill"
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Basic Information Section
                basicInfoSection

                // Schedule Section
                scheduleSection

                // Tags Section
                tagsSection

                // Validation Errors
                if !validationErrors.isEmpty {
                    validationErrorsSection
                }
            }
            .navigationTitle("Add Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.daisyHabit)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveHabit()
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(.daisyHabit)
                }
            }
        }
        .sheet(isPresented: $showingRecurrencePicker) {
            RecurrenceRulePickerView(
                recurrenceRule: $recurrenceRule
            )
        }
        .sheet(isPresented: $showingTagAssignment) {
            TagAssignmentSheet(
                title: "Habit Tags",
                selectedTags: $selectedTags,
                onSave: { tags in
                    selectedTags = tags
                    validateForm()
                }
            )
        }
        .onAppear {
            validateForm()
        }
    }

    // MARK: - Form Sections

    @ViewBuilder
    private var basicInfoSection: some View {
        Section("Habit Details") {
            ValidatedTitleField(
                text: $habitTitle,
                placeholder: "Habit title"
            )
            .onChange(of: habitTitle) { _, _ in
                validateForm()
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("Description (optional)")
                    .font(.subheadline)
                    .foregroundColor(.daisyTextSecondary)
                    .padding(.bottom, Spacing.extraSmall)

                RichTextEditor(
                    attributedText: $habitDescriptionAttributed,
                    placeholder: "Add details, notes, or formatting...",
                    maxLength: DesignSystem.inputValidation.CharacterLimits.description
                )
            }

            // Priority picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Priority")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.daisyText)

                PriorityPicker(
                    priority: $selectedPriority,
                    accentColor: .daisyHabit
                )
            }
        }
    }

    @ViewBuilder
    private var scheduleSection: some View {
        Section(content: {
            // Recurrence Rule
            Button(action: {
                showingRecurrencePicker = true
            }) {
                HStack {
                    Image(systemName: "repeat")
                        .foregroundColor(.daisyHabit)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Frequency")
                            .foregroundColor(.daisyText)

                        Text(recurrenceRule?.displayDescription ?? "Daily (flexible)")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }
            .buttonStyle(.plain)

        }, header: {
            Text("Schedule")
        })
    }

    @ViewBuilder
    private var tagsSection: some View {
        Section(
            content: {
                TagSelectionRow(
                    selectedTags: $selectedTags,
                    accentColor: .daisyHabit,
                    onShowTagSelection: { showingTagAssignment = true }
                )
            },
            header: {
                Text("Tags")
            },
            footer: {
                Text("Organize with up to 3 tags for easy filtering and grouping.")
            }
        )
    }

    @ViewBuilder
    private var validationErrorsSection: some View {
        let errorsByseverity = Dictionary(grouping: validationErrors, by: \.severity)

        Section {
            // Show errors first
            if let errors = errorsByseverity[.error], !errors.isEmpty {
                ForEach(Array(errors), id: \.self) { error in
                    Label(error.message, systemImage: error.severity.icon)
                        .foregroundColor(error.severity.color)
                        .font(.caption)
                }
            }

            // Then show warnings
            if let warnings = errorsByseverity[.warning], !warnings.isEmpty {
                ForEach(Array(warnings), id: \.self) { warning in
                    Label(warning.message, systemImage: warning.severity.icon)
                        .foregroundColor(warning.severity.color)
                        .font(.caption)
                }
            }
        } header: {
            let hasErrors = errorsByseverity[.error]?.isEmpty == false
            Text(hasErrors ? "Please Fix These Issues" : "Suggestions")
                .foregroundColor(hasErrors ? .daisyError : .orange)
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        // Only errors prevent form submission, warnings are just suggestions
        !validationErrors.contains { $0.severity == .error }
    }

    // MARK: - Methods

    private func validateForm() {
        var errors: Set<ValidationError> = []

        let trimmedTitle = habitTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        // Title validation
        if trimmedTitle.isEmpty {
            errors.insert(.emptyTitle)
        } else if trimmedTitle.count > DesignSystem.inputValidation.CharacterLimits.title {
            errors.insert(.titleTooLong)
        }

        // Description validation
        if habitDescriptionAttributed.characterCount > DesignSystem.inputValidation.CharacterLimits.description {
            errors.insert(.descriptionTooLong)
        }

        // Tags validation
        if selectedTags.count > 3 {
            errors.insert(.tooManyTags)
        }

        validationErrors = errors
    }

    private func saveHabit() {
        guard isFormValid else { return }

        let habit = Habit(
            title: habitTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            habitDescription: "", // Placeholder for backward compatibility
            recurrenceRule: recurrenceRule,
            priority: selectedPriority
        )

        // Set rich text description
        habit.habitDescriptionAttributed = habitDescriptionAttributed

        // Add to context
        modelContext.insert(habit)

        // Assign tags
        for tag in selectedTags {
            _ = habit.addTag(tag)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Handle error with proper error transformation
            let transformedError = ErrorTransformer.transformHabitError(error, operation: "create habit")
            habitManager.lastError = transformedError
        }
    }
}

// MARK: - Preview

#Preview("Add Habit") {
    let container = try! ModelContainer(
        for: Habit.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    let habitManager = HabitManager(modelContext: context)
    let tagManager = TagManager(modelContext: context)

    return AddHabitView()
        .modelContainer(container)
        .environment(habitManager)
        .environment(tagManager)
}

