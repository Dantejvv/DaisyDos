//
//  TitleFieldSection.swift
//  DaisyDos
//
//  Standardized title input field with validation and character counting
//  Used across Add/Edit views for Tasks and Habits
//

import SwiftUI

/// A standardized title input section with validation, character counting, and error display.
///
/// Features:
/// - Character limit enforcement (50 chars default)
/// - Visual character count with color coding
/// - Empty title validation with error message
/// - Consistent styling across all forms
/// - Accessibility support
///
/// Example:
/// ```swift
/// TitleFieldSection(
///     title: $title,
///     placeholder: "Task title",
///     showError: showTitleError
/// )
/// ```
struct TitleFieldSection: View {
    @Binding var title: String
    let placeholder: String
    let showError: Bool
    let maxLength: Int

    init(
        title: Binding<String>,
        placeholder: String = "Title",
        showError: Bool = false,
        maxLength: Int = DesignSystem.inputValidation.CharacterLimits.title
    ) {
        self._title = title
        self.placeholder = placeholder
        self.showError = showError
        self.maxLength = maxLength
    }

    private var characterCount: Int {
        title.count
    }

    private var countColor: Color {
        DesignSystem.inputValidation.characterCountColorExact(
            currentCount: characterCount,
            maxLength: maxLength
        )
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var showValidationError: Bool {
        showError && trimmedTitle.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(placeholder, text: $title)
                .font(.title3)
                .autocorrectionDisabled(true)
                .accessibilityLabel(placeholder)
                .onChange(of: title) { _, newValue in
                    DesignSystem.inputValidation.enforceCharacterLimit(
                        &title,
                        newValue: newValue,
                        maxLength: maxLength
                    )
                }

            HStack {
                if showValidationError {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.daisyError)
                        Text("Title cannot be empty")
                            .font(.caption)
                            .foregroundColor(.daisyError)
                    }
                }

                Spacer()

                Text("\(characterCount)/\(maxLength)")
                    .font(.caption)
                    .foregroundColor(countColor)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Normal state
        TitleFieldSection(
            title: .constant("Sample Task"),
            placeholder: "Task title"
        )
        .padding()
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding()

        // Error state
        TitleFieldSection(
            title: .constant(""),
            placeholder: "Task title",
            showError: true
        )
        .padding()
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding()

        // Near limit state
        TitleFieldSection(
            title: .constant("This is a very long task title approaching the"),
            placeholder: "Task title"
        )
        .padding()
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding()
    }
}
