//
//  TaskNotificationSettingsView.swift
//  DaisyDos
//
//  Created by Claude Code on 12/01/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct TaskNotificationSettingsView: View {
    @Environment(TaskNotificationManager.self) private var notificationManager
    @Environment(\.dismiss) private var dismiss

    @State private var enableNotifications = true
    @State private var enableOverdueReminders = true
    @State private var showingPermissionAlert = false
    @State private var scheduledNotificationsCount = 0

    var body: some View {
        NavigationStack {
            Form {
                // Permission Status Section
                permissionStatusSection

                // Notification Settings Section
                if notificationManager.isPermissionGranted {
                    notificationSettingsSection
                    overdueSettingsSection
                    statisticsSection
                }
            }
            .navigationTitle("Task Reminders")
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
                Text("Please enable notifications in Settings to receive task reminders.")
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var permissionStatusSection: some View {
        Section {
            HStack {
                Image(systemName: notificationManager.isPermissionGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(notificationManager.isPermissionGranted ? .daisySuccess : .orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Permission")
                        .font(.headline)

                    Text(notificationManager.isPermissionGranted ? "Enabled" : "Not Enabled")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }

                Spacer()

                if !notificationManager.isPermissionGranted {
                    Button("Enable") {
                        requestPermissions()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        } header: {
            Text("Permission")
        } footer: {
            Text("Allow DaisyDos to send notifications for task reminders and deadlines.")
        }
    }

    @ViewBuilder
    private var notificationSettingsSection: some View {
        Section {
            Toggle("Enable Task Reminders", isOn: $enableNotifications)
                .onChange(of: enableNotifications) { _, newValue in
                    notificationManager.isNotificationsEnabled = newValue
                    updateScheduledCount()
                }
        } header: {
            Text("Task Notifications")
        } footer: {
            Text("Receive notifications before tasks are due based on the alert time you set for each task.")
        }
    }

    @ViewBuilder
    private var overdueSettingsSection: some View {
        Section {
            Toggle("Overdue Reminders", isOn: $enableOverdueReminders)
                .onChange(of: enableOverdueReminders) { _, newValue in
                    notificationManager.enableOverdueReminders = newValue
                    if enableNotifications {
                        notificationManager.scheduleAllTaskNotifications()
                    }
                    updateScheduledCount()
                }
        } header: {
            Text("Overdue Tasks")
        } footer: {
            Text("Receive a follow-up notification 1 hour after a task becomes overdue.")
        }
    }

    @ViewBuilder
    private var statisticsSection: some View {
        Section {
            HStack {
                Text("Scheduled Notifications")
                Spacer()
                Text("\(scheduledNotificationsCount)")
                    .foregroundColor(.daisyTextSecondary)
            }

            Button("Refresh All Reminders") {
                notificationManager.scheduleAllTaskNotifications()
                updateScheduledCount()
            }
        } header: {
            Text("Statistics")
        } footer: {
            Text("Refresh all reminders to resync notifications with your tasks.")
        }
    }

    // MARK: - Actions

    private func loadCurrentSettings() {
        enableNotifications = notificationManager.isNotificationsEnabled
        enableOverdueReminders = notificationManager.enableOverdueReminders
    }

    private func requestPermissions() {
        _Concurrency.Task {
            let granted = await notificationManager.requestNotificationPermissions()
            if granted {
                notificationManager.isNotificationsEnabled = true
                enableNotifications = true
                updateScheduledCount()
            } else {
                showingPermissionAlert = true
            }
        }
    }

    private func updateScheduledCount() {
        _Concurrency.Task {
            scheduledNotificationsCount = await notificationManager.getScheduledNotificationsCount()
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Task.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return TaskNotificationSettingsView()
        .modelContainer(container)
        .environment(TaskNotificationManager(modelContext: container.mainContext))
}
