//
//  HabitReminderPickerSheet.swift
//  DaisyDos
//
//  Created by Claude Code on 1/21/26.
//  Simplified picker for habit alert time (time-of-day)
//

import SwiftUI

/// Sheet for setting habit alert time
/// Habits always use time-of-day alerts (no relative offsets)
struct HabitReminderPickerSheet: View {
    @Binding var alertTimeHour: Int?
    @Binding var alertTimeMinute: Int?

    let accentColor: Color

    @Environment(\.dismiss) private var dismiss

    @State private var hasAlert: Bool
    @State private var workingDate: Date

    init(
        alertTimeHour: Binding<Int?>,
        alertTimeMinute: Binding<Int?>,
        accentColor: Color = .daisyHabit
    ) {
        self._alertTimeHour = alertTimeHour
        self._alertTimeMinute = alertTimeMinute
        self.accentColor = accentColor

        // Determine if there's an existing alert time
        let hasExisting = alertTimeHour.wrappedValue != nil
        self._hasAlert = State(initialValue: hasExisting)

        // Create a date from the hour/minute components, or default to 9:00 AM
        var components = DateComponents()
        components.hour = alertTimeHour.wrappedValue ?? 9
        components.minute = alertTimeMinute.wrappedValue ?? 0

        let defaultDate = Calendar.current.date(from: components) ?? Date()
        self._workingDate = State(initialValue: defaultDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    // Info section
                    infoSection

                    // No alert option
                    noneOption

                    // Alert at time option (always visible)
                    alertAtTimeOption

                    // Time picker (only shown when alert is enabled)
                    if hasAlert {
                        timePickerSection
                    }
                }
                .padding(.vertical, Spacing.medium)
            }
            .background(Color.daisyBackground)
            .navigationTitle("Alert")
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
                Text("About Habit Alerts")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)
            }

            Text("Set a time of day when you'd like to be reminded about this habit.")
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
            hasAlert = false
        }) {
            HStack {
                Image(systemName: "bell.slash")
                    .font(.body)
                    .foregroundColor(!hasAlert ? accentColor : .daisyTextSecondary)

                Text("No Alert")
                    .foregroundColor(.daisyText)

                Spacer()

                if !hasAlert {
                    Image(systemName: "checkmark")
                        .foregroundColor(accentColor)
                        .font(.body.weight(.semibold))
                }
            }
            .padding()
            .background(!hasAlert ? accentColor.opacity(0.08) : Color.daisySurface)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Alert At Time Option

    private var alertAtTimeOption: some View {
        Button(action: {
            hasAlert = true
        }) {
            HStack {
                Image(systemName: "bell.badge")
                    .font(.body)
                    .foregroundColor(hasAlert ? accentColor : .daisyTextSecondary)

                Text("Alert at time")
                    .foregroundColor(.daisyText)

                Spacer()

                if hasAlert {
                    Text(formattedTime)
                        .font(.caption)
                        .foregroundColor(accentColor)

                    Image(systemName: "checkmark")
                        .foregroundColor(accentColor)
                        .font(.body.weight(.semibold))
                }
            }
            .padding()
            .background(hasAlert ? accentColor.opacity(0.08) : Color.daisySurface)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Time Picker Section

    private var timePickerSection: some View {
        VStack(spacing: 0) {
            DatePicker(
                "Time",
                selection: $workingDate,
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

    // MARK: - Helpers

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: workingDate)
    }

    private func saveAndDismiss() {
        if hasAlert {
            // Save alert time
            let components = Calendar.current.dateComponents([.hour, .minute], from: workingDate)
            alertTimeHour = components.hour
            alertTimeMinute = components.minute
        } else {
            // Clear alert time
            alertTimeHour = nil
            alertTimeMinute = nil
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview("No Alert") {
    @Previewable @State var hour: Int? = nil
    @Previewable @State var minute: Int? = nil

    HabitReminderPickerSheet(
        alertTimeHour: $hour,
        alertTimeMinute: $minute,
        accentColor: .daisyHabit
    )
}

#Preview("With Alert") {
    @Previewable @State var hour: Int? = 9
    @Previewable @State var minute: Int? = 0

    HabitReminderPickerSheet(
        alertTimeHour: $hour,
        alertTimeMinute: $minute,
        accentColor: .daisyHabit
    )
}
