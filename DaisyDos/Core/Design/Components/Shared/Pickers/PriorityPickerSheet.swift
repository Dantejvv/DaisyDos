//
//  PriorityPickerSheet.swift
//  DaisyDos
//
//  Created by Claude Code on 11/4/25.
//  Reusable priority picker sheet component
//

import SwiftUI

/// A sheet-based priority picker with descriptions
struct PriorityPickerSheet: View {
    @Binding var selectedPriority: Priority
    let accentColor: Color

    @Environment(\.dismiss) private var dismiss
    @Environment(AppearanceManager.self) private var appearanceManager

    @State private var workingPriority: Priority

    init(
        selectedPriority: Binding<Priority>,
        accentColor: Color = .daisyTask
    ) {
        self._selectedPriority = selectedPriority
        self.accentColor = accentColor
        self._workingPriority = State(initialValue: selectedPriority.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(Priority.allCases, id: \.self) { priority in
                    Button(action: {
                        workingPriority = priority
                    }) {
                        HStack(spacing: Spacing.medium) {
                            // Priority Icon
                            let priorityColor = priority.color(from: appearanceManager)
                            ZStack {
                                Circle()
                                    .fill(workingPriority == priority ? priorityColor.opacity(0.2) : Color.daisySurface)
                                    .frame(width: 44, height: 44)

                                if let symbol = priority.sfSymbol {
                                    Image(systemName: symbol)
                                        .font(.title3.weight(.medium))
                                        .foregroundColor(priorityColor)
                                } else {
                                    Image(systemName: "minus")
                                        .font(.title3.weight(.medium))
                                        .foregroundColor(.daisyTextSecondary)
                                }
                            }

                            // Priority Label
                            Text(priority.rawValue)
                                .font(.body.weight(workingPriority == priority ? .semibold : .regular))
                                .foregroundColor(.daisyText)

                            Spacer()

                            // Checkmark
                            if workingPriority == priority {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(priorityColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        workingPriority == priority ?
                        priority.color(from: appearanceManager).opacity(0.08) : Color.clear
                    )
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Set Priority")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.daisyTextSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedPriority = workingPriority
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(accentColor)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var priority: Priority = .medium

    return PriorityPickerSheet(
        selectedPriority: $priority,
        accentColor: .daisyTask
    )
}
