//
//  ReminderPickerSheet.swift
//  DaisyDos
//
//  Created by Claude Code on 1/6/26.
//  Reminder picker that supports both absolute and relative reminders
//
//  When recurrence is NOT set: Shows date/time picker for absolute reminders
//  When recurrence IS set: Shows preset offset options for relative reminders
//

import SwiftUI

/// Sheet-based reminder picker with conditional UI based on recurrence
/// - Non-recurring items: Absolute date/time picker
/// - Recurring items: Relative offset preset list
struct ReminderPickerSheet: View {
    // For non-recurring items (absolute reminder)
    @Binding var reminderDate: Date?

    // For recurring items (relative reminder)
    @Binding var reminderOffset: TimeInterval?

    /// Whether the item has a recurrence rule set
    let hasRecurrence: Bool

    let accentColor: Color

    @Environment(\.dismiss) private var dismiss

    // Absolute mode state
    @State private var workingDate: Date
    @State private var hasAbsoluteReminder: Bool

    // Relative mode state
    @State private var selectedOffset: ReminderOffset?

    /// Initializer for items that may or may not have recurrence
    init(
        reminderDate: Binding<Date?>,
        reminderOffset: Binding<TimeInterval?>,
        hasRecurrence: Bool,
        accentColor: Color = .daisyTask
    ) {
        self._reminderDate = reminderDate
        self._reminderOffset = reminderOffset
        self.hasRecurrence = hasRecurrence
        self.accentColor = accentColor

        // Absolute mode setup
        let hasValue = reminderDate.wrappedValue != nil
        self._hasAbsoluteReminder = State(initialValue: hasValue)
        self._workingDate = State(initialValue: reminderDate.wrappedValue ?? Date())

        // Relative mode setup
        self._selectedOffset = State(initialValue: ReminderOffset.from(timeInterval: reminderOffset.wrappedValue))
    }

    /// Convenience initializer for non-recurring items (backward compatible)
    init(
        reminderDate: Binding<Date?>,
        accentColor: Color = .daisyTask
    ) {
        self._reminderDate = reminderDate
        self._reminderOffset = .constant(nil)
        self.hasRecurrence = false
        self.accentColor = accentColor

        let hasValue = reminderDate.wrappedValue != nil
        self._hasAbsoluteReminder = State(initialValue: hasValue)
        self._workingDate = State(initialValue: reminderDate.wrappedValue ?? Date())
        self._selectedOffset = State(initialValue: nil)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    if hasRecurrence {
                        relativeReminderContent
                    } else {
                        absoluteReminderContent
                    }
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
                        saveAndDismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(accentColor)
                }
            }
        }
    }

    // MARK: - Save Logic

    private func saveAndDismiss() {
        if hasRecurrence {
            // Save relative offset
            reminderOffset = selectedOffset?.rawValue
            // Clear absolute reminder when switching to recurring
            reminderDate = nil
        } else {
            // Save absolute date
            if hasAbsoluteReminder {
                reminderDate = workingDate
            } else {
                reminderDate = nil
            }
            // Clear relative offset when non-recurring
            reminderOffset = nil
        }
        dismiss()
    }

    // MARK: - Relative Reminder Content (for recurring items)

    private var relativeReminderContent: some View {
        VStack(spacing: Spacing.small) {
            // No Reminder option
            relativeOptionRow(
                offset: nil,
                title: "No Reminder",
                symbolName: "bell.slash"
            )

            // Preset offset options
            ForEach(ReminderOffset.allCases) { offset in
                relativeOptionRow(
                    offset: offset,
                    title: offset.displayName,
                    symbolName: offset.symbolName
                )
            }
        }
    }

    private func relativeOptionRow(offset: ReminderOffset?, title: String, symbolName: String) -> some View {
        let isSelected = selectedOffset == offset

        return Button(action: {
            selectedOffset = offset
        }) {
            HStack {
                Image(systemName: symbolName)
                    .font(.body)
                    .foregroundColor(isSelected ? accentColor : .daisyTextSecondary)
                    .frame(width: 24)

                Text(title)
                    .foregroundColor(.daisyText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(accentColor)
                        .font(.body.weight(.semibold))
                }
            }
            .padding()
            .background(isSelected ? accentColor.opacity(0.08) : Color.daisySurface)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Absolute Reminder Content (for non-recurring items)

    private var absoluteReminderContent: some View {
        VStack(spacing: Spacing.medium) {
            // None option
            noneOption

            // Date & Time option
            dateTimeOption

            // Date/Time picker
            dateTimeSection
        }
    }

    private var noneOption: some View {
        Button(action: {
            hasAbsoluteReminder = false
        }) {
            HStack {
                Image(systemName: "bell.slash")
                    .font(.body)
                    .foregroundColor(!hasAbsoluteReminder ? accentColor : .daisyTextSecondary)

                Text("No Reminder")
                    .foregroundColor(.daisyText)

                Spacer()

                if !hasAbsoluteReminder {
                    Image(systemName: "checkmark")
                        .foregroundColor(accentColor)
                        .font(.body.weight(.semibold))
                }
            }
            .padding()
            .background(!hasAbsoluteReminder ? accentColor.opacity(0.08) : Color.daisySurface)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    private var dateTimeOption: some View {
        Button(action: {
            hasAbsoluteReminder = true
        }) {
            HStack {
                Image(systemName: "bell.badge")
                    .font(.body)
                    .foregroundColor(hasAbsoluteReminder ? accentColor : .daisyTextSecondary)

                Text("Date & Time")
                    .foregroundColor(.daisyText)

                Spacer()

                if hasAbsoluteReminder {
                    Text(formattedWorkingDate)
                        .font(.caption)
                        .foregroundColor(accentColor)

                    Image(systemName: "checkmark")
                        .foregroundColor(accentColor)
                        .font(.body.weight(.semibold))
                }
            }
            .padding()
            .background(hasAbsoluteReminder ? accentColor.opacity(0.08) : Color.daisySurface)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
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
                    hasAbsoluteReminder = true
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
                        hasAbsoluteReminder = true
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

#Preview("Non-recurring (Absolute)") {
    @Previewable @State var reminder: Date? = nil
    @Previewable @State var offset: TimeInterval? = nil

    return ReminderPickerSheet(
        reminderDate: $reminder,
        reminderOffset: $offset,
        hasRecurrence: false,
        accentColor: .daisyTask
    )
}

#Preview("Recurring (Relative)") {
    @Previewable @State var reminder: Date? = nil
    @Previewable @State var offset: TimeInterval? = ReminderOffset.fifteenMinutesBefore.rawValue

    return ReminderPickerSheet(
        reminderDate: $reminder,
        reminderOffset: $offset,
        hasRecurrence: true,
        accentColor: .daisyHabit
    )
}
