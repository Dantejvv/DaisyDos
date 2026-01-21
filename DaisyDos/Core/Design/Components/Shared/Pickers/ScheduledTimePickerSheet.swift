//
//  ScheduledTimePickerSheet.swift
//  DaisyDos
//
//  Created by Claude Code on 1/19/26.
//  Time picker for setting the scheduled time of recurring habits
//

import SwiftUI

/// Sheet-based time picker for setting the scheduled time of a recurring habit
/// The scheduled time is the reference point for relative reminder offsets
struct ScheduledTimePickerSheet: View {
    @Binding var scheduledTimeHour: Int?
    @Binding var scheduledTimeMinute: Int?

    let accentColor: Color

    @Environment(\.dismiss) private var dismiss

    @State private var hasScheduledTime: Bool
    @State private var workingDate: Date

    init(
        scheduledTimeHour: Binding<Int?>,
        scheduledTimeMinute: Binding<Int?>,
        accentColor: Color = .daisyHabit
    ) {
        self._scheduledTimeHour = scheduledTimeHour
        self._scheduledTimeMinute = scheduledTimeMinute
        self.accentColor = accentColor

        // Determine if there's an existing scheduled time
        let hasExisting = scheduledTimeHour.wrappedValue != nil && scheduledTimeMinute.wrappedValue != nil
        self._hasScheduledTime = State(initialValue: hasExisting)

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
                    // Info text
                    infoSection

                    // No scheduled time option
                    noneOption

                    // Specific time option
                    timeOption

                    // Time picker
                    if hasScheduledTime {
                        timePickerSection
                    }
                }
                .padding(.vertical, Spacing.medium)
            }
            .background(Color.daisyBackground)
            .navigationTitle("Scheduled Time")
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
                Text("About Scheduled Time")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)
            }

            Text("Set a scheduled time for your recurring habit. This time is used as the reference point for relative reminders (e.g., \"15 minutes before\").")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Options

    private var noneOption: some View {
        Button(action: {
            hasScheduledTime = false
        }) {
            HStack {
                Image(systemName: "clock")
                    .font(.body)
                    .foregroundColor(!hasScheduledTime ? accentColor : .daisyTextSecondary)

                Text("No Scheduled Time")
                    .foregroundColor(.daisyText)

                Spacer()

                if !hasScheduledTime {
                    Image(systemName: "checkmark")
                        .foregroundColor(accentColor)
                        .font(.body.weight(.semibold))
                }
            }
            .padding()
            .background(!hasScheduledTime ? accentColor.opacity(0.08) : Color.daisySurface)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    private var timeOption: some View {
        Button(action: {
            hasScheduledTime = true
        }) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.body)
                    .foregroundColor(hasScheduledTime ? accentColor : .daisyTextSecondary)

                Text("At Specific Time")
                    .foregroundColor(.daisyText)

                Spacer()

                if hasScheduledTime {
                    Text(formattedTime)
                        .font(.caption)
                        .foregroundColor(accentColor)

                    Image(systemName: "checkmark")
                        .foregroundColor(accentColor)
                        .font(.body.weight(.semibold))
                }
            }
            .padding()
            .background(hasScheduledTime ? accentColor.opacity(0.08) : Color.daisySurface)
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Time Picker

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
            .onChange(of: workingDate) { _, _ in
                hasScheduledTime = true
            }
        }
        .padding()
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
        if hasScheduledTime {
            let components = Calendar.current.dateComponents([.hour, .minute], from: workingDate)
            scheduledTimeHour = components.hour
            scheduledTimeMinute = components.minute
        } else {
            scheduledTimeHour = nil
            scheduledTimeMinute = nil
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview("No Time Set") {
    @Previewable @State var hour: Int? = nil
    @Previewable @State var minute: Int? = nil

    return ScheduledTimePickerSheet(
        scheduledTimeHour: $hour,
        scheduledTimeMinute: $minute,
        accentColor: .daisyHabit
    )
}

#Preview("Time Set") {
    @Previewable @State var hour: Int? = 9
    @Previewable @State var minute: Int? = 0

    return ScheduledTimePickerSheet(
        scheduledTimeHour: $hour,
        scheduledTimeMinute: $minute,
        accentColor: .daisyHabit
    )
}
