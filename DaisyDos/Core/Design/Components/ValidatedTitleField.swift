//
//  ValidatedTitleField.swift
//  DaisyDos
//
//  Created by Claude Code on 10/17/25.
//  Reusable title input field with character counting and validation
//

import SwiftUI

/// A validated text field with character limit enforcement and visual feedback
struct ValidatedTitleField: View {
    @Binding var text: String
    let placeholder: String
    let maxLength: Int
    let showError: Bool

    init(
        text: Binding<String>,
        placeholder: String = "Title",
        maxLength: Int = DesignSystem.inputValidation.CharacterLimits.title,
        showError: Bool = false
    ) {
        self._text = text
        self.placeholder = placeholder
        self.maxLength = maxLength
        self.showError = showError
    }

    private var characterCount: Int {
        text.count
    }

    private var countColor: Color {
        DesignSystem.inputValidation.characterCountColorExact(
            currentCount: characterCount,
            maxLength: maxLength
        )
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var showValidationError: Bool {
        showError && trimmedText.isEmpty && !text.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(placeholder, text: $text)
                .autocorrectionDisabled(true)
                .accessibilityLabel(placeholder)
                .onChange(of: text) { _, newValue in
                    DesignSystem.inputValidation.enforceCharacterLimit(
                        &text,
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
    Form {
        Section("Example") {
            ValidatedTitleField(
                text: .constant("Sample Title"),
                placeholder: "Task Title"
            )
        }
    }
}
