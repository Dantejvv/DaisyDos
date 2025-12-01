//
//  RowStylingModifier.swift
//  DaisyDos
//
//  Created by Claude Code on 1/11/25.
//  Reusable row styling for multi-select and interaction
//

import SwiftUI

// MARK: - Row Styling Modifier

struct RowStylingModifier: ViewModifier {
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void

    func body(content: Content) -> some View {
        content
            .listRowBackground(
                Group {
                    if isSelected {
                        HStack(spacing: 0) {
                            // Left border accent
                            Rectangle()
                                .fill(accentColor)
                                .frame(width: 6)

                            // Background tint
                            accentColor.opacity(0.15)
                        }
                    } else {
                        Color.clear
                    }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
    }
}

// MARK: - View Extension

extension View {
    /// Applies standard row styling for multi-select lists
    /// - Parameters:
    ///   - isSelected: Whether the row is currently selected
    ///   - accentColor: The accent color for selection highlight
    ///   - onTap: Action to perform when row is tapped
    func rowStyling(isSelected: Bool, accentColor: Color, onTap: @escaping () -> Void) -> some View {
        modifier(RowStylingModifier(isSelected: isSelected, accentColor: accentColor, onTap: onTap))
    }
}

// MARK: - Preview

#Preview("Row Styling") {
    List {
        Text("Unselected Row")
            .padding()
            .rowStyling(isSelected: false, accentColor: .blue, onTap: {})

        Text("Selected Row (Task)")
            .padding()
            .rowStyling(isSelected: true, accentColor: .daisyTask, onTap: {})

        Text("Selected Row (Habit)")
            .padding()
            .rowStyling(isSelected: true, accentColor: .daisyHabit, onTap: {})
    }
    .listStyle(.plain)
}
