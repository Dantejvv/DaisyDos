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
    @State private var habitDescription = ""
    @State private var recurrenceRule: RecurrenceRule?
    @State private var selectedTags: [Tag] = []

    // UI State
    @State private var showingRecurrencePicker = false
    @State private var showingTagAssignment = false
    @State private var validationErrors: Set<ValidationError> = []

    // MARK: - Validation

    enum ValidationError: String, CaseIterable {
        case emptyTitle = "Habit title is required"
        case tooManyTags = "Maximum 3 tags allowed"

        var message: String {
            return self.rawValue
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
            TextField("Habit title", text: $habitTitle)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)
                .onChange(of: habitTitle) { _, _ in
                    validateForm()
                }

            TextField("Description (optional)", text: $habitDescription, axis: .vertical)
                .lineLimit(3...6)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled(true)
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
        Section {
            ForEach(Array(validationErrors), id: \.self) { error in
                Label(error.message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.daisyError)
                    .font(.caption)
            }
        } header: {
            Text("Please Fix These Issues")
                .foregroundColor(.daisyError)
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        validationErrors.isEmpty
    }

    // MARK: - Methods

    private func validateForm() {
        var errors: Set<ValidationError> = []

        // Title validation
        if habitTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.insert(.emptyTitle)
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
            habitDescription: habitDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            recurrenceRule: recurrenceRule
        )

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

