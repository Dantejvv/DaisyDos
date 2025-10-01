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

    // UI State
    @State private var showingRecurrencePicker = false
    @State private var showingTagAssignment = false
    @State private var validationErrors: Set<ValidationError> = []

    // MARK: - Validation

    enum ValidationError: String, CaseIterable {
        case emptyTitle = "Habit title is required"
        case titleTooLong = "Habit title must be 50 characters or less"
        case descriptionTooLong = "Description must be 200 characters or less"
        case tooManyTags = "Maximum 3 tags allowed"

        var message: String {
            return self.rawValue
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
                    .onChange(of: habitTitle) { _, _ in
                        validateForm()
                    }

                HStack {
                    Spacer()
                    let titleColor: Color = habitTitle.count > 50 ? .orange :
                                           habitTitle.count > 40 ? .yellow : .daisyTextSecondary
                    Text("\(habitTitle.count)/50")
                        .font(.caption2)
                        .foregroundColor(titleColor)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                TextField("Description (optional)", text: $habitDescription, axis: .vertical)
                    .lineLimit(3...6)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(true)
                    .onChange(of: habitDescription) { _, _ in
                        validateForm()
                    }

                HStack {
                    Spacer()
                    let descColor: Color = habitDescription.count > 200 ? .orange :
                                          habitDescription.count > 160 ? .yellow : .daisyTextSecondary
                    Text("\(habitDescription.count)/200")
                        .font(.caption2)
                        .foregroundColor(descColor)
                }
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
        } else if trimmedTitle.count > 50 {
            errors.insert(.titleTooLong)
        }

        // Description validation
        if trimmedDescription.count > 200 {
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
    let healthTag = tagManager.createTag(name: "Health", sfSymbolName: "heart", colorName: "green")!

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