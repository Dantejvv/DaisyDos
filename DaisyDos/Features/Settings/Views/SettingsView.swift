//
//  SettingsView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(LocalOnlyModeManager.self) private var localOnlyModeManager
    @Environment(AppearanceManager.self) private var appearanceManager
    @Environment(TagManager.self) private var tagManager
    @Environment(NotificationPreferencesManager.self) private var notificationPreferencesManager
    @Environment(TaskNotificationManager.self) private var taskNotificationManager
    @Environment(CloudKitSyncManager.self) private var cloudKitSyncManager: CloudKitSyncManager?

    @Query private var allTags: [Tag]

    @State private var showingAbout = false
    @State private var showingAppearanceSettings = false
    @State private var showingCloudKitStatus = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTagPicker = false
    @State private var showingImportExport = false
    @State private var showingTestDataGenerator = false
    @State private var showingErrorMessageTest = false
    @State private var showingRestartAlert = false
    @State private var enableSync = false

    private var localOnlyModeBinding: Binding<Bool> {
        Binding(
            get: { localOnlyModeManager.isLocalOnlyMode },
            set: { newValue in
                enableSync = !newValue
                showingRestartAlert = true
            }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                privacySection
                appearanceSection
                notificationsSection
                tagsSection
                dataManagementSection
                #if DEBUG
                developerSection
                #endif
                appInformationSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingAppearanceSettings) {
                AppearanceSettingsView()
            }
            .sheet(isPresented: $showingCloudKitStatus) {
                CloudKitSyncStatusView()
            }
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingTagPicker) {
                TagsView()
            }
            .sheet(isPresented: $showingImportExport) {
                ImportExportView()
            }
            .sheet(isPresented: $showingTestDataGenerator) {
                TestDataGeneratorView()
            }
            #if DEBUG
            .sheet(isPresented: $showingErrorMessageTest) {
                NavigationStack {
                    ErrorMessageTestView()
                }
            }
            #endif
            .alert("Restart Required", isPresented: $showingRestartAlert) {
                Button("Cancel", role: .cancel) {
                    localOnlyModeManager.isLocalOnlyMode = !enableSync
                }
                Button("OK") {
                    print("⚠️ Please restart the app for changes to take effect")
                }
            } message: {
                Text(enableSync
                    ? "Enabling iCloud sync requires restarting DaisyDos."
                    : "Switching to local-only mode requires restarting DaisyDos.")
            }
        }
    }

    // MARK: - View Components

    private var privacySection: some View {
        Section("Privacy") {
            Toggle(isOn: localOnlyModeBinding) {
                Label {
                    Text("Local-Only Mode")
                        .foregroundColor(.daisyText)
                } icon: {
                    Image(systemName: localOnlyModeManager.isLocalOnlyMode ? "lock.shield" : "icloud")
                }
            }

            Text(localOnlyModeManager.isLocalOnlyMode
                ? "Your data stays on this device. Disable to enable iCloud sync."
                : "Your data syncs via iCloud. Enable for local-only storage.")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)

            if !localOnlyModeManager.isLocalOnlyMode {
                Button(action: { showingCloudKitStatus = true }) {
                    HStack {
                        Label {
                            Text("Sync Status")
                                .foregroundColor(.daisyText)
                        } icon: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Spacer()
                        Text(cloudKitSyncManager?.syncStatus.displayText ?? "Unknown")
                            .foregroundColor(.daisyTextSecondary)
                            .font(.caption)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
            } else {
                HStack {
                    Text("iCloud Status:")
                        .font(.caption)
                    Spacer()
                    Text(localOnlyModeManager.cloudKitStatusDescription)
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }

            Button(action: { showingPrivacyPolicy = true }) {
                HStack {
                    Label {
                        Text("Privacy Policy")
                            .foregroundColor(.daisyText)
                    } icon: {
                        Image(systemName: "hand.raised")
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Button(action: { showingAppearanceSettings = true }) {
                HStack {
                    Label {
                        Text("Theme & Colors")
                            .foregroundColor(.daisyText)
                    } icon: {
                        Image(systemName: "paintbrush")
                    }
                    Spacer()
                    Text(appearanceManager.preferredColorScheme.displayName)
                        .foregroundColor(.daisyTextSecondary)
                        .font(.caption)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }
        }
    }

    private var notificationsSection: some View {
        Section("Notifications") {
            Toggle(isOn: Binding(
                get: { notificationPreferencesManager.isGlobalNotificationsEnabled },
                set: { notificationPreferencesManager.isGlobalNotificationsEnabled = $0 }
            )) {
                Label {
                    Text("Enable Notifications")
                        .foregroundColor(.daisyText)
                } icon: {
                    Image(systemName: "bell")
                }
            }

            // Permission status
            HStack {
                Image(systemName: taskNotificationManager.isPermissionGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(taskNotificationManager.isPermissionGranted ? .daisySuccess : .orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Permission")
                        .font(.subheadline)
                        .foregroundColor(.daisyText)

                    Text(taskNotificationManager.isPermissionGranted ? "Granted" : "Not Granted")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }

                Spacer()

                if !taskNotificationManager.isPermissionGranted {
                    Button("Grant") {
                        _Concurrency.Task {
                            await taskNotificationManager.requestNotificationPermissions()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            // Info text
            Text("Notifications are set individually for each task and habit using the alert button in the edit view.")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
        }
    }

    private var tagsSection: some View {
        Section("Tags") {
            Button(action: { showingTagPicker = true }) {
                HStack {
                    Label {
                        Text("Manage Tags")
                            .foregroundColor(.daisyText)
                    } icon: {
                        Image(systemName: "tag")
                    }
                    Spacer()
                    Text("\(allTags.count)")
                        .foregroundColor(.daisyTextSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }
        }
    }

    private var dataManagementSection: some View {
        Section("Data Management") {
            Button(action: { showingImportExport = true }) {
                HStack {
                    Label {
                        Text("Import/Export")
                            .foregroundColor(.daisyText)
                    } icon: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }
        }
    }

    private var developerSection: some View {
        Section("Developer") {
            Button(action: { showingTestDataGenerator = true }) {
                Label {
                    Text("Test Data Generator")
                        .foregroundColor(.daisyText)
                } icon: {
                    Image(systemName: "wrench.and.screwdriver")
                }
            }

            Button(action: { showingErrorMessageTest = true }) {
                Label {
                    Text("Test Error Messages")
                        .foregroundColor(.daisyText)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                }
            }
        }
    }

    private var appInformationSection: some View {
        Section("App Information") {
            Button(action: { showingAbout = true }) {
                Label {
                    Text("About DaisyDos")
                        .foregroundColor(.daisyText)
                } icon: {
                    Image(systemName: "questionmark.circle")
                }
            }

            HStack {
                Label {
                    Text("Version")
                        .foregroundColor(.daisyText)
                } icon: {
                    Image(systemName: "apps.iphone")
                }
                Spacer()
                Text("1.0.0 Beta")
                    .foregroundColor(.daisyTextSecondary)
            }
        }
    }
}

// MARK: - About View

private struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppearanceManager.self) private var appearanceManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "flower")
                        .font(.system(size: 64))

                    Text("DaisyDos")
                        .font(.largeTitle.bold())

                    Text("A unified productivity app for tasks and habits")
                        .font(.body)
                        .foregroundColor(.daisyTextSecondary)
                        .multilineTextAlignment(.center)

                    Text("DaisyDos combines task management and habit tracking in a single, privacy-first application. Built with SwiftUI and SwiftData, it focuses on simplicity, accessibility, and keeping your data private.")
                        .font(.body)
                        .foregroundColor(.daisyTextSecondary)
                        .padding()
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .applyAppearance(appearanceManager)
    }
}


#Preview {
    let container = try! ModelContainer(for: Task.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return SettingsView()
        .modelContainer(container)
        .environment(LocalOnlyModeManager())
        .environment(TaskManager(modelContext: container.mainContext))
        .environment(HabitManager(modelContext: container.mainContext))
        .environment(TagManager(modelContext: container.mainContext))
}