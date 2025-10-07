//
//  HabitEditView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI
import SwiftData

struct HabitEditView: View {
    // MARK: - Properties

    @Bindable var habit: Habit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(TagManager.self) private var tagManager

    @State private var habitManager: HabitManager
    @State private var habitTitle: String
    @State private var habitDescription: String
    @State private var recurrenceRule: RecurrenceRule?
    @State private var selectedTags: [Tag] = []
    @State private var selectedPriority: HabitPriority

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

    // MARK: - Initializer

    init(habit: Habit) {
        self.habit = habit
        self._habitManager = State(initialValue: HabitManager(modelContext: ModelContext(habit.modelContext!.container)))
        self._habitTitle = State(initialValue: habit.title)
        self._habitDescription = State(initialValue: habit.habitDescription)
        self._recurrenceRule = State(initialValue: habit.recurrenceRule)
        self._selectedTags = State(initialValue: Array(habit.tags))
        self._selectedPriority = State(initialValue: habit.priority)
    }

    // MARK: - Character Count Colors

    private var titleCountColor: Color {
        return DesignSystem.inputValidation.characterCountColorExact(
            currentCount: habitTitle.count,
            maxLength: DesignSystem.inputValidation.CharacterLimits.title
        )
    }

    private var descriptionCountColor: Color {
        return DesignSystem.inputValidation.characterCountColorExact(
            currentCount: habitDescription.count,
            maxLength: DesignSystem.inputValidation.CharacterLimits.description
        )
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
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveHabit()
                    }
                    .disabled(!isFormValid)
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
            VStack(alignment: .leading, spacing: 4) {
                TextField("Habit title", text: $habitTitle)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .onChange(of: habitTitle) { _, newValue in
                        DesignSystem.inputValidation.enforceCharacterLimit(
                            &habitTitle,
                            newValue: newValue,
                            maxLength: DesignSystem.inputValidation.CharacterLimits.title
                        )
                        validateForm()
                    }

                HStack {
                    Spacer()
                    Text("\(habitTitle.count)/\(DesignSystem.inputValidation.CharacterLimits.title)")
                        .font(.caption2)
                        .foregroundColor(titleCountColor)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                TextField("Description (optional)", text: $habitDescription, axis: .vertical)
                    .lineLimit(3...6)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(true)
                    .onChange(of: habitDescription) { _, newValue in
                        DesignSystem.inputValidation.enforceCharacterLimit(
                            &habitDescription,
                            newValue: newValue,
                            maxLength: DesignSystem.inputValidation.CharacterLimits.description
                        )
                        validateForm()
                    }

                HStack {
                    Spacer()
                    Text("\(habitDescription.count)/\(DesignSystem.inputValidation.CharacterLimits.description)")
                        .font(.caption2)
                        .foregroundColor(descriptionCountColor)
                }
            }

            // Priority picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Priority")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.daisyText)

                HStack(spacing: 0) {
                    ForEach(HabitPriority.allCases, id: \.self) { priorityOption in
                        Button(action: {
                            selectedPriority = priorityOption
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
                                    .fill(selectedPriority == priorityOption ? Color.daisyHabit.opacity(0.2) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.daisyHabit, lineWidth: selectedPriority == priorityOption ? 2 : 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(selectedPriority == priorityOption ? .daisyHabit : .daisyText)
                    }
                }
                .padding(.horizontal, 4)
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
        Section(content: {
            // Tag Assignment
            Button(action: {
                showingTagAssignment = true
            }) {
                HStack {
                    Image(systemName: "tag.fill")
                        .foregroundColor(.daisyTag)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tags")
                            .foregroundColor(.daisyText)

                        if selectedTags.isEmpty {
                            Text("No tags selected")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(selectedTags, id: \.id) { tag in
                                        TagChipView(tag: tag)
                                            .scaleEffect(0.9)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }
            .buttonStyle(.plain)
        }, header: {
            Text("Organization")
        }, footer: {
            Text("Organize habits with up to 3 tags for easy filtering and grouping.")
        })
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
        let trimmedDescription = habitDescription.trimmingCharacters(in: .whitespacesAndNewlines)

        // Title validation
        if trimmedTitle.isEmpty {
            errors.insert(.emptyTitle)
        } else if trimmedTitle.count > DesignSystem.inputValidation.CharacterLimits.title {
            errors.insert(.titleTooLong)
        }

        // Description validation
        if trimmedDescription.count > DesignSystem.inputValidation.CharacterLimits.description {
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

        // Update habit properties
        habit.title = habitTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        habit.habitDescription = habitDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        habit.recurrenceRule = recurrenceRule
        habit.priority = selectedPriority

        // Update tags
        let currentTags = Set(habit.tags)
        let newTags = Set(selectedTags)

        // Remove tags that are no longer selected
        for tag in currentTags.subtracting(newTags) {
            habit.removeTag(tag)
        }

        // Add newly selected tags
        for tag in newTags.subtracting(currentTags) {
            _ = habit.addTag(tag)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            // Handle error with proper error transformation
            let transformedError = ErrorTransformer.transformHabitError(error, operation: "update habit")
            habitManager.lastError = transformedError
        }
    }
}

// MARK: - Preview

#Preview("Edit Habit") {
    let container = try! ModelContainer(
        for: Habit.self, Tag.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    let tagManager = TagManager(modelContext: context)

    // Create sample tags
    let workoutTag = tagManager.createTag(name: "Workout", sfSymbolName: "figure.run", colorName: "red")!
    _ = tagManager.createTag(name: "Health", sfSymbolName: "heart", colorName: "green")

    let habit = Habit(
        title: "Morning Exercise",
        habitDescription: "30 minutes of cardio to start the day",
        recurrenceRule: .daily()
    )
    _ = habit.addTag(workoutTag)
    context.insert(habit)

    return HabitEditView(habit: habit)
        .modelContainer(container)
        .environment(tagManager)
}