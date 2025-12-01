//
//  DatePickerSheet.swift
//  DaisyDos
//
//  Created by Claude Code on 11/4/25.
//  Reusable date picker sheet component
//

import SwiftUI

/// A sheet-based date picker with quick date shortcuts
struct DatePickerSheet: View {
    @Binding var selectedDate: Date?
    @Binding var hasDate: Bool
    let accentColor: Color

    @Environment(\.dismiss) private var dismiss

    @State private var workingDate: Date
    @State private var includeTime: Bool = false

    init(
        selectedDate: Binding<Date?>,
        hasDate: Binding<Bool>,
        accentColor: Color = .daisyTask
    ) {
        self._selectedDate = selectedDate
        self._hasDate = hasDate
        self.accentColor = accentColor

        // Initialize working date
        if let date = selectedDate.wrappedValue {
            self._workingDate = State(initialValue: date)
            // Check if the date has a time component (not midnight)
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: date)
            self._includeTime = State(initialValue: components.hour != 0 || components.minute != 0)
        } else {
            self._workingDate = State(initialValue: Date())
            self._includeTime = State(initialValue: false)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // None option
                Button(action: {
                    hasDate = false
                    selectedDate = nil
                    dismiss()
                }) {
                    HStack {
                        Text("None")
                            .foregroundColor(.daisyText)

                        Spacer()

                        if !hasDate {
                            Image(systemName: "checkmark")
                                .foregroundColor(accentColor)
                                .font(.body.weight(.semibold))
                        }
                    }
                    .padding()
                    .background(Color.daisySurface)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, Spacing.medium)
                }
                .buttonStyle(.plain)

                Divider()
                    .padding(.vertical, Spacing.small)

                // Graphical Date Picker
                VStack(spacing: Spacing.small) {
                    Text("Select Date")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.daisyTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    DatePicker(
                        "Select date",
                        selection: $workingDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)
                    .tint(accentColor)
                }

                Divider()
                    .padding(.top, Spacing.small)

                // Time of Day Toggle and Picker
                VStack(spacing: Spacing.small) {
                    Toggle(isOn: $includeTime) {
                        HStack(spacing: Spacing.small) {
                            Image(systemName: includeTime ? "clock.fill" : "clock")
                                .foregroundColor(includeTime ? accentColor : .daisyTextSecondary)
                                .font(.body)

                            Text("Include Time")
                                .font(.body.weight(.medium))
                                .foregroundColor(.daisyText)
                        }
                    }
                    .tint(accentColor)
                    .padding()
                    .background(Color.daisySurface)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .onChange(of: includeTime) { _, newValue in
                        if !newValue {
                            // Reset time to start of day when toggled off
                            workingDate = Calendar.current.startOfDay(for: workingDate)
                        } else {
                            // Set time to current time when toggled on
                            let calendar = Calendar.current
                            let timeComponents = calendar.dateComponents([.hour, .minute], from: Date())
                            if let newDate = calendar.date(bySettingHour: timeComponents.hour ?? 9, minute: timeComponents.minute ?? 0, second: 0, of: workingDate) {
                                workingDate = newDate
                            }
                        }
                    }

                    // Time Picker (when enabled)
                    if includeTime {
                        DatePicker(
                            "Time",
                            selection: $workingDate,
                            displayedComponents: [.hourAndMinute]
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding(.horizontal)
                        .scaleEffect(0.95)
                        .frame(height: 130)
                        .clipped()
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                    }
                }
                .padding(.bottom, Spacing.medium)

                Spacer()
            }
            .background(Color.daisyBackground)
            .navigationTitle("Set Due Date")
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
                        // If time is not included, ensure date is set to start of day (midnight)
                        if includeTime {
                            selectedDate = workingDate
                        } else {
                            selectedDate = Calendar.current.startOfDay(for: workingDate)
                        }
                        hasDate = true
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
    @Previewable @State var date: Date? = nil
    @Previewable @State var hasDate = false

    return DatePickerSheet(
        selectedDate: $date,
        hasDate: $hasDate,
        accentColor: .daisyTask
    )
}
