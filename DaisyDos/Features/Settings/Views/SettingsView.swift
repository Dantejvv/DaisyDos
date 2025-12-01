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
    @Environment(HabitNotificationManager.self) private var notificationManager: HabitNotificationManager?

    @Query private var allTags: [Tag]

    @State private var showingAbout = false
    @State private var showingAppearanceSettings = false
    @State private var showingNotificationSettings = false
    @State private var showingTagPicker = false
    @State private var showingImportExport = false
    @State private var showingResetDelete = false
    @State private var showingTestDataGenerator = false
    @State private var showingErrorMessageTest = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Privacy
                Section("Privacy") {
                    HStack {
                        Label {
                            Text("Local-Only Mode")
                                .foregroundColor(.daisyText)
                        } icon: {
                            Image(systemName: "lock.shield")
                        }
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .disabled(true)
                    }
                    Text("DaisyDos keeps your data private by default.")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }

                // MARK: - Appearance
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

                // MARK: - Notifications
                Section("Notifications") {
                    Button(action: { showingNotificationSettings = true }) {
                        HStack {
                            Label {
                                Text("Habit Reminders")
                                    .foregroundColor(.daisyText)
                            } icon: {
                                Image(systemName: "bell")
                            }
                            Spacer()
                            if let notificationManager = notificationManager {
                                Text(notificationManager.isPermissionGranted ? "Enabled" : "Disabled")
                                    .foregroundColor(.daisyTextSecondary)
                                    .font(.caption)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                        }
                    }
                }

                // MARK: - Tags
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

                // MARK: - Data Management
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

                    Button(action: { showingResetDelete = true }) {
                        HStack {
                            Label {
                                Text("Reset & Delete")
                                    .foregroundColor(.daisyText)
                            } icon: {
                                Image(systemName: "trash.circle")
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                        }
                    }
                }

                // MARK: - Developer Tools
                #if DEBUG
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
                #endif

                // MARK: - App Information
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
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingAppearanceSettings) {
                AppearanceSettingsView()
            }
            .sheet(isPresented: $showingNotificationSettings) {
                if notificationManager != nil {
                    HabitNotificationSettingsView()
                }
            }
            .sheet(isPresented: $showingTagPicker) {
                TagsView()
            }
            .sheet(isPresented: $showingImportExport) {
                ImportExportView()
            }
            .sheet(isPresented: $showingResetDelete) {
                ResetDeleteView()
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