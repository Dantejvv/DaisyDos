//
//  HabitNotificationSettingsView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/30/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct HabitNotificationSettingsView: View {
    @Environment(HabitNotificationManager.self) private var notificationManager: HabitNotificationManager?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTime = Date()
    @State private var showingPermissionAlert = false
    @State private var scheduledNotificationsCount = 0

    var body: some View {
        NavigationStack {
            Form {
                // Permission Status Section
                permissionStatusSection

                // Notification Settings Section
                if notificationManager?.isPermissionGranted == true {
                    notificationSettingsSection
                    reminderTimeSection
                    statisticsSection
                }
            }
            .navigationTitle("Habit Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentSettings()
                updateScheduledCount()
            }
            .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable notifications in Settings to receive habit reminders.")
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var permissionStatusSection: some View {
        Section {
            HStack {
                Image(systemName: notificationManager?.isPermissionGranted == true ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(notificationManager?.isPermissionGranted == true ? .daisySuccess : .orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Permission")
                        .font(.headline)

                    Text(notificationManager?.isPermissionGranted == true ? "Enabled" : "Not Enabled")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }

                Spacer()

                if notificationManager?.isPermissionGranted != true {
                    Button("Enable") {
                        requestPermissions()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } footer: {
            Text("Enable notifications to receive timely reminders for your habits.")
        }
    }

    @ViewBuilder
    private var notificationSettingsSection: some View {
        Section {
            Toggle("Habit Reminders", isOn: Binding(
                get: { notificationManager?.isNotificationsEnabled ?? false },
                set: { notificationManager?.isNotificationsEnabled = $0 }
            ))
        } header: {
            Text("Settings")
        } footer: {
            Text("Turn on to receive daily reminders for your habits.")
        }
    }

    @ViewBuilder
    private var reminderTimeSection: some View {
        Section {
            DatePicker(
                "Reminder Time",
                selection: $selectedTime,
                displayedComponents: .hourAndMinute
            )
            .onChange(of: selectedTime) { _, newTime in
                updateReminderTime(newTime)
            }
        } header: {
            Text("Default Reminder Time")
        } footer: {
            Text("All habit reminders will be sent at this time each day.")
        }
    }

    @ViewBuilder
    private var statisticsSection: some View {
        Section {
            HStack {
                Label("Scheduled Reminders", systemImage: "bell.badge")
                Spacer()
                Text("\(scheduledNotificationsCount)")
                    .foregroundColor(.daisyTextSecondary)
            }

            Button("Refresh All Reminders") {
                notificationManager?.scheduleAllHabitNotifications()
                updateScheduledCount()
            }
            .foregroundColor(.daisyHabit)
        } header: {
            Text("Statistics")
        } footer: {
            Text("Tap 'Refresh All Reminders' if you've changed habit schedules and want to update notifications.")
        }
    }

    // MARK: - Methods

    private func loadCurrentSettings() {
        guard let notificationManager = notificationManager else { return }

        // Convert default reminder time to Date for picker
        let calendar = Calendar.current
        let now = Date()
        let components = notificationManager.defaultReminderTime

        selectedTime = calendar.date(bySettingHour: components.hour ?? 9, minute: components.minute ?? 0, second: 0, of: now) ?? now
    }

    private func updateReminderTime(_ time: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)

        notificationManager?.updateDefaultReminderTime(hour: hour, minute: minute)
        updateScheduledCount()
    }

    private func requestPermissions() {
        guard let notificationManager = notificationManager else { return }

        _Concurrency.Task {
            let granted = await notificationManager.requestNotificationPermissions()
            if !granted {
                await MainActor.run {
                    showingPermissionAlert = true
                }
            }
        }
    }

    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    private func updateScheduledCount() {
        guard let notificationManager = notificationManager else { return }

        _Concurrency.Task {
            let count = await notificationManager.getScheduledNotificationsCount()
            await MainActor.run {
                scheduledNotificationsCount = count
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Habit.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    HabitNotificationSettingsView()
        .modelContainer(container)
        .environment(HabitNotificationManager(modelContext: container.mainContext))
}