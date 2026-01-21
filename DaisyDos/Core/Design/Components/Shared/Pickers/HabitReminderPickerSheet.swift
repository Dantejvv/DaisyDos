//
//  HabitReminderPickerSheet.swift
//  DaisyDos
//
//  Created by Claude Code on 1/21/26.
//  Combined picker for habit reminders: scheduled time + relative offset
//

import SwiftUI

/// Sheet for setting habit reminders with scheduled time and relative offset
/// Habits always use relative reminders (offset from scheduled time)
struct HabitReminderPickerSheet: View {
    @Binding var reminderOffset: TimeInterval?
    @Binding var scheduledTimeHour: Int?
    @Binding var scheduledTimeMinute: Int?

    let accentColor: Color

    @Environment(\.dismiss) private var dismiss

    @State private var hasReminder: Bool
    @State private var selectedOffset: ReminderOffset
    @State private var workingDate: Date

    init(
        reminderOffset: Binding<TimeInterval?>,
        scheduledTimeHour: Binding<Int?>,
        scheduledTimeMinute: Binding<Int?>,
        accentColor: Color = .daisyHabit
    ) {
        self._reminderOffset = reminderOffset
        self._scheduledTimeHour = scheduledTimeHour
        self._scheduledTimeMinute = scheduledTimeMinute
        self.accentColor = accentColor

        // Determine if there's an existing reminder
        let hasExisting = reminderOffset.wrappedValue != nil
        self._hasReminder = State(initialValue: hasExisting)

        // Initialize selected offset
        if let offset = reminderOffset.wrappedValue,
           let preset = ReminderOffset.from(timeInterval: offset) {
            self._selectedOffset = State(initialValue: preset)
        } else {
            self._selectedOffset = State(initialValue: .fifteenMinutesBefore)
        }

        // Create a date from the hour/minute components, or default to 9:00 AM
        var components = DateComponents()
        components.hour = scheduledTimeHour.wrappedValue ?? 9
        components.minute = scheduledTimeMinute.wrappedValue ?? 0

        let defaultDate = Calendar.current.date(from: components) ?? Date()
        self._workingDate = State(initialValue: defaultDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    // Info section
                    infoSection

                    // No reminder option
                    noneOption

                    // Reminder enabled section
                    if hasReminder {
                        // Scheduled time section
                        scheduledTimeSection

                        // Reminder offset section
                        offsetSection
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

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Image(systemName: "info.circle")
                    .foregroundColor(accentColor)
                Text("About Habit Reminders")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)
            }

            Text("Set a scheduled time for your habit, then choose when to be reminded relative to that time.")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding(.horizontal)
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

    // MARK: - Scheduled Time Section

    private var scheduledTimeSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(accentColor)
                Text("Scheduled Time")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)
                Spacer()
                Text(formattedTime)
                    .font(.subheadline)
                    .foregroundColor(accentColor)
            }
            .padding(.horizontal)
            .padding(.top, Spacing.small)

            DatePicker(
                "Time",
                selection: $workingDate,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .tint(accentColor)
        }
        .padding(.vertical, Spacing.small)
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Offset Section

    private var offsetSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(accentColor)
                Text("Remind Me")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)
            }
            .padding(.horizontal)
            .padding(.top, Spacing.small)

            VStack(spacing: 0) {
                ForEach(ReminderOffset.allCases) { offset in
                    Button(action: {
                        selectedOffset = offset
                    }) {
                        HStack {
                            Image(systemName: offset.symbolName)
                                .font(.body)
                                .foregroundColor(selectedOffset == offset ? accentColor : .daisyTextSecondary)
                                .frame(width: 24)

                            Text(offset.displayName)
                                .foregroundColor(.daisyText)

                            Spacer()

                            if selectedOffset == offset {
                                Image(systemName: "checkmark")
                                    .foregroundColor(accentColor)
                                    .font(.body.weight(.semibold))
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .background(selectedOffset == offset ? accentColor.opacity(0.08) : Color.clear)
                    }
                    .buttonStyle(.plain)

                    if offset != ReminderOffset.allCases.last {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
        }
        .padding(.bottom, Spacing.small)
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: workingDate)
    }

    private func saveAndDismiss() {
        if hasReminder {
            // Save scheduled time
            let components = Calendar.current.dateComponents([.hour, .minute], from: workingDate)
            scheduledTimeHour = components.hour
            scheduledTimeMinute = components.minute

            // Save reminder offset
            reminderOffset = selectedOffset.rawValue
        } else {
            // Clear all reminder data
            reminderOffset = nil
            scheduledTimeHour = nil
            scheduledTimeMinute = nil
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview("No Reminder") {
    @Previewable @State var offset: TimeInterval? = nil
    @Previewable @State var hour: Int? = nil
    @Previewable @State var minute: Int? = nil

    return HabitReminderPickerSheet(
        reminderOffset: $offset,
        scheduledTimeHour: $hour,
        scheduledTimeMinute: $minute,
        accentColor: .daisyHabit
    )
}

#Preview("With Reminder") {
    @Previewable @State var offset: TimeInterval? = -900
    @Previewable @State var hour: Int? = 9
    @Previewable @State var minute: Int? = 0

    return HabitReminderPickerSheet(
        reminderOffset: $offset,
        scheduledTimeHour: $hour,
        scheduledTimeMinute: $minute,
        accentColor: .daisyHabit
    )
}
