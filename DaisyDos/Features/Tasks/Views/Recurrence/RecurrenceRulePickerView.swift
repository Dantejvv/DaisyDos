//
//  RecurrenceRulePickerView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
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
                return "Monday through Friday"
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
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header
                    headerSection

                    // MARK: - Quick Presets
                    if !isCustomMode {
                        presetsSection

                        // Custom option
                        customOptionCard
                    }

                    // MARK: - Custom Configuration
                    if isCustomMode {
                        customConfigurationSection
                    }

                    // MARK: - Preview
                    if currentRecurrenceRule != nil {
                        previewSection
                    }
                }
                .padding()
            }
            .navigationTitle("Recurrence")
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
                }
            }
            .onAppear {
                initializeFromExistingRule()
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Set up a recurrence pattern")
                .font(.headline)
                .foregroundColor(.daisyText)

            Text("Choose how often this task should repeat")
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Presets Section

    @ViewBuilder
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                            selectedPreset = preset
                        }
                    )
                }
            }
        }
    }

    // MARK: - Custom Option Card

    @ViewBuilder
    private var customOptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Advanced")
                .font(.headline)
                .foregroundColor(.daisyText)

            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isCustomMode = true
                    selectedPreset = nil
                }
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Colors.Secondary.purple.opacity(0.15))
                            .frame(width: 56, height: 56)

                        Image(systemName: "gearshape.circle")
                            .font(.title2)
                            .foregroundColor(Colors.Secondary.purple)
                    }

                    VStack(alignment: .leading, spacing: 4) {
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
                .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Custom Configuration Section

    @ViewBuilder
    private var customConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isCustomMode = false
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                        Text("Back to presets")
                            .font(.subheadline)
                    }
                    .foregroundColor(.daisyTask)
                }

                Spacer()
            }

            // Frequency Picker
            frequencySection

            // Interval Input
            intervalSection

            // Frequency-specific options
            frequencySpecificOptions

            // End conditions
            endConditionsSection
        }
    }

    // MARK: - Frequency Section

    @ViewBuilder
    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frequency")
                .font(.headline)
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

    // MARK: - Interval Section

    @ViewBuilder
    private var intervalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interval")
                .font(.headline)
                .foregroundColor(.daisyText)

            VStack(spacing: 8) {
                HStack {
                    Text("Every")
                        .foregroundColor(.daisyText)

                    Spacer()

                    Text(intervalUnit)
                        .foregroundColor(.daisyText)
                }

                Picker("Interval", selection: $interval) {
                    ForEach(intervalRange, id: \.self) { num in
                        Text("\(num)").tag(num)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .accessibilityLabel("Interval picker")
                .accessibilityHint("Select how often the task should repeat. Range: \(intervalRange.lowerBound) to \(intervalRange.upperBound) \(intervalUnit)")
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

    @ViewBuilder
    private var weeklyOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Days of Week")
                .font(.headline)
                .foregroundColor(.daisyText)

            DayOfWeekSelector(selectedDays: $selectedDaysOfWeek)
        }
    }

    @ViewBuilder
    private var monthlyOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Day of Month")
                .font(.headline)
                .foregroundColor(.daisyText)

            VStack(spacing: 8) {
                HStack {
                    Text("Day")
                        .foregroundColor(.daisyText)

                    Spacer()

                    Text("of the month")
                        .foregroundColor(.daisyText)
                }

                Picker("Day of Month", selection: $dayOfMonth) {
                    ForEach(1...31, id: \.self) { day in
                        Text("\(day)").tag(day)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 120)
                .accessibilityLabel("Day of month picker")
                .accessibilityHint("Select which day of the month the task should repeat")
            }
            .padding()
            .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - End Conditions Section

    @ViewBuilder
    private var endConditionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("End Conditions")
                .font(.headline)
                .foregroundColor(.daisyText)

            VStack(spacing: 12) {
                // End Date Option
                HStack {
                    Toggle("End on date", isOn: $hasEndDate)
                        .toggleStyle(.switch)
                        .onChange(of: hasEndDate) { _, newValue in
                            if newValue {
                                hasMaxOccurrences = false
                            }
                        }

                    Spacer()
                }

                if hasEndDate {
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Divider()

                // Max Occurrences Option
                HStack {
                    Toggle("Stop after", isOn: $hasMaxOccurrences)
                        .toggleStyle(.switch)
                        .onChange(of: hasMaxOccurrences) { _, newValue in
                            if newValue {
                                hasEndDate = false
                            }
                        }

                    Spacer()
                }

                if hasMaxOccurrences {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Number of occurrences")
                                .foregroundColor(.daisyText)

                            Spacer()
                        }

                        Picker("Max Occurrences", selection: $maxOccurrences) {
                            ForEach(1...100, id: \.self) { num in
                                Text("\(num)").tag(num)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .accessibilityLabel("Maximum occurrences picker")
                        .accessibilityHint("Select how many times the task should repeat")
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
            .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Preview Section

    @ViewBuilder
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .foregroundColor(.daisyText)

            if let rule = currentRecurrenceRule {
                VStack(spacing: 12) {
                    // Pattern description
                    HStack {
                        Image(systemName: "repeat.circle")
                            .foregroundColor(.daisyTask)

                        Text(rule.displayDescription)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.daisyText)

                        Spacer()
                    }

                    Divider()

                    // Next occurrences
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next occurrences:")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)

                        let occurrences = rule.occurrences(from: Date(), limit: 5)
                        ForEach(Array(occurrences.enumerated()), id: \.offset) { index, date in
                            HStack {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(.daisyTextSecondary)
                                    .frame(width: 20, alignment: .leading)

                                Text(date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.daisyText)

                                Spacer()
                            }
                        }

                        if occurrences.isEmpty {
                            Text("No future occurrences")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                                .italic()
                        }
                    }
                }
                .padding()
                .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
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
            return 1...365  // Up to daily for a year
        case .weekly:
            return 1...42   // Up to 42 weeks (~10 months)
        case .monthly:
            return 1...12   // Up to 12 months
        case .yearly:
            return 1...10   // Up to 10 years
        case .custom:
            return 1...30   // Default range
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
            maxOccurrences: hasMaxOccurrences ? maxOccurrences : nil
        )
    }

    private func saveRecurrenceRule() {
        recurrenceRule = currentRecurrenceRule
    }
}

#Preview {
    RecurrenceRulePickerView(recurrenceRule: .constant(nil))
}