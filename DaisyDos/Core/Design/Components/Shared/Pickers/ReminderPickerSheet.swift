//
//  ReminderPickerSheet.swift
//  DaisyDos
//
//  Created by Claude Code on 1/6/26.
//  Reminder picker that supports both absolute and time-of-day reminders
//
//  When recurrence is NOT set: Shows date/time picker for absolute reminders
//  When recurrence IS set: Shows time-of-day picker for alert time
//

import SwiftUI

/// Sheet-based reminder picker with conditional UI based on recurrence
/// - Non-recurring items: Absolute date/time picker
/// - Recurring items: Time-of-day picker for alert time
struct ReminderPickerSheet: View {
    // For non-recurring items (absolute reminder)
    @Binding var reminderDate: Date?

    // For recurring items (alert time)
    @Binding var alertTimeHour: Int?
    @Binding var alertTimeMinute: Int?

    /// Whether the item has a recurrence rule set
    let hasRecurrence: Bool

    let accentColor: Color

    @Environment(\.dismiss) private var dismiss

    // Absolute mode state
    @State private var workingDate: Date
    @State private var hasAbsoluteReminder: Bool

    // Alert time mode state
    @State private var hasAlertTime: Bool
    @State private var alertTime: Date

    /// Initializer for items that may or may not have recurrence
    init(
        reminderDate: Binding<Date?>,
        alertTimeHour: Binding<Int?>,
        alertTimeMinute: Binding<Int?>,
        hasRecurrence: Bool,
        accentColor: Color = .daisyTask
    ) {
        self._reminderDate = reminderDate
        self._alertTimeHour = alertTimeHour
        self._alertTimeMinute = alertTimeMinute
        self.hasRecurrence = hasRecurrence
        self.accentColor = accentColor

        // Absolute mode setup
        let hasValue = reminderDate.wrappedValue != nil
        self._hasAbsoluteReminder = State(initialValue: hasValue)
        self._workingDate = State(initialValue: reminderDate.wrappedValue ?? Date())

        // Alert time mode setup
        let hasAlert = alertTimeHour.wrappedValue != nil
        self._hasAlertTime = State(initialValue: hasAlert)

        // Create alert time Date from hour/minute or default to 9:00 AM
        var components = DateComponents()
        components.hour = alertTimeHour.wrappedValue ?? 9
        components.minute = alertTimeMinute.wrappedValue ?? 0
        let defaultTime = Calendar.current.date(from: components) ?? Date()
        self._alertTime = State(initialValue: defaultTime)
    }

    /// Convenience initializer for non-recurring items (backward compatible)
    init(
        reminderDate: Binding<Date?>,
        accentColor: Color = .daisyTask
    ) {
        self._reminderDate = reminderDate
        self._alertTimeHour = .constant(nil)
        self._alertTimeMinute = .constant(nil)
        self.hasRecurrence = false
        self.accentColor = accentColor

        let hasValue = reminderDate.wrappedValue != nil
        self._hasAbsoluteReminder = State(initialValue: hasValue)
        self._workingDate = State(initialValue: reminderDate.wrappedValue ?? Date())
        self._hasAlertTime = State(initialValue: false)
        self._alertTime = State(initialValue: Date())
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
            // Save alert time
            if hasAlertTime {
                let components = Calendar.current.dateComponents([.hour, .minute], from: alertTime)
                alertTimeHour = components.hour
                alertTimeMinute = components.minute
            } else {
                alertTimeHour = nil
                alertTimeMinute = nil
            }
            // Clear absolute reminder when switching to recurring
            reminderDate = nil
        } else {
            // Save absolute date
            if hasAbsoluteReminder {
                reminderDate = workingDate
            } else {
                reminderDate = nil
            }
            // Clear alert time when non-recurring
            alertTimeHour = nil
            alertTimeMinute = nil
        }
        dismiss()
    }

    // MARK: - Alert Time Content (for recurring items)

    private var relativeReminderContent: some View {
        VStack(spacing: Spacing.medium) {
            // No Alert option
            alertOptionRow(hasAlert: false, title: "No Alert", symbolName: "bell.slash")

            // Alert at time option
            alertOptionRow(hasAlert: true, title: "Alert at time", symbolName: "bell.badge")

            // Time picker (shown when alert is enabled)
            if hasAlertTime {
                alertTimePicker
            }
        }
    }

    private func alertOptionRow(hasAlert: Bool, title: String, symbolName: String) -> some View {
        let isSelected = hasAlertTime == hasAlert

        return Button(action: {
            hasAlertTime = hasAlert
        }) {
            HStack {
                Image(systemName: symbolName)
                    .font(.body)
                    .foregroundColor(isSelected ? accentColor : .daisyTextSecondary)
                    .frame(width: 24)

                Text(title)
                    .foregroundColor(.daisyText)

                Spacer()

                if isSelected && hasAlert {
                    Text(formattedAlertTime)
                        .font(.caption)
                        .foregroundColor(accentColor)
                }

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

    private var alertTimePicker: some View {
        VStack(spacing: 0) {
            DatePicker(
                "Alert Time",
                selection: $alertTime,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .tint(accentColor)
        }
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var formattedAlertTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: alertTime)
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
    @Previewable @State var alertHour: Int? = nil
    @Previewable @State var alertMinute: Int? = nil

    return ReminderPickerSheet(
        reminderDate: $reminder,
        alertTimeHour: $alertHour,
        alertTimeMinute: $alertMinute,
        hasRecurrence: false,
        accentColor: .daisyTask
    )
}

#Preview("Recurring (Alert Time)") {
    @Previewable @State var reminder: Date? = nil
    @Previewable @State var alertHour: Int? = 9
    @Previewable @State var alertMinute: Int? = 0

    return ReminderPickerSheet(
        reminderDate: $reminder,
        alertTimeHour: $alertHour,
        alertTimeMinute: $alertMinute,
        hasRecurrence: true,
        accentColor: .daisyHabit
    )
}
