//
//  RichTextEditor.swift
//  DaisyDos
//
//  Created by Claude Code on 10/15/25.
//

import SwiftUI

/// Rich text editor with formatting toolbar for iOS 17+
/// Supports Bold, Italic, Underline, and Bullet Lists
/// Maintains liquid glass aesthetic with native SwiftUI components
struct RichTextEditor: View {

    // MARK: - Properties

    @Binding var attributedText: AttributedString
    let placeholder: String
    let maxLength: Int

    @State private var nsAttributedText: NSAttributedString
    @State private var isEditing: Bool = false
    @State private var showToolbar: Bool = false

    // MARK: - Computed Properties

    private var currentCharacterCount: Int {
        attributedText.characters.count
    }

    private var characterCountColor: Color {
        DesignSystem.inputValidation.characterCountColorExact(
            currentCount: currentCharacterCount,
            maxLength: maxLength
        )
    }

    // MARK: - Initializer

    init(
        attributedText: Binding<AttributedString>,
        placeholder: String = "",
        maxLength: Int = DesignSystem.inputValidation.CharacterLimits.description
    ) {
        self._attributedText = attributedText
        self.placeholder = placeholder
        self.maxLength = maxLength
        self._nsAttributedText = State(initialValue: NSAttributedString(attributedText.wrappedValue))
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Text Editor
            textEditorView

            // Formatting Toolbar
            if showToolbar {
                FormattingToolbar(
                    nsAttributedText: $nsAttributedText,
                    onUpdate: { newText in
                        if let attrString = try? AttributedString(newText, including: \.uiKit) {
                            attributedText = attrString
                        }
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Character Count
            characterCountView
        }
        .animation(.easeInOut(duration: DesignSystem.Tokens.Animation.fast), value: showToolbar)
        .onChange(of: isEditing) { _, newValue in
            withAnimation {
                showToolbar = newValue
            }
        }
        .onChange(of: attributedText) { _, newValue in
            nsAttributedText = NSAttributedString(newValue)
        }
        .onAppear {
            // Show toolbar immediately if there's content
            showToolbar = !attributedText.characters.isEmpty
        }
    }

    // MARK: - Subviews

    private var textEditorView: some View {
        ZStack(alignment: .topLeading) {
            // Background with liquid glass effect
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Colors.Semantic.inputBackground)
                        .opacity(0.9)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isEditing ? Colors.Semantic.inputBorderFocused : Colors.Semantic.inputBorder,
                            lineWidth: isEditing ? 2 : 1
                        )
                )

            VStack(alignment: .leading, spacing: 0) {
                // TextEditor wrapper
                TextEditorWrapper(
                    nsAttributedText: $nsAttributedText,
                    isEditing: $isEditing,
                    placeholder: placeholder,
                    maxLength: maxLength,
                    onUpdate: { newText in
                        if let attrString = try? AttributedString(newText, including: \.uiKit) {
                            attributedText = attrString
                        }
                    }
                )
                .frame(minHeight: 80, maxHeight: 180)
                .padding(Spacing.small)
            }
        }
    }

    private var characterCountView: some View {
        HStack {
            Spacer()
            Text("\(currentCharacterCount)/\(maxLength)")
                .font(.caption2)
                .foregroundColor(characterCountColor)
                .monospacedDigit()
                .padding(.top, Spacing.extraSmall)
        }
    }
}

// MARK: - TextEditor Wrapper

/// UITextView wrapper for rich text editing with NSAttributedString support
private struct TextEditorWrapper: UIViewRepresentable {

    @Binding var nsAttributedText: NSAttributedString
    @Binding var isEditing: Bool

    let placeholder: String
    let maxLength: Int
    let onUpdate: (NSAttributedString) -> Void

    // Store reference to the actual UITextView for toolbar actions
    static var currentTextView: UITextView?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator

        // Styling
        textView.backgroundColor = .clear
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.textColor = UIColor(Colors.Primary.text)
        textView.autocapitalizationType = .sentences
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.keyboardType = .default
        textView.returnKeyType = .default

        // Allow rich text formatting
        textView.allowsEditingTextAttributes = true

        // Accessibility
        textView.isAccessibilityElement = true
        textView.accessibilityLabel = "Description text editor"
        textView.accessibilityHint = "Enter and format your text here"

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        // Update text if changed externally
        if textView.attributedText != nsAttributedText {
            let selectedRange = textView.selectedRange
            textView.attributedText = nsAttributedText
            textView.selectedRange = selectedRange
        }

        // Update placeholder visibility
        context.coordinator.updatePlaceholder(in: textView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextEditorWrapper
        private var placeholderLabel: UILabel?

        init(_ parent: TextEditorWrapper) {
            self.parent = parent
            super.init()
        }

        func textViewDidChange(_ textView: UITextView) {
            // Enforce character limit
            if textView.text.count > parent.maxLength {
                textView.text = String(textView.text.prefix(parent.maxLength))
            }

            // Update binding
            parent.nsAttributedText = textView.attributedText
            parent.onUpdate(textView.attributedText)

            // Update placeholder
            updatePlaceholder(in: textView)
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isEditing = true
            TextEditorWrapper.currentTextView = textView

            // Sync typing attributes with the current cursor position
            syncTypingAttributesWithCursor(in: textView)
        }

        /// Sync typing attributes with the formatting at the cursor position
        private func syncTypingAttributesWithCursor(in textView: UITextView) {
            let selectedRange = textView.selectedRange

            // Only sync if we're at a cursor position (no selection)
            // and the text is not empty
            guard selectedRange.length == 0, textView.attributedText.length > 0 else {
                return
            }

            // If cursor is in the middle of text, inherit attributes from the character before cursor
            if selectedRange.location > 0 && selectedRange.location <= textView.attributedText.length {
                let attributes = textView.attributedText.attributes(at: selectedRange.location - 1, effectiveRange: nil)

                // Only update if the attributes are actually different
                // This prevents overriding manual format toggles
                if !areAttributesEqual(attributes, textView.typingAttributes) {
                    textView.typingAttributes = attributes
                }
            } else {
                // If at the beginning, use default attributes
                let defaultFont = UIFont.preferredFont(forTextStyle: .body)
                let defaultColor = UIColor(Colors.Primary.text)

                textView.typingAttributes = [
                    .font: defaultFont,
                    .foregroundColor: defaultColor
                ]
            }
        }

        /// Check if two attribute dictionaries are equal for formatting purposes
        private func areAttributesEqual(_ attr1: [NSAttributedString.Key: Any], _ attr2: [NSAttributedString.Key: Any]) -> Bool {
            // Compare font traits (bold, italic)
            let font1 = attr1[.font] as? UIFont
            let font2 = attr2[.font] as? UIFont
            let traits1 = font1?.fontDescriptor.symbolicTraits ?? []
            let traits2 = font2?.fontDescriptor.symbolicTraits ?? []

            // Compare underline
            let underline1 = attr1[.underlineStyle] != nil
            let underline2 = attr2[.underlineStyle] != nil

            return traits1 == traits2 && underline1 == underline2
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            // Update typing attributes when cursor moves
            syncTypingAttributesWithCursor(in: textView)
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isEditing = false
            TextEditorWrapper.currentTextView = nil
        }

        func updatePlaceholder(in textView: UITextView) {
            // Create placeholder label if needed
            if placeholderLabel == nil {
                let label = UILabel()
                label.text = parent.placeholder
                label.font = UIFont.preferredFont(forTextStyle: .body)
                label.textColor = UIColor.placeholderText
                label.numberOfLines = 0
                label.translatesAutoresizingMaskIntoConstraints = false
                textView.addSubview(label)

                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 5),
                    label.trailingAnchor.constraint(equalTo: textView.trailingAnchor, constant: -5),
                    label.topAnchor.constraint(equalTo: textView.topAnchor, constant: 8)
                ])

                placeholderLabel = label
            }

            // Show/hide placeholder
            placeholderLabel?.isHidden = !textView.text.isEmpty
        }
    }
}

// MARK: - Formatting Toolbar

/// Toolbar with formatting controls for rich text editing
private struct FormattingToolbar: View {

    @Binding var nsAttributedText: NSAttributedString
    let onUpdate: (NSAttributedString) -> Void

    @State private var isBoldActive: Bool = false
    @State private var isItalicActive: Bool = false
    @State private var isUnderlineActive: Bool = false
    @State private var updateTrigger: Int = 0

    var body: some View {
        HStack(spacing: 20) {
            boldButton
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isBoldActive ? Color.daisyTask.opacity(0.3) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isBoldActive ? Color.daisyTask : Color.clear, lineWidth: 2)
                )

            italicButton
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isItalicActive ? Color.daisyTask.opacity(0.3) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isItalicActive ? Color.daisyTask : Color.clear, lineWidth: 2)
                )

            underlineButton
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isUnderlineActive ? Color.daisyTask.opacity(0.3) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isUnderlineActive ? Color.daisyTask : Color.clear, lineWidth: 2)
                )

            Divider()
                .frame(height: 24)

            bulletButton
                .frame(width: 44, height: 44)

            Spacer()
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, y: -2)
        )
        .onAppear {
            updateActiveStates()
            setupSelectionChangeObserver()
        }
        .onChange(of: updateTrigger) { _, _ in
            updateActiveStates()
        }
    }

    private var boldButton: some View {
        Button {
            toggleBold()
            updateActiveStates()
        } label: {
            Image(systemName: "bold")
                .font(.body)
                .foregroundColor(isBoldActive ? .daisyTask : .daisyText)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel("Bold")
    }

    private var italicButton: some View {
        Button {
            toggleItalic()
            updateActiveStates()
        } label: {
            Image(systemName: "italic")
                .font(.body)
                .foregroundColor(isItalicActive ? .daisyTask : .daisyText)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel("Italic")
    }

    private var underlineButton: some View {
        Button {
            toggleUnderline()
            updateActiveStates()
        } label: {
            Image(systemName: "underline")
                .font(.body)
                .foregroundColor(isUnderlineActive ? .daisyTask : .daisyText)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel("Underline")
    }

    private var bulletButton: some View {
        Button {
            insertBulletPoint()
        } label: {
            Image(systemName: "list.bullet")
                .font(.body)
                .foregroundColor(.daisyText)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel("Bullet List")
    }

    // MARK: - Formatting Actions

    private func toggleBold() {
        toggleAttribute(.font, trait: .traitBold)
    }

    private func toggleItalic() {
        toggleAttribute(.font, trait: .traitItalic)
    }

    private func toggleAttribute(_ key: NSAttributedString.Key, trait: UIFontDescriptor.SymbolicTraits) {
        guard let textView = TextEditorWrapper.currentTextView else { return }

        let selectedRange = textView.selectedRange

        // If no text selected, toggle the typing attributes for future text
        if selectedRange.length == 0 {
            var typingAttributes = textView.typingAttributes

            let currentFont = typingAttributes[.font] as? UIFont ?? UIFont.preferredFont(forTextStyle: .body)
            let descriptor = currentFont.fontDescriptor

            let newTraits: UIFontDescriptor.SymbolicTraits
            if descriptor.symbolicTraits.contains(trait) {
                newTraits = descriptor.symbolicTraits.subtracting(trait)
            } else {
                newTraits = descriptor.symbolicTraits.union(trait)
            }

            if let newDescriptor = descriptor.withSymbolicTraits(newTraits) {
                let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
                typingAttributes[.font] = newFont
                textView.typingAttributes = typingAttributes
            }
            return
        }

        // Apply to selected text
        let mutableString = NSMutableAttributedString(attributedString: textView.attributedText)

        // Get current font at selection
        var currentFont = UIFont.preferredFont(forTextStyle: .body)
        if selectedRange.location < mutableString.length {
            if let font = mutableString.attribute(.font, at: selectedRange.location, effectiveRange: nil) as? UIFont {
                currentFont = font
            }
        }

        let descriptor = currentFont.fontDescriptor
        let newTraits: UIFontDescriptor.SymbolicTraits

        if descriptor.symbolicTraits.contains(trait) {
            newTraits = descriptor.symbolicTraits.subtracting(trait)
        } else {
            newTraits = descriptor.symbolicTraits.union(trait)
        }

        if let newDescriptor = descriptor.withSymbolicTraits(newTraits) {
            let newFont = UIFont(descriptor: newDescriptor, size: currentFont.pointSize)
            mutableString.addAttribute(.font, value: newFont, range: selectedRange)
        }

        textView.attributedText = mutableString
        textView.selectedRange = selectedRange

        nsAttributedText = mutableString
        onUpdate(mutableString)
    }

    private func toggleUnderline() {
        guard let textView = TextEditorWrapper.currentTextView else { return }

        let selectedRange = textView.selectedRange

        // If no text selected, toggle the typing attributes for future text
        if selectedRange.length == 0 {
            var typingAttributes = textView.typingAttributes
            let hasUnderline = typingAttributes[.underlineStyle] != nil

            if hasUnderline {
                typingAttributes.removeValue(forKey: .underlineStyle)
            } else {
                typingAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            }

            textView.typingAttributes = typingAttributes
            return
        }

        // Apply to selected text
        let mutableString = NSMutableAttributedString(attributedString: textView.attributedText)

        // Check if selection already has underline
        var hasUnderline = false
        if selectedRange.location < mutableString.length {
            if let _ = mutableString.attribute(.underlineStyle, at: selectedRange.location, effectiveRange: nil) {
                hasUnderline = true
            }
        }

        if hasUnderline {
            mutableString.removeAttribute(.underlineStyle, range: selectedRange)
        } else {
            mutableString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: selectedRange)
        }

        textView.attributedText = mutableString
        textView.selectedRange = selectedRange

        nsAttributedText = mutableString
        onUpdate(mutableString)
    }

    private func insertBulletPoint() {
        guard let textView = TextEditorWrapper.currentTextView else { return }

        let selectedRange = textView.selectedRange
        let mutableString = NSMutableAttributedString(attributedString: textView.attributedText)

        let bullet = NSAttributedString(string: "• ")
        mutableString.insert(bullet, at: selectedRange.location)

        textView.attributedText = mutableString
        textView.selectedRange = NSRange(location: selectedRange.location + bullet.length, length: 0)

        nsAttributedText = mutableString
        onUpdate(mutableString)
    }

    // MARK: - Active State Management

    private func updateActiveStates() {
        guard let textView = TextEditorWrapper.currentTextView else { return }

        let typingAttributes = textView.typingAttributes

        // Check bold
        if let font = typingAttributes[.font] as? UIFont {
            isBoldActive = font.fontDescriptor.symbolicTraits.contains(.traitBold)
        } else {
            isBoldActive = false
        }

        // Check italic
        if let font = typingAttributes[.font] as? UIFont {
            isItalicActive = font.fontDescriptor.symbolicTraits.contains(.traitItalic)
        } else {
            isItalicActive = false
        }

        // Check underline
        isUnderlineActive = typingAttributes[.underlineStyle] != nil
    }

    private func setupSelectionChangeObserver() {
        // Set up a timer to periodically update button states
        // NOTE: We only update UI state, NOT typing attributes
        // Typing attributes are managed by UITextView and our toggle methods
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let _ = TextEditorWrapper.currentTextView else { return }

            // Trigger UI update to sync button states with current typing attributes
            updateTrigger += 1
        }
    }
}

// MARK: - Format Button

private struct FormatButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.daisyText)
                .frame(width: 32, height: 32)
        }
        .accessibilityLabel(label)
    }
}

// MARK: - Preview

#Preview("Rich Text Editor") {
    struct PreviewWrapper: View {
        @State private var text = AttributedString("This is a sample description with some text.")

        var body: some View {
            VStack(spacing: Spacing.large) {
                Text("Rich Text Editor")
                    .font(.daisyTitle)

                RichTextEditor(
                    attributedText: $text,
                    placeholder: "Enter description here...",
                    maxLength: 200
                )

                // Show plain text for debugging
                Text("Plain text: \(String(text.characters))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
            .padding()
            .background(Colors.Primary.background)
        }
    }

    return PreviewWrapper()
}
