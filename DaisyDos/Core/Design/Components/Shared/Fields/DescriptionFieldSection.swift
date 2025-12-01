//
//  DescriptionFieldSection.swift
//  DaisyDos
//
//  Standardized description/notes field using RichTextEditor
//  Used across Add/Edit views for Tasks and Habits
//

import SwiftUI

/// A standardized description field section using RichTextEditor.
///
/// Features:
/// - Rich text formatting support
/// - Configurable placeholder
/// - Configurable max length
/// - Consistent min height and styling
/// - Accessibility support
///
/// Example:
/// ```swift
/// DescriptionFieldSection(
///     attributedText: $taskDescription,
///     placeholder: "Add details or notes..."
/// )
/// ```
struct DescriptionFieldSection: View {
    @Binding var attributedText: AttributedString
    let placeholder: String
    let minHeight: CGFloat
    let maxLength: Int

    init(
        attributedText: Binding<AttributedString>,
        placeholder: String = "Add details or notes...",
        minHeight: CGFloat = 32,
        maxLength: Int = Int.max
    ) {
        self._attributedText = attributedText
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.maxLength = maxLength
    }

    var body: some View {
        RichTextEditor(
            attributedText: $attributedText,
            placeholder: placeholder,
            maxLength: maxLength
        )
        .frame(minHeight: minHeight)
        .padding(.leading, -Spacing.small)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Empty state
        DescriptionFieldSection(
            attributedText: .constant(AttributedString(""))
        )
        .padding()
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding()

        // With content
        DescriptionFieldSection(
            attributedText: .constant(AttributedString("This is a sample task description with some details about what needs to be done."))
        )
        .padding()
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding()
    }
}
