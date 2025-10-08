//
//  RecurrenceRulePickerView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//  Redesigned based on iOS patterns from Things 3, Todoist, Apple Calendar
//

import SwiftUI

struct RecurrenceRulePickerView: View {
    @Binding var recurrenceRule: RecurrenceRule?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPreset: PresetType?
    @State private var isCustomMode: Bool = false
    @State private var frequency: RecurrenceRule.Frequency = .daily
    @State private var interval: Int = 1
    @State private var selectedDaysOfWeek: Set<Int> = []
    @State private var dayOfMonth: Int = 1
    @State private var repeatMode: RecurrenceRule.RepeatMode = .fromOriginalDate
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var hasMaxOccurrences: Bool = false
    @State private var maxOccurrences: Int = 10

    // MARK: - Preset Types

    enum PresetType: String, CaseIterable {
        case daily = "Daily"
        case weekdays = "Weekdays"
        case weekends = "Weekends"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"

        var description: String {
            switch self {
            case .daily:
                return "Every day"
            case .weekdays:
                return "Monday to Friday"
            case .weekends:
                return "Saturday and Sunday"
            case .weekly:
                return "Same day each week"
            case .monthly:
                return "Same day each month"
            case .yearly:
                return "Same date each year"
            }
        }

        var icon: String {
            switch self {
            case .daily:
                return "repeat.circle"
            case .weekdays:
                return "briefcase.circle"
            case .weekends:
                return "bed.double.circle"
            case .weekly:
                return "calendar.circle"
            case .monthly:
                return "calendar.badge.clock"
            case .yearly:
                return "calendar.badge.plus"
            }
        }

        func createRecurrenceRule() -> RecurrenceRule {
            switch self {
            case .daily:
                return .daily()
            case .weekdays:
                return .weekdays
            case .weekends:
                return .weekends
            case .weekly:
                return .weekly(daysOfWeek: [Calendar.current.component(.weekday, from: Date())])
            case .monthly:
                return .monthly(dayOfMonth: Calendar.current.component(.day, from: Date()))
            case .yearly:
                return .yearly()
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Natural Language Summary (Always Visible)
                if let rule = currentRecurrenceRule {
                    naturalLanguageSummary(for: rule)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Quick Presets
                        if !isCustomMode {
                            presetsSection
                            customOptionCard
                        }

                        // MARK: - Custom Configuration
                        if isCustomMode {
                            customConfigurationSection
                        }

                        // MARK: - Preview
                        if let rule = currentRecurrenceRule {
                            previewSection(for: rule)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Repeat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveRecurrenceRule()
                        dismiss()
                    }
                    .disabled(currentRecurrenceRule == nil)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                initializeFromExistingRule()
            }
        }
    }

    // MARK: - Natural Language Summary

    @ViewBuilder
    private func naturalLanguageSummary(for rule: RecurrenceRule) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "repeat.circle.fill")
                .font(.title2)
                .foregroundColor(.daisyTask)

            Text(rule.naturalLanguageDescription)
                .font(.headline)
                .foregroundColor(.daisyText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
    }

    // MARK: - Presets Section

    @ViewBuilder
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Options")
                .font(.headline)
                .foregroundColor(.daisyText)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(PresetType.allCases, id: \.self) { preset in
                    RecurrencePresetCard(
                        preset: preset,
                        isSelected: selectedPreset == preset,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedPreset = preset
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Custom Option Card

    @ViewBuilder
    private var customOptionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Advanced")
                .font(.headline)
                .foregroundColor(.daisyText)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isCustomMode = true
                    selectedPreset = nil
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "gearshape.circle.fill")
                        .font(.title2)
                        .foregroundColor(Colors.Secondary.purple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Custom Pattern")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.daisyText)

                        Text("Create your own recurrence rule")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
                .padding()
                .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Custom Configuration Section

    @ViewBuilder
    private var customConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Back button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isCustomMode = false
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                    Text("Quick Options")
                        .font(.subheadline)
                }
                .foregroundColor(.daisyTask)
            }

            // Frequency Picker (Segmented)
            frequencySection

            // Interval Stepper (New!)
            intervalSection

            // Frequency-specific options
            frequencySpecificOptions

            // Repeat Mode (New!)
            repeatModeSection

            // End conditions
            endConditionsSection
        }
    }

    // MARK: - Frequency Section

    @ViewBuilder
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frequency")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.daisyText)

            Picker("Frequency", selection: $frequency) {
                ForEach(RecurrenceRule.Frequency.allCases.filter { $0 != .custom }, id: \.self) { freq in
                    Text(freq.displayName).tag(freq)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: frequency) { _, _ in
                resetFrequencySpecificOptions()
            }
        }
    }

    // MARK: - Interval Section (New: Using Stepper!)

    @ViewBuilder
    private var intervalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interval")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.daisyText)

            HStack {
                Text("Every")
                    .foregroundColor(.daisyText)

                Spacer()

                Stepper(value: $interval, in: intervalRange) {
                    HStack(spacing: 4) {
                        Text("\(interval)")
                            .fontWeight(.semibold)
                            .foregroundColor(.daisyTask)
                        Text(intervalUnit)
                            .foregroundColor(.daisyText)
                    }
                }
                .labelsHidden()
            }
            .padding()
            .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Frequency Specific Options

    @ViewBuilder
    private var frequencySpecificOptions: some View {
        switch frequency {
        case .weekly:
            weeklyOptionsSection
        case .monthly:
            monthlyOptionsSection
        default:
            EmptyView()
        }
    }

    // MARK: - Weekly Options (New: Pill Buttons!)

    @ViewBuilder
    private var weeklyOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Days of Week")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.daisyText)

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
                        Text(Calendar.current.veryShortWeekdaySymbols[weekday - 1])
                            .font(.subheadline.weight(isSelected ? .semibold : .regular))
                            .foregroundColor(isSelected ? .white : .daisyText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? Color.daisyTask : Color.daisySurface)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Monthly Options (New: Using Stepper!)

    @ViewBuilder
    private var monthlyOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Day of Month")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.daisyText)

            HStack {
                Text("Day")
                    .foregroundColor(.daisyText)

                Spacer()

                Stepper(value: $dayOfMonth, in: 1...31) {
                    HStack(spacing: 4) {
                        Text("\(dayOfMonth)")
                            .fontWeight(.semibold)
                            .foregroundColor(.daisyTask)
                        Text("of the month")
                            .foregroundColor(.daisyText)
                    }
                }
                .labelsHidden()
            }
            .padding()
            .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Repeat Mode Section (New!)

    @ViewBuilder
    private var repeatModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Repeat Mode")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.daisyText)

            VStack(spacing: 8) {
                ForEach(RecurrenceRule.RepeatMode.allCases, id: \.self) { mode in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            repeatMode = mode
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: mode.icon)
                                .font(.title3)
                                .foregroundColor(repeatMode == mode ? .daisyTask : .daisyTextSecondary)
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(mode.displayName)
                                    .font(.subheadline.weight(repeatMode == mode ? .semibold : .regular))
                                    .foregroundColor(.daisyText)

                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(.daisyTextSecondary)
                            }

                            Spacer()

                            if repeatMode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.daisyTask)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(repeatMode == mode ? Color.daisyTask.opacity(0.1) : Color.daisySurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(repeatMode == mode ? Color.daisyTask : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - End Conditions Section

    @ViewBuilder
    private var endConditionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("End Conditions")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.daisyText)

            VStack(spacing: 12) {
                // End Date Option
                Toggle("End on date", isOn: $hasEndDate)
                    .toggleStyle(.switch)
                    .tint(.daisyTask)
                    .onChange(of: hasEndDate) { _, newValue in
                        if newValue {
                            hasMaxOccurrences = false
                        }
                    }

                if hasEndDate {
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .tint(.daisyTask)
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }

                Divider()

                // Max Occurrences Option
                Toggle("Stop after occurrences", isOn: $hasMaxOccurrences)
                    .toggleStyle(.switch)
                    .tint(.daisyTask)
                    .onChange(of: hasMaxOccurrences) { _, newValue in
                        if newValue {
                            hasEndDate = false
                        }
                    }

                if hasMaxOccurrences {
                    HStack {
                        Text("Number of times")
                            .foregroundColor(.daisyText)

                        Spacer()

                        Stepper(value: $maxOccurrences, in: 1...100) {
                            Text("\(maxOccurrences)")
                                .fontWeight(.semibold)
                                .foregroundColor(.daisyTask)
                        }
                        .labelsHidden()
                    }
                    .padding(.vertical, 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
            .padding()
            .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Preview Section

    @ViewBuilder
    private func previewSection(for rule: RecurrenceRule) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.daisyTask)
                Text("Next Occurrences")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)
            }

            let occurrences = rule.occurrences(from: Date(), limit: 3)
            if !occurrences.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(occurrences.enumerated()), id: \.offset) { index, date in
                        HStack(spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.daisyTextSecondary)
                                .frame(width: 16, alignment: .leading)

                            Text(date, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.daisyText)

                            Spacer()

                            Text(date, style: .relative)
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.daisySurface.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            } else {
                Text("No future occurrences")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                    .italic()
                    .padding()
            }
        }
    }

    // MARK: - Computed Properties

    private var intervalUnit: String {
        let base = switch frequency {
        case .daily: "day"
        case .weekly: "week"
        case .monthly: "month"
        case .yearly: "year"
        case .custom: "unit"
        }
        return interval == 1 ? base : base + "s"
    }

    private var intervalRange: ClosedRange<Int> {
        switch frequency {
        case .daily:
            return 1...365
        case .weekly:
            return 1...52
        case .monthly:
            return 1...12
        case .yearly:
            return 1...10
        case .custom:
            return 1...30
        }
    }

    private var currentRecurrenceRule: RecurrenceRule? {
        if let preset = selectedPreset {
            return preset.createRecurrenceRule()
        } else if isCustomMode {
            return createCustomRecurrenceRule()
        }
        return nil
    }

    // MARK: - Helper Methods

    private func initializeFromExistingRule() {
        guard let existingRule = recurrenceRule else { return }

        // Try to match with presets first
        for preset in PresetType.allCases {
            let presetRule = preset.createRecurrenceRule()
            if isRuleSimilarToPreset(existingRule, presetRule) {
                selectedPreset = preset
                return
            }
        }

        // If no preset matches, use custom mode
        isCustomMode = true
        frequency = existingRule.frequency
        interval = existingRule.interval
        selectedDaysOfWeek = existingRule.daysOfWeek ?? []
        dayOfMonth = existingRule.dayOfMonth ?? Calendar.current.component(.day, from: Date())
        repeatMode = existingRule.repeatMode

        if let endDate = existingRule.endDate {
            hasEndDate = true
            self.endDate = endDate
        }

        if let maxOccurrences = existingRule.maxOccurrences {
            hasMaxOccurrences = true
            self.maxOccurrences = maxOccurrences
        }
    }

    private func isRuleSimilarToPreset(_ rule: RecurrenceRule, _ preset: RecurrenceRule) -> Bool {
        return rule.frequency == preset.frequency &&
               rule.interval == preset.interval &&
               rule.daysOfWeek == preset.daysOfWeek &&
               rule.dayOfMonth == preset.dayOfMonth
    }

    private func resetFrequencySpecificOptions() {
        selectedDaysOfWeek = []
        dayOfMonth = Calendar.current.component(.day, from: Date())

        // Reset interval if it's outside the new frequency's valid range
        if !intervalRange.contains(interval) {
            interval = 1
        }
    }

    private func createCustomRecurrenceRule() -> RecurrenceRule? {
        var daysOfWeek: Set<Int>? = nil
        var dayOfMonth: Int? = nil

        switch frequency {
        case .weekly:
            if !selectedDaysOfWeek.isEmpty {
                daysOfWeek = selectedDaysOfWeek
            }
        case .monthly:
            dayOfMonth = self.dayOfMonth
        default:
            break
        }

        return RecurrenceRule(
            frequency: frequency,
            interval: interval,
            daysOfWeek: daysOfWeek,
            dayOfMonth: dayOfMonth,
            endDate: hasEndDate ? endDate : nil,
            maxOccurrences: hasMaxOccurrences ? maxOccurrences : nil,
            repeatMode: repeatMode
        )
    }

    private func saveRecurrenceRule() {
        recurrenceRule = currentRecurrenceRule
    }
}

#Preview {
    RecurrenceRulePickerView(recurrenceRule: .constant(nil))
}
