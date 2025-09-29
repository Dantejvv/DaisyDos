//
//  RecurrenceVisualizationView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/29/25.
//

import SwiftUI

struct RecurrenceVisualizationView: View {
    let recurrenceRule: RecurrenceRule?
    let onEdit: () -> Void

    @State private var nextOccurrences: [Date] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection

            if let rule = recurrenceRule {
                contentSection(for: rule)
            } else {
                emptyStateSection
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
        .onAppear {
            updateNextOccurrences()
        }
        .onChange(of: recurrenceRule) { _, _ in
            updateNextOccurrences()
        }
    }

    // MARK: - Header Section

    @ViewBuilder
    private var headerSection: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "repeat.circle.fill")
                    .foregroundColor(.daisyTask)
                    .font(.title3)

                Text("Recurrence")
                    .font(.headline)
                    .foregroundColor(.daisyText)
            }

            Spacer()

            Menu {
                Button(action: onEdit) {
                    Label("Edit Pattern", systemImage: "pencil")
                }

                if recurrenceRule != nil {
                    Button(action: {
                        // This would be handled by the parent view
                    }) {
                        Label("Remove Recurrence", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundColor(.daisyTextSecondary)
                    .font(.title3)
            }
            .accessibilityLabel("Recurrence options")
        }
    }

    // MARK: - Content Section

    @ViewBuilder
    private func contentSection(for rule: RecurrenceRule) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Pattern description
            patternDescriptionSection(for: rule)

            // Next occurrence
            if let nextDate = nextOccurrences.first {
                nextOccurrenceSection(nextDate)
            }

            // Upcoming occurrences
            if nextOccurrences.count > 1 {
                upcomingOccurrencesSection
            }

            // End conditions
            if rule.endDate != nil || rule.maxOccurrences != nil {
                endConditionsSection(for: rule)
            }
        }
    }

    @ViewBuilder
    private func patternDescriptionSection(for rule: RecurrenceRule) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pattern")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)

                Spacer()
            }

            Text(rule.displayDescription)
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.daisyBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func nextOccurrenceSection(_ nextDate: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Next")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)

                Spacer()

                if isWithinNextWeek(nextDate) {
                    Text(timeUntilText(nextDate))
                        .font(.caption)
                        .foregroundColor(.daisyTask)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Colors.Secondary.blue.opacity(0.1), in: Capsule())
                }
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(nextDate, style: .date)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.daisyText)

                    Text(nextDate, style: .time)
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }

                Spacer()

                Text(dayOfWeekText(nextDate))
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.regularMaterial, in: Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.daisyBackground.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private var upcomingOccurrencesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Upcoming")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.daisyText)

            VStack(spacing: 6) {
                ForEach(Array(nextOccurrences.dropFirst().prefix(4).enumerated()), id: \.offset) { index, date in
                    HStack {
                        Text("\(index + 2).")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                            .frame(width: 20, alignment: .leading)

                        Text(date, style: .date)
                            .font(.caption)
                            .foregroundColor(.daisyText)

                        Spacer()

                        Text(dayOfWeekText(date))
                            .font(.caption2)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.daisyBackground.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    @ViewBuilder
    private func endConditionsSection(for rule: RecurrenceRule) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("End Conditions")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.daisyText)

            VStack(alignment: .leading, spacing: 4) {
                if let endDate = rule.endDate {
                    HStack {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundColor(.daisyTextSecondary)
                            .font(.caption)

                        Text("Ends on \(endDate, style: .date)")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }

                if let maxOccurrences = rule.maxOccurrences {
                    HStack {
                        Image(systemName: "number.circle")
                            .foregroundColor(.daisyTextSecondary)
                            .font(.caption)

                        Text("Stops after \(maxOccurrences) occurrences")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.daisyBackground.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Empty State Section

    @ViewBuilder
    private var emptyStateSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "repeat.circle")
                .font(.title)
                .foregroundColor(.daisyTextSecondary)

            Text("No recurrence pattern")
                .font(.subheadline)
                .foregroundColor(.daisyTextSecondary)

            Button(action: onEdit) {
                Text("Add Recurrence")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyTask)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    // MARK: - Helper Methods

    private func updateNextOccurrences() {
        guard let rule = recurrenceRule else {
            nextOccurrences = []
            return
        }

        nextOccurrences = rule.occurrences(from: Date(), limit: 5)
    }

    private func isWithinNextWeek(_ date: Date) -> Bool {
        let weekFromNow = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date()) ?? Date()
        return date <= weekFromNow
    }

    private func timeUntilText(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let days = calendar.dateComponents([.day], from: now, to: date).day ?? 0
            if days <= 7 {
                return "In \(days) days"
            } else {
                return "In \(days / 7) weeks"
            }
        }
    }

    private func dayOfWeekText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Short day of week (Mon, Tue, etc.)
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 20) {
        // With recurrence rule
        RecurrenceVisualizationView(
            recurrenceRule: .daily(interval: 2),
            onEdit: {}
        )

        // Without recurrence rule
        RecurrenceVisualizationView(
            recurrenceRule: nil,
            onEdit: {}
        )

        // Complex recurrence rule
        RecurrenceVisualizationView(
            recurrenceRule: .weekly(
                daysOfWeek: [2, 4, 6],
                interval: 1,
                endDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())
            ),
            onEdit: {}
        )
    }
    .padding()
    .background(Color.daisyBackground)
}