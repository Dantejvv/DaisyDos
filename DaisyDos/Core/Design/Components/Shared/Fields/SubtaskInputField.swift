//
//  SubtaskInputField.swift
//  DaisyDos
//
//  Standardized inline subtask input field
//  Used for adding new subtasks in Add/Edit/Detail views
//

import SwiftUI

/// An inline input field for adding new subtasks.
///
/// Features:
/// - Circle icon placeholder (disabled)
/// - Text field with focus management
/// - Conditional "done" button when text is present
/// - Submit on return key or done button
/// - Character limit enforcement
/// - Accessibility support
///
/// Example:
/// ```swift
/// SubtaskInputField(
///     text: $newSubtaskTitle,
///     isFocused: $newSubtaskFocused,
///     onAdd: {
///         addSubtask()
///     }
/// )
/// ```
struct SubtaskInputField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let placeholder: String
    let maxLength: Int
    let onAdd: () -> Void

    init(
        text: Binding<String>,
        isFocused: FocusState<Bool>.Binding,
        placeholder: String = "Add subtask",
        maxLength: Int = DesignSystem.inputValidation.CharacterLimits.title,
        onAdd: @escaping () -> Void
    ) {
        self._text = text
        self.isFocused = isFocused
        self.placeholder = placeholder
        self.maxLength = maxLength
        self.onAdd = onAdd
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasText: Bool {
        !trimmedText.isEmpty
    }

    var body: some View {
        HStack(spacing: Spacing.small) {
            // Circle icon placeholder (disabled)
            Button(action: {}) {
                Image(systemName: "circle")
                    .font(.body)
                    .foregroundColor(.daisyTextSecondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .disabled(true)
            .accessibilityHidden(true)

            // Input field
            TextField(placeholder, text: $text)
                .font(.body)
                .foregroundColor(.daisyText)
                .focused(isFocused)
                .submitLabel(.done)
                .autocorrectionDisabled(true)
                .accessibilityLabel(placeholder)
                .onChange(of: text) { _, newValue in
                    DesignSystem.inputValidation.enforceCharacterLimit(
                        &text,
                        newValue: newValue,
                        maxLength: maxLength
                    )
                }
                .onSubmit {
                    if hasText {
                        onAdd()
                    }
                }

            // Done/Add button - only show when there's text
            if hasText {
                Button(action: onAdd) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundColor(.daisyTask)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add subtask")
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, Spacing.medium)
        .frame(height: 32)
        .animation(.easeInOut(duration: 0.2), value: hasText)
    }
}

#Preview {
    @Previewable @State var text = ""
    @Previewable @FocusState var isFocused: Bool

    VStack(spacing: 0) {
        SubtaskInputField(
            text: $text,
            isFocused: $isFocused,
            onAdd: {
                print("Added: \(text)")
                text = ""
            }
        )
    }
    .background(Color.daisySurface)
    .cornerRadius(12)
    .padding()
    .onAppear {
        isFocused = true
    }
}
