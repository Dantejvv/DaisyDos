//
//  View+SwipeActions.swift
//  DaisyDos
//
//  Created by Claude Code on 10/28/25.
//  Reusable swipe actions patterns for list rows
//

import SwiftUI

// MARK: - Standard Row Swipe Actions

extension View {
    /// Applies standard swipe actions for list rows with delete and edit on trailing edge
    /// - Parameters:
    ///   - isMultiSelectMode: Whether multi-select mode is active
    ///   - accentColor: The tint color for the edit button
    ///   - onDelete: Action to perform when delete is tapped
    ///   - onEdit: Action to perform when edit is tapped
    ///   - leadingAction: Optional closure for leading swipe action
    /// - Returns: View with swipe actions applied
    func standardRowSwipeActions(
        isMultiSelectMode: Bool,
        accentColor: Color,
        onDelete: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        @ViewBuilder leadingAction: @escaping () -> some View
    ) -> some View {
        self
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if !isMultiSelectMode {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }

                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(accentColor)
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                if !isMultiSelectMode {
                    leadingAction()
                }
            }
    }
}

// MARK: - Swipe Action Builders

/// Helper for creating duplicate action button
struct DuplicateSwipeAction: View {
    let onDuplicate: () -> Void

    var body: some View {
        Button(action: onDuplicate) {
            Label("Duplicate", systemImage: "plus.square.on.square")
        }
        .tint(.blue)
    }
}

/// Helper for creating skip action button
struct SkipSwipeAction: View {
    let onSkip: () -> Void

    var body: some View {
        Button(action: onSkip) {
            Label("Skip", systemImage: "forward")
        }
        .tint(.orange)
    }
}
