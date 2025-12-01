//
//  AlertPickerSheet.swift
//  DaisyDos
//
//  Created by Claude Code on 11/4/25.
//  iOS Calendar-style alert picker for task reminders
//

import SwiftUI

/// Alert/reminder time options similar to iOS Calendar
enum AlertOption: String, CaseIterable, Identifiable {
    case atTimeOfEvent = "At time of event"
    case fiveMinutesBefore = "5 minutes before"
    case fifteenMinutesBefore = "15 minutes before"
    case thirtyMinutesBefore = "30 minutes before"
    case oneHourBefore = "1 hour before"
    case twoHoursBefore = "2 hours before"
    case oneDayBefore = "1 day before"
    case twoDaysBefore = "2 days before"
    case oneWeekBefore = "1 week before"

    var id: String { rawValue }

    /// Time interval in seconds (negative means before, 0 means at time)
    var timeInterval: TimeInterval {
        switch self {
        case .atTimeOfEvent: return 0
        case .fiveMinutesBefore: return -5 * 60
        case .fifteenMinutesBefore: return -15 * 60
        case .thirtyMinutesBefore: return -30 * 60
        case .oneHourBefore: return -60 * 60
        case .twoHoursBefore: return -2 * 60 * 60
        case .oneDayBefore: return -24 * 60 * 60
        case .twoDaysBefore: return -2 * 24 * 60 * 60
        case .oneWeekBefore: return -7 * 24 * 60 * 60
        }
    }

    /// Compact display text for the button
    var compactText: String {
        switch self {
        case .atTimeOfEvent: return "At time"
        case .fiveMinutesBefore: return "5 min before"
        case .fifteenMinutesBefore: return "15 min before"
        case .thirtyMinutesBefore: return "30 min before"
        case .oneHourBefore: return "1 hr before"
        case .twoHoursBefore: return "2 hrs before"
        case .oneDayBefore: return "1 day before"
        case .twoDaysBefore: return "2 days before"
        case .oneWeekBefore: return "1 week before"
        }
    }

    /// Very short label for icon toolbar (e.g., "5m", "1h", "1d")
    var shortLabel: String {
        switch self {
        case .atTimeOfEvent: return "On time"
        case .fiveMinutesBefore: return "5m"
        case .fifteenMinutesBefore: return "15m"
        case .thirtyMinutesBefore: return "30m"
        case .oneHourBefore: return "1h"
        case .twoHoursBefore: return "2h"
        case .oneDayBefore: return "1d"
        case .twoDaysBefore: return "2d"
        case .oneWeekBefore: return "1w"
        }
    }

    /// Initialize from time interval
    static func from(timeInterval: TimeInterval) -> AlertOption? {
        return AlertOption.allCases.first { $0.timeInterval == timeInterval }
    }
}

/// Sheet-based alert time picker similar to iOS Calendar
struct AlertPickerSheet: View {
    @Binding var selectedAlert: AlertOption?
    let accentColor: Color

    @Environment(\.dismiss) private var dismiss

    @State private var workingSelection: AlertOption?

    init(
        selectedAlert: Binding<AlertOption?>,
        accentColor: Color = .daisyTask
    ) {
        self._selectedAlert = selectedAlert
        self.accentColor = accentColor
        self._workingSelection = State(initialValue: selectedAlert.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            List {
                // None option
                Button(action: {
                    workingSelection = nil
                }) {
                    HStack {
                        Text("None")
                            .foregroundColor(.daisyText)

                        Spacer()

                        if workingSelection == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(accentColor)
                                .font(.body.weight(.semibold))
                        }
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(workingSelection == nil ? accentColor.opacity(0.08) : Color.clear)

                // Alert options
                ForEach(AlertOption.allCases) { option in
                    Button(action: {
                        workingSelection = option
                    }) {
                        HStack {
                            Text(option.rawValue)
                                .foregroundColor(.daisyText)

                            Spacer()

                            if workingSelection == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(accentColor)
                                    .font(.body.weight(.semibold))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        workingSelection == option ? accentColor.opacity(0.08) : Color.clear
                    )
                }
            }
            .listStyle(.insetGrouped)
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
                        selectedAlert = workingSelection
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
    @Previewable @State var alert: AlertOption? = .fifteenMinutesBefore

    return AlertPickerSheet(
        selectedAlert: $alert,
        accentColor: .daisyTask
    )
}
