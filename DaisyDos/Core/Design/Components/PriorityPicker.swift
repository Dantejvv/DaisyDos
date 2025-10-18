//
//  PriorityPicker.swift
//  DaisyDos
//
//  Created by Claude Code on 10/17/25.
//  Reusable priority selection component for Tasks and Habits
//

import SwiftUI

/// A horizontal priority picker with visual indicators
struct PriorityPicker: View {
    @Binding var priority: Priority
    let accentColor: Color

    init(
        priority: Binding<Priority>,
        accentColor: Color = .daisyTask
    ) {
        self._priority = priority
        self.accentColor = accentColor
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Priority.allCases, id: \.self) { priorityOption in
                Button(action: {
                    priority = priorityOption
                }) {
                    VStack(spacing: 4) {
                        // Fixed height for icon area to ensure consistent button sizes
                        Group {
                            if priorityOption.sfSymbol != nil {
                                priorityOption.indicatorView()
                                    .font(.caption)
                            } else {
                                Color.clear
                                    .frame(width: 1, height: 1)
                            }
                        }
                        .frame(height: 16)

                        Text(priorityOption.rawValue)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(priority == priorityOption ? accentColor.opacity(0.2) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(accentColor, lineWidth: priority == priorityOption ? 2 : 0.5)
                    )
                }
                .buttonStyle(.plain)
                .foregroundColor(priority == priorityOption ? accentColor : .daisyText)
                .accessibilityLabel(priorityOption.accessibilityLabel)
            }
        }
        .padding(.horizontal, 4)
    }
}

#Preview("Task Priority") {
    Form {
        Section("Priority") {
            PriorityPicker(
                priority: .constant(.medium),
                accentColor: .daisyTask
            )
        }
    }
}

#Preview("Habit Priority") {
    Form {
        Section("Priority") {
            PriorityPicker(
                priority: .constant(.high),
                accentColor: .daisyHabit
            )
        }
    }
}
