//
//  ReplenishmentTimePickerView.swift
//  DaisyDos
//
//  Created by Claude Code on 1/25/26.
//  Picker for setting the global replenishment time for recurring items
//

import SwiftUI

/// Sheet for setting the global replenishment time
/// This determines when new recurring task/habit instances become visible each day
struct ReplenishmentTimePickerView: View {
    @Environment(ReplenishmentTimeManager.self) private var replenishmentTimeManager
    @Environment(\.dismiss) private var dismiss

    @State private var workingDate: Date

    init() {
        // Create a date from the current replenishment time
        // We'll initialize this properly in onAppear since we can't access environment here
        self._workingDate = State(initialValue: Date())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    // Info section
                    infoSection

                    // Time picker
                    timePickerSection
                }
                .padding(.vertical, Spacing.medium)
            }
            .background(Color.daisyBackground)
            .navigationTitle("Replenishment Time")
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
                    .foregroundColor(.accentColor)
                }
            }
            .onAppear {
                // Initialize working date from manager
                var components = DateComponents()
                components.hour = replenishmentTimeManager.replenishmentHour
                components.minute = replenishmentTimeManager.replenishmentMinute
                if let date = Calendar.current.date(from: components) {
                    workingDate = date
                }
            }
        }
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                Image(systemName: "info.circle")
                    .foregroundColor(.accentColor)
                Text("About Replenishment Time")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)
            }

            Text("When you complete a recurring task or habit, the next instance will appear at this time on its scheduled day. This allows you to start fresh each morning without seeing tomorrow's items too early.")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Time Picker Section

    private var timePickerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.accentColor)
                Text("Time")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)
                Spacer()
                Text(formattedTime)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal)
            .padding(.top, Spacing.small)

            DatePicker(
                "Time",
                selection: $workingDate,
                displayedComponents: [.hourAndMinute]
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .tint(.accentColor)
        }
        .padding(.vertical, Spacing.small)
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
        let components = Calendar.current.dateComponents([.hour, .minute], from: workingDate)
        if let hour = components.hour {
            replenishmentTimeManager.replenishmentHour = hour
        }
        if let minute = components.minute {
            replenishmentTimeManager.replenishmentMinute = minute
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    ReplenishmentTimePickerView()
        .environment(ReplenishmentTimeManager())
}
