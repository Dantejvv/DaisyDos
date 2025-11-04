//
//  RowActionButton.swift
//  DaisyDos
//
//  Created by Claude Code on 1/2/25.
//  Shared component for action buttons in row views
//

import SwiftUI

/// Reusable action button for row views with consistent styling and accessibility
struct RowActionButton: View {
    let systemName: String
    let color: Color
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.caption)
                .foregroundColor(color)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .frame(minWidth: 44, minHeight: 44) // Ensure 44pt touch target
    }
}
