//
//  RecurrenceRulePickerView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//  Redesigned with minimal, modern card-based UI (Option 3)
//

import SwiftUI

struct RecurrenceRulePickerView: View {
    @Binding var recurrenceRule: RecurrenceRule?
    @Environment(\.dismiss) private var dismiss

    @State private var frequency: RecurrenceRule.Frequency = .daily
    @State private var selectedDaysOfWeek: Set<Int> = []
    @State private var dayOfMonth: Int = 1
    @State private var customDayInterval: Int = 1
    @State private var isCustomInterval: Bool = false

    // Quick preset options
    enum QuickPreset: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
        case custom = "Custom"

        var icon: String {
            switch self {
            case .daily: return "repeat.circle"
            case .weekly: return "calendar.circle"
            case .monthly: return "calendar.badge.clock"
            case .yearly: return "calendar.badge.plus"
            case .custom: return "number.circle"
            }
        }

        var frequency: RecurrenceRule.Frequency? {
            switch self {
            case .daily: return .daily
            case .weekly: return .weekly
            case .monthly: return .monthly
            case .yearly: return .yearly
            case .custom: return nil // Custom doesn't have a preset frequency
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    // MARK: - Quick Presets
                    HStack(spacing: 4) {
                        ForEach(QuickPreset.allCases, id: \.self) { preset in
                            QuickPresetButton(
                                preset: preset,
                                isSelected: (preset == .custom && isCustomInterval) || (preset != .custom && frequency == preset.frequency && !hasCustomSettings && !isCustomInterval),
                                accentColor: .daisyTask
                            ) {
                                if preset == .custom {
                                    isCustomInterval = true
                                    frequency = .daily // Default to daily for custom
                                } else {
                                    isCustomInterval = false
                                    if let freq = preset.frequency {
                                        frequency = freq
                                    }
                                    // Reset custom settings when selecting preset
                                    selectedDaysOfWeek = []
                                    customDayInterval = 1
                                    if frequency == .monthly {
                                        dayOfMonth = Calendar.current.component(.day, from: Date())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, Spacing.small)

                    // MARK: - Custom Day Interval (when Custom is selected)
                    if isCustomInterval {
                        customIntervalPicker
                    }

                    // MARK: - Frequency-Specific Options
                    if !isCustomInterval && frequency == .weekly {
                        weekdayPicker
                    } else if !isCustomInterval && frequency == .monthly {
                        monthDayPicker
                    }
                }
                .padding(.vertical)
            }
            .background(Color.daisyBackground)
            .navigationTitle("Set Recurrence")
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
                        saveRecurrenceRule()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.daisyTask)
                }
            }
            .onAppear {
                initializeFromExistingRule()
            }
        }
    }

    // MARK: - Weekday Picker (for Weekly)

    @ViewBuilder
    private var weekdayPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { weekday in
                    let isSelected = selectedDaysOfWeek.contains(weekday)
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if isSelected {
                                selectedDaysOfWeek.remove(weekday)
                            } else {
                                selectedDaysOfWeek.insert(weekday)
                            }
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(Calendar.current.veryShortWeekdaySymbols[weekday - 1])
                                .font(.caption.weight(isSelected ? .semibold : .medium))
                                .foregroundColor(isSelected ? .white : .daisyText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? Color.daisyTask : Color.daisySurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? Color.clear : Color.daisyTask.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            if selectedDaysOfWeek.isEmpty {
                Text("Select at least one day")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, Spacing.small)
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Month Day Picker (for Monthly)

    @ViewBuilder
    private var monthDayPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("Repeat every")
                    .font(.body)
                    .foregroundColor(.daisyText)

                Spacer()

                Picker("Day of Month", selection: $dayOfMonth) {
                    ForEach(1...31, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 180)
                .clipped()

                Text("month")
                    .font(.body)
                    .foregroundColor(.daisyText)
            }
            .padding(.horizontal)
        }
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Custom Interval Picker

    @ViewBuilder
    private var customIntervalPicker: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("Repeat every")
                    .font(.body)
                    .foregroundColor(.daisyText)

                Spacer()

                Picker("Days", selection: $customDayInterval) {
                    ForEach(1...365, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 180)
                .clipped()

                Text(customDayInterval == 1 ? "day" : "days")
                    .font(.body)
                    .foregroundColor(.daisyText)
            }
            .padding(.horizontal)
        }
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Helper Properties

    private var hasCustomSettings: Bool {
        switch frequency {
        case .weekly:
            return !selectedDaysOfWeek.isEmpty
        case .monthly:
            return dayOfMonth != Calendar.current.component(.day, from: Date())
        default:
            return false
        }
    }

    // MARK: - Helper Methods

    private func initializeFromExistingRule() {
        guard let existingRule = recurrenceRule else { return }

        frequency = existingRule.frequency
        selectedDaysOfWeek = existingRule.daysOfWeek ?? []
        dayOfMonth = existingRule.dayOfMonth ?? Calendar.current.component(.day, from: Date())
    }

    private func resetFrequencyOptions() {
        selectedDaysOfWeek = []
        if frequency == .monthly {
            dayOfMonth = Calendar.current.component(.day, from: Date())
        }
    }

    private func saveRecurrenceRule() {
        var daysOfWeek: Set<Int>? = nil
        var dayOfMonth: Int? = nil
        var interval = 1

        // Handle custom interval (every X days)
        if isCustomInterval {
            interval = customDayInterval
        } else {
            switch frequency {
            case .weekly:
                // If no days selected, default to current weekday
                if selectedDaysOfWeek.isEmpty {
                    daysOfWeek = [Calendar.current.component(.weekday, from: Date())]
                } else {
                    daysOfWeek = selectedDaysOfWeek
                }
            case .monthly:
                dayOfMonth = self.dayOfMonth
            default:
                break
            }
        }

        recurrenceRule = RecurrenceRule(
            frequency: frequency,
            interval: interval,
            daysOfWeek: daysOfWeek,
            dayOfMonth: dayOfMonth,
            endDate: nil, // No end date in simplified version
            maxOccurrences: nil, // No max occurrences in simplified version
            repeatMode: .fromOriginalDate // Always from original date
        )
    }
}

// MARK: - Quick Preset Button

private struct QuickPresetButton: View {
    let preset: RecurrenceRulePickerView.QuickPreset
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: preset.icon)
                    .font(.body)
                    .foregroundColor(isSelected ? accentColor : .daisyTextSecondary)

                Text(preset.rawValue)
                    .font(.caption2.weight(isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .daisyText : .daisyTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? accentColor.opacity(0.15) : Color.daisySurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RecurrenceRulePickerView(recurrenceRule: .constant(nil))
}
