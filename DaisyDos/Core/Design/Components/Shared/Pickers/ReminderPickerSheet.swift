//
//  ReminderPickerSheet.swift
//  DaisyDos
//
//  Created by Claude Code on 1/6/26.
//  Absolute date/time reminder picker for task notifications
//

import SwiftUI

/// Sheet-based reminder picker with date and time selection
struct ReminderPickerSheet: View {
    @Binding var reminderDate: Date?
    let accentColor: Color

    @Environment(\.dismiss) private var dismiss

    @State private var workingDate: Date
    @State private var hasReminder: Bool

    init(
        reminderDate: Binding<Date?>,
        accentColor: Color = .daisyTask
    ) {
        self._reminderDate = reminderDate
        self.accentColor = accentColor

        let hasValue = reminderDate.wrappedValue != nil
        self._hasReminder = State(initialValue: hasValue)
        // Default to 1 hour from now if no existing reminder
        self._workingDate = State(initialValue: reminderDate.wrappedValue ?? Date().addingTimeInterval(3600))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    // None option
                    noneOption

                    // Date/Time picker
                    dateTimeSection
                }
                .padding(.vertical, Spacing.medium)
            }
            .background(Color.daisyBackground)
            .navigationTitle("Reminder")
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
                        if hasReminder {
                            reminderDate = workingDate
                        } else {
                            reminderDate = nil
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(accentColor)
                }
            }
        }
    }

    // MARK: - None Option

    private var noneOption: some View {
        Button(action: {
            hasReminder = false
        }) {
            HStack {
                Image(systemName: "bell.slash")
                    .font(.body)
                    .foregroundColor(!hasReminder ? accentColor : .daisyTextSecondary)

                Text("No Reminder")
                    .foregroundColor(.daisyText)

                Spacer()

                if !hasReminder {
                    Image(systemName: "checkmark")
                        .foregroundColor(accentColor)
                        .font(.body.weight(.semibold))
                }
            }
            .padding()
            .background(!hasReminder ? accentColor.opacity(0.08) : Color.daisySurface)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date/Time Section

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // Header with selected state
            HStack {
                Text("Date & Time")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.daisyTextSecondary)

                Spacer()

                if hasReminder {
                    Text(formattedWorkingDate)
                        .font(.caption.weight(.medium))
                        .foregroundColor(accentColor)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                // Date picker
                DatePicker(
                    "Date",
                    selection: $workingDate,
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                .tint(accentColor)
                .onChange(of: workingDate) { _, _ in
                    hasReminder = true
                }

                Divider()
                    .padding(.horizontal)

                // Time picker
                HStack {
                    Text("Time")
                        .font(.body)
                        .foregroundColor(.daisyText)

                    Spacer()

                    DatePicker(
                        "Time",
                        selection: $workingDate,
                        displayedComponents: [.hourAndMinute]
                    )
                    .labelsHidden()
                    .tint(accentColor)
                    .onChange(of: workingDate) { _, _ in
                        hasReminder = true
                    }
                }
                .padding()
            }
            .background(Color.daisySurface)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var formattedWorkingDate: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current

        if calendar.isDateInToday(workingDate) {
            formatter.dateFormat = "'Today' h:mm a"
        } else if calendar.isDateInTomorrow(workingDate) {
            formatter.dateFormat = "'Tomorrow' h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }

        return formatter.string(from: workingDate)
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var reminder: Date? = nil

    return ReminderPickerSheet(
        reminderDate: $reminder,
        accentColor: .daisyTask
    )
}
