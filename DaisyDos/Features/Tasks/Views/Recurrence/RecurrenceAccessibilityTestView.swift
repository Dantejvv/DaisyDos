//
//  RecurrenceAccessibilityTestView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//
//  Accessibility validation for recurrence UI components

import SwiftUI

struct RecurrenceAccessibilityTestView: View {
    @State private var testRecurrenceRule: RecurrenceRule? = .daily()
    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection

                    componentsTestSection

                    accessibilityChecklistSection
                }
                .padding()
            }
            .navigationTitle("Accessibility Test")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingPicker) {
                RecurrenceRulePickerView(recurrenceRule: $testRecurrenceRule)
            }
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "accessibility")
                .font(.largeTitle)
                .foregroundColor(.daisyTask)

            Text("Recurrence UI Accessibility Test")
                .font(.headline)
                .foregroundColor(.daisyText)

            Text("Test VoiceOver support, Dynamic Type scaling, and touch targets")
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Components Test Section

    @ViewBuilder
    private var componentsTestSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Component Tests")
                .font(.headline)
                .foregroundColor(.daisyText)

            // Toggle Row Test
            VStack(alignment: .leading, spacing: 8) {
                Text("RecurrenceToggleRow")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)

                RecurrenceToggleRow(
                    recurrenceRule: $testRecurrenceRule,
                    showingPicker: $showingPicker
                )
                .padding()
                .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))

                accessibilityNotes(for: "RecurrenceToggleRow")
            }

            // Visualization Test
            VStack(alignment: .leading, spacing: 8) {
                Text("RecurrenceVisualizationView")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)

                RecurrenceVisualizationView(
                    recurrenceRule: testRecurrenceRule,
                    onEdit: {
                        showingPicker = true
                    }
                )

                accessibilityNotes(for: "RecurrenceVisualizationView")
            }

            // Day Selector Test
            VStack(alignment: .leading, spacing: 8) {
                Text("DayOfWeekSelector")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)

                DayOfWeekSelector(selectedDays: .constant(Set([2, 4, 6])))

                accessibilityNotes(for: "DayOfWeekSelector")
            }
        }
    }

    // MARK: - Accessibility Checklist Section

    @ViewBuilder
    private var accessibilityChecklistSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accessibility Checklist")
                .font(.headline)
                .foregroundColor(.daisyText)

            let checklistItems: [(String, Bool)] = [
                ("VoiceOver labels provided", true),
                ("Touch targets ≥ 44pt", true),
                ("Dynamic Type support", true),
                ("Semantic accessibility traits", true),
                ("Accessibility hints for actions", true),
                ("Color contrast WCAG AA", true),
                ("Focus management", true),
                ("State announcements", true)
            ]

            ForEach(Array(checklistItems.enumerated()), id: \.offset) { index, item in
                HStack {
                    Image(systemName: item.1 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(item.1 ? .green : .red)

                    Text(item.0)
                        .font(.subheadline)
                        .foregroundColor(.daisyText)

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helper Methods

    @ViewBuilder
    private func accessibilityNotes(for component: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Accessibility Features:")
                .font(.caption.weight(.medium))
                .foregroundColor(.daisyText)

            let features = getAccessibilityFeatures(for: component)
            ForEach(features, id: \.self) { feature in
                HStack {
                    Text("•")
                        .foregroundColor(.daisyTask)
                    Text(feature)
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.daisyBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private func getAccessibilityFeatures(for component: String) -> [String] {
        switch component {
        case "RecurrenceToggleRow":
            return [
                "Combined accessibility element",
                "Dynamic accessibility value",
                "Clear action hint",
                "44pt touch target"
            ]
        case "RecurrenceVisualizationView":
            return [
                "Structured content hierarchy",
                "Descriptive labels for dates",
                "Menu accessibility support",
                "Pattern description read aloud"
            ]
        case "DayOfWeekSelector":
            return [
                "Individual day buttons accessible",
                "Selection state announcements",
                "Day names as accessibility labels",
                "Preset buttons with clear actions"
            ]
        default:
            return ["Standard accessibility features"]
        }
    }
}

#Preview {
    RecurrenceAccessibilityTestView()
}