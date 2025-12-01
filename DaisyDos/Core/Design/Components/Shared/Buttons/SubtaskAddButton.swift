//
//  SubtaskAddButton.swift
//  DaisyDos
//
//  Standardized "Add Subtask" button
//  Always visible trigger for showing subtask input field
//

import SwiftUI

/// A button for triggering subtask addition.
///
/// Features:
/// - "Add Subtask" label with plus icon
/// - Consistent styling with 44pt touch target
/// - Tap gesture handling
/// - Accessibility support
///
/// Example:
/// ```swift
/// SubtaskAddButton {
///     showSubtaskField = true
///     focusField = true
/// }
/// ```
struct SubtaskAddButton: View {
    let accentColor: Color
    let action: () -> Void

    init(accentColor: Color = .daisyTask, action: @escaping () -> Void) {
        self.accentColor = accentColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "plus.circle")
                Text("Add Subtask")
                Spacer()
            }
            .font(.body)
            .foregroundColor(accentColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add Subtask")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 16) {
        SubtaskAddButton {
            print("Add subtask tapped")
        }
        .background(Color.daisySurface)
        .cornerRadius(12)

        // In context with subtasks
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "circle")
                    .foregroundColor(.daisyTextSecondary)
                Text("Example subtask")
                Spacer()
            }
            .padding()

            Divider()

            SubtaskAddButton {
                print("Add subtask tapped")
            }
        }
        .background(Color.daisySurface)
        .cornerRadius(12)
    }
    .padding()
}
