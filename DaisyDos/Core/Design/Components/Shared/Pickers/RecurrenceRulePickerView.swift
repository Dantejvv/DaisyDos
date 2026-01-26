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
    let allowsNone: Bool
    @Environment(\.dismiss) private var dismiss

    @State private var frequency: RecurrenceRule.Frequency = .daily
    @State private var isNoneSelected: Bool = false
    @State private var selectedDaysOfWeek: Set<Int> = []
    @State private var dayOfMonth: Int = 1
    @State private var customInterval: Int = 1
    @State private var isCustomInterval: Bool = false

    // Quick preset options
    enum QuickPreset: String, CaseIterable {
        case none = "None"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case custom = "Custom"

        var icon: String {
            switch self {
            case .none: return "xmark.circle"
            case .daily: return "repeat.circle"
            case .weekly: return "calendar.circle"
            case .monthly: return "calendar.badge.clock"
            case .custom: return "number.circle"
            }
        }

        var frequency: RecurrenceRule.Frequency? {
            switch self {
            case .none: return nil // No recurrence
            case .daily: return .daily
            case .weekly: return .weekly
            case .monthly: return .monthly
            case .custom: return nil // Custom doesn't have a preset frequency
            }
        }
    }

    /// Returns the presets to display based on whether None is allowed
    private var availablePresets: [QuickPreset] {
        if allowsNone {
            return QuickPreset.allCases
        } else {
            return QuickPreset.allCases.filter { $0 != .none }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    // MARK: - Quick Presets
                    HStack(spacing: 4) {
                        ForEach(availablePresets, id: \.self) { preset in
                            QuickPresetButton(
                                preset: preset,
                                isSelected: isPresetSelected(preset),
                                accentColor: .daisyTask
                            ) {
                                selectPreset(preset)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, Spacing.small)

                    // Only show additional options when recurrence is enabled
                    if !isNoneSelected {
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
                Text("On the")
                    .font(.body)
                    .foregroundColor(.daisyText)

                Spacer()

                Picker("Day of Month", selection: $dayOfMonth) {
                    ForEach(1...31, id: \.self) { day in
                        Text(ordinalString(for: day)).tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 180)
                .clipped()

                Text("of each month")
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

                Picker("Interval", selection: $customInterval) {
                    ForEach(1...365, id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 180)
                .clipped()

                Text(customInterval == 1 ? "day" : "days")
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

    /// Returns ordinal string (1st, 2nd, 3rd, etc.)
    private func ordinalString(for day: Int) -> String {
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return "\(day)\(suffix)"
    }

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

    /// Check if a preset is currently selected
    private func isPresetSelected(_ preset: QuickPreset) -> Bool {
        switch preset {
        case .none:
            return isNoneSelected
        case .custom:
            return isCustomInterval && !isNoneSelected
        default:
            return !isNoneSelected && !isCustomInterval && frequency == preset.frequency && !hasCustomSettings
        }
    }

    /// Handle preset selection
    private func selectPreset(_ preset: QuickPreset) {
        if preset == .none {
            isNoneSelected = true
            isCustomInterval = false
        } else if preset == .custom {
            isNoneSelected = false
            isCustomInterval = true
            frequency = .daily
        } else {
            isNoneSelected = false
            isCustomInterval = false
            if let freq = preset.frequency {
                frequency = freq
            }
            // Reset custom settings when selecting preset
            selectedDaysOfWeek = []
            customInterval = 1
            if frequency == .monthly {
                dayOfMonth = Calendar.current.component(.day, from: Date())
            }
        }
    }

    // MARK: - Helper Methods

    private func initializeFromExistingRule() {
        guard let existingRule = recurrenceRule else {
            // If no existing rule and None is allowed, select None
            if allowsNone {
                isNoneSelected = true
            }
            return
        }

        isNoneSelected = false
        frequency = existingRule.frequency
        selectedDaysOfWeek = existingRule.daysOfWeek ?? []
        dayOfMonth = existingRule.dayOfMonth ?? Calendar.current.component(.day, from: Date())

        // Handle custom intervals (daily with interval > 1)
        if existingRule.interval > 1 && existingRule.frequency == .daily {
            isCustomInterval = true
            customInterval = existingRule.interval
        }
    }

    private func resetFrequencyOptions() {
        selectedDaysOfWeek = []
        if frequency == .monthly {
            dayOfMonth = Calendar.current.component(.day, from: Date())
        }
    }

    private func saveRecurrenceRule() {
        // If "None" is selected, clear the recurrence rule
        if isNoneSelected {
            recurrenceRule = nil
            return
        }

        var daysOfWeek: Set<Int>? = nil
        var dayOfMonth: Int? = nil
        var interval = 1
        var finalFrequency = frequency

        // Handle custom interval (every X days)
        if isCustomInterval {
            interval = customInterval
            finalFrequency = .daily
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
            frequency: finalFrequency,
            interval: interval,
            daysOfWeek: daysOfWeek,
            dayOfMonth: dayOfMonth,
            endDate: nil,
            repeatMode: .fromOriginalDate
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

#Preview("Tasks - With None Option") {
    RecurrenceRulePickerView(recurrenceRule: .constant(nil), allowsNone: true)
}

#Preview("Habits - No None Option") {
    RecurrenceRulePickerView(recurrenceRule: .constant(.daily()), allowsNone: false)
}
