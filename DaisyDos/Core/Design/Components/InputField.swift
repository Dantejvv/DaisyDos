//
//  InputField.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI

/// Input field wrapper with validation and accessibility
/// Provides consistent styling, validation states, and accessibility labels
/// Supports different input types, secure entry, and custom validation
struct InputField: View {

    // MARK: - Configuration

    @Binding var text: String
    let label: String
    let placeholder: String
    let helperText: String?
    let errorMessage: String?
    let isRequired: Bool
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let textContentType: UITextContentType?
    let autocapitalization: TextInputAutocapitalization
    let maxLength: Int?
    let onEditingChanged: ((Bool) -> Void)?
    let onCommit: (() -> Void)?

    // MARK: - State Management

    @FocusState private var isFocused: Bool
    @State private var showCharacterCount: Bool = false

    // MARK: - Computed Properties

    private var hasError: Bool {
        errorMessage != nil && !errorMessage!.isEmpty
    }

    private var isOverLimit: Bool {
        guard let maxLength = maxLength else { return false }
        return text.count > maxLength
    }

    private var characterCountText: String {
        guard let maxLength = maxLength else { return "" }
        return "\(text.count)/\(maxLength)"
    }

    private var fieldState: FieldState {
        if hasError || isOverLimit {
            return .error
        } else if isFocused {
            return .focused
        } else {
            return .normal
        }
    }

    // MARK: - Field State

    enum FieldState {
        case normal
        case focused
        case error

        var borderColor: Color {
            switch self {
            case .normal:
                return Colors.Semantic.inputBorder
            case .focused:
                return Colors.Semantic.inputBorderFocused
            case .error:
                return Colors.Accent.error
            }
        }

        var borderWidth: CGFloat {
            switch self {
            case .normal:
                return 1
            case .focused, .error:
                return 2
            }
        }
    }

    // MARK: - Initializers

    /// Creates a comprehensive input field with all options
    init(
        text: Binding<String>,
        label: String,
        placeholder: String = "",
        helperText: String? = nil,
        errorMessage: String? = nil,
        isRequired: Bool = false,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        textContentType: UITextContentType? = nil,
        autocapitalization: TextInputAutocapitalization = .sentences,
        maxLength: Int? = nil,
        onEditingChanged: ((Bool) -> Void)? = nil,
        onCommit: (() -> Void)? = nil
    ) {
        self._text = text
        self.label = label
        self.placeholder = placeholder
        self.helperText = helperText
        self.errorMessage = errorMessage
        self.isRequired = isRequired
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.textContentType = textContentType
        self.autocapitalization = autocapitalization
        self.maxLength = maxLength
        self.onEditingChanged = onEditingChanged
        self.onCommit = onCommit
    }

    /// Creates a simple text input field
    init(
        _ label: String,
        text: Binding<String>,
        placeholder: String = "",
        isRequired: Bool = false,
        errorMessage: String? = nil
    ) {
        self.init(
            text: text,
            label: label,
            placeholder: placeholder,
            errorMessage: errorMessage,
            isRequired: isRequired
        )
    }

    // MARK: - View Body

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.extraSmall) {
            // Field label
            fieldLabel

            // Input field
            inputField

            // Helper text, error message, or character count
            fieldFooter
        }
        .animation(
            .easeInOut(duration: DesignSystem.Tokens.Animation.fast),
            value: fieldState
        )
    }

    private var fieldLabel: some View {
        HStack(spacing: Spacing.extraSmall) {
            Text(label)
                .font(.daisySubtitle.weight(.medium))
                .foregroundColor(labelColor)

            if isRequired {
                Text("*")
                    .font(.daisySubtitle.weight(.medium))
                    .foregroundColor(Colors.Accent.error)
            }

            Spacer()

            if showCharacterCount && maxLength != nil {
                Text(characterCountText)
                    .font(.daisyCaption)
                    .foregroundColor(isOverLimit ? Colors.Accent.error : Colors.Primary.textSecondary)
                    .monospacedDigit()
            }
        }
    }

    private var inputField: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(textContentType)
                    .autocorrectionDisabled(true)
            } else {
                TextField(placeholder, text: $text, axis: .horizontal)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled(true)
                    .onSubmit {
                        onCommit?()
                    }
            }
        }
        .focused($isFocused)
        .font(.daisyBody)
        .foregroundColor(Colors.Primary.text)
        .padding(EdgeInsets(
            top: Spacing.small,
            leading: Spacing.medium,
            bottom: Spacing.small,
            trailing: Spacing.medium
        ))
        .background(inputBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(fieldState.borderColor, lineWidth: fieldState.borderWidth)
        )
        .onChange(of: isFocused) { oldValue, newValue in
            onEditingChanged?(newValue)
            updateCharacterCountVisibility()
        }
        .onChange(of: text) { oldValue, newValue in
            // Apply max length limit
            if let maxLength = maxLength, newValue.count > maxLength {
                text = String(newValue.prefix(maxLength))
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityValue(text.isEmpty ? "Empty" : text)
    }

    private var inputBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Colors.Semantic.inputBackground)
                    .opacity(0.9)
            )
    }

    @ViewBuilder
    private var fieldFooter: some View {
        HStack {
            if let errorMessage = errorMessage, hasError {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.daisyCaption)
                    .foregroundColor(Colors.Accent.error)
                    .labelStyle(.titleAndIcon)
            } else if let helperText = helperText {
                Text(helperText)
                    .font(.daisyCaption)
                    .foregroundColor(Colors.Primary.textSecondary)
            }

            Spacer()
        }
    }

    // MARK: - Computed Styling Properties

    private var labelColor: Color {
        if hasError {
            return Colors.Accent.error
        } else if isFocused {
            return Colors.Secondary.blue
        } else {
            return Colors.Primary.text
        }
    }

    // MARK: - Helper Methods

    private func updateCharacterCountVisibility() {
        if maxLength != nil {
            showCharacterCount = isFocused || isOverLimit
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        var components = [label]

        if isRequired {
            components.append("required")
        }

        if hasError, let error = errorMessage {
            components.append("Error: \(error)")
        } else if let helper = helperText {
            components.append(helper)
        }

        if let maxLength = maxLength {
            components.append("Maximum \(maxLength) characters")
        }

        return components.joined(separator: ", ")
    }

    private var accessibilityHint: String {
        if isSecure {
            return "Secure text field"
        } else {
            return "Text field"
        }
    }
}

// MARK: - Convenience Initializers

extension InputField {

    /// Email input field
    static func email(
        text: Binding<String>,
        label: String = "Email",
        placeholder: String = "Enter your email",
        isRequired: Bool = false,
        errorMessage: String? = nil
    ) -> InputField {
        InputField(
            text: text,
            label: label,
            placeholder: placeholder,
            errorMessage: errorMessage,
            isRequired: isRequired,
            keyboardType: .emailAddress,
            textContentType: .emailAddress,
            autocapitalization: .never
        )
    }

    /// Password input field
    static func password(
        text: Binding<String>,
        label: String = "Password",
        placeholder: String = "Enter your password",
        isRequired: Bool = true,
        errorMessage: String? = nil,
        helperText: String? = nil
    ) -> InputField {
        InputField(
            text: text,
            label: label,
            placeholder: placeholder,
            helperText: helperText,
            errorMessage: errorMessage,
            isRequired: isRequired,
            isSecure: true,
            textContentType: .password
        )
    }

    /// Search input field
    static func search(
        text: Binding<String>,
        placeholder: String = "Search...",
        onCommit: (() -> Void)? = nil
    ) -> InputField {
        InputField(
            text: text,
            label: "Search",
            placeholder: placeholder,
            keyboardType: .webSearch,
            textContentType: .username, // Prevents password suggestions
            onCommit: onCommit
        )
    }

    /// Text area input field
    static func textArea(
        text: Binding<String>,
        label: String,
        placeholder: String = "",
        maxLength: Int = 500,
        isRequired: Bool = false,
        errorMessage: String? = nil
    ) -> InputField {
        InputField(
            text: text,
            label: label,
            placeholder: placeholder,
            errorMessage: errorMessage,
            isRequired: isRequired,
            autocapitalization: .sentences,
            maxLength: maxLength
        )
    }

    /// Number input field
    static func number(
        text: Binding<String>,
        label: String,
        placeholder: String = "0",
        isRequired: Bool = false,
        errorMessage: String? = nil
    ) -> InputField {
        InputField(
            text: text,
            label: label,
            placeholder: placeholder,
            errorMessage: errorMessage,
            isRequired: isRequired,
            keyboardType: .numberPad,
            autocapitalization: .never
        )
    }
}

// MARK: - Validation Extensions

extension InputField {

    /// Adds validation state to the input field
    func validation(errorMessage: String?) -> InputField {
        InputField(
            text: self._text,
            label: self.label,
            placeholder: self.placeholder,
            helperText: self.helperText,
            errorMessage: errorMessage,
            isRequired: self.isRequired,
            isSecure: self.isSecure,
            keyboardType: self.keyboardType,
            textContentType: self.textContentType,
            autocapitalization: self.autocapitalization,
            maxLength: self.maxLength,
            onEditingChanged: self.onEditingChanged,
            onCommit: self.onCommit
        )
    }

    /// Adds helper text to the input field
    func helper(_ text: String) -> InputField {
        InputField(
            text: self._text,
            label: self.label,
            placeholder: self.placeholder,
            helperText: text,
            errorMessage: self.errorMessage,
            isRequired: self.isRequired,
            isSecure: self.isSecure,
            keyboardType: self.keyboardType,
            textContentType: self.textContentType,
            autocapitalization: self.autocapitalization,
            maxLength: self.maxLength,
            onEditingChanged: self.onEditingChanged,
            onCommit: self.onCommit
        )
    }
}

// MARK: - Input Validation Utilities

extension InputField {

    /// Common validation patterns
    enum ValidationPattern {
        case email
        case phone
        case url
        case required

        var regex: String {
            switch self {
            case .email:
                return "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$"
            case .phone:
                return "^\\+?[1-9]\\d{1,14}$"
            case .url:
                return "^https?://[\\w\\.-]+\\.[a-z]{2,}.*$"
            case .required:
                return "^.+$"
            }
        }

        func validate(_ input: String) -> Bool {
            let predicate = NSPredicate(format: "SELF MATCHES[c] %@", regex)
            return predicate.evaluate(with: input)
        }

        var errorMessage: String {
            switch self {
            case .email:
                return "Please enter a valid email address"
            case .phone:
                return "Please enter a valid phone number"
            case .url:
                return "Please enter a valid URL"
            case .required:
                return "This field is required"
            }
        }
    }

    /// Validates input against a pattern
    static func validate(_ input: String, against pattern: ValidationPattern) -> String? {
        if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && pattern == .required {
            return pattern.errorMessage
        }

        if !input.isEmpty && !pattern.validate(input) {
            return pattern.errorMessage
        }

        return nil
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct InputField_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Spacing.large) {
                Group {
                    Text("Input Field Examples")
                        .font(.daisyTitle)
                        .padding(.top)

                    InputField(
                        "Basic Text Field",
                        text: .constant(""),
                        placeholder: "Enter text here"
                    )

                    InputField.email(
                        text: .constant(""),
                        isRequired: true
                    )

                    InputField.password(
                        text: .constant(""),
                        helperText: "Minimum 8 characters"
                    )

                    InputField(
                        "With Error",
                        text: .constant("invalid-email"),
                        placeholder: "Email address",
                        isRequired: true,
                        errorMessage: "Please enter a valid email address"
                    )

                    InputField.textArea(
                        text: .constant(""),
                        label: "Description",
                        placeholder: "Enter a description...",
                        maxLength: 200
                    )

                    InputField.search(
                        text: .constant(""),
                        placeholder: "Search tasks and habits..."
                    )
                }
            }
            .padding()
        }
        .background(Colors.Primary.background)
    }
}
#endif