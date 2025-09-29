//
//  RecurrenceToggleRow.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct RecurrenceToggleRow: View {
    @Binding var recurrenceRule: RecurrenceRule?
    @Binding var showingPicker: Bool

    private var isRecurring: Bool {
        recurrenceRule != nil
    }

    private var displayText: String {
        if let rule = recurrenceRule {
            return rule.displayDescription
        } else {
            return "None"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main toggle row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recurrence")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.daisyText)

                    Text(displayText)
                        .font(.caption)
                        .foregroundColor(isRecurring ? .daisyTask : .daisyTextSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Toggle("", isOn: .init(
                    get: { isRecurring },
                    set: { newValue in
                        if newValue {
                            showingPicker = true
                        } else {
                            recurrenceRule = nil
                        }
                    }
                ))
                .labelsHidden()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isRecurring {
                    showingPicker = true
                }
            }

            // Edit button when recurring
            if isRecurring {
                HStack {
                    Spacer()

                    Button(action: {
                        showingPicker = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.caption)

                            Text("Edit Pattern")
                                .font(.caption)
                        }
                        .foregroundColor(.daisyTask)
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Recurrence")
        .accessibilityValue(displayText)
        .accessibilityHint(isRecurring ? "Tap to edit recurrence pattern" : "Tap to add recurrence pattern")
    }
}

#Preview {
    VStack(spacing: 20) {
        // No recurrence
        RecurrenceToggleRow(
            recurrenceRule: .constant(nil),
            showingPicker: .constant(false)
        )

        // With recurrence
        RecurrenceToggleRow(
            recurrenceRule: .constant(.daily()),
            showingPicker: .constant(false)
        )

        // Complex recurrence
        RecurrenceToggleRow(
            recurrenceRule: .constant(.weekly(daysOfWeek: [2, 3, 4, 5, 6])),
            showingPicker: .constant(false)
        )
    }
    .padding()
    .background(Color.daisySurface)
}