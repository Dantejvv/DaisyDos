//
//  CompactIconButton.swift
//  DaisyDos
//
//  Standardized compact icon button for metadata toolbars
//  Shows active/inactive states with visual feedback
//

import SwiftUI

/// A compact icon button optimized for toolbar use.
///
/// Features:
/// - Active/inactive visual states
/// - Configurable accent color
/// - Fixed 28pt size for consistency
/// - Accessibility support built-in
///
/// Example:
/// ```swift
/// CompactIconButton(
///     icon: "calendar",
///     isActive: hasDueDate,
///     accentColor: .daisyTask
/// ) {
///     showingDatePicker = true
/// }
/// ```
struct CompactIconButton: View {
    let icon: String
    let isActive: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(isActive ? accentColor : .daisyTextSecondary)
                .frame(width: 28, height: 28)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            CompactIconButton(icon: "calendar", isActive: false, accentColor: .blue) {}
            CompactIconButton(icon: "calendar", isActive: true, accentColor: .blue) {}
        }

        HStack(spacing: 12) {
            CompactIconButton(icon: "bell", isActive: false, accentColor: .orange) {}
            CompactIconButton(icon: "bell.fill", isActive: true, accentColor: .orange) {}
        }

        HStack(spacing: 12) {
            CompactIconButton(icon: "flag", isActive: false, accentColor: .red) {}
            CompactIconButton(icon: "flag.fill", isActive: true, accentColor: .red) {}
        }
    }
    .padding()
}
