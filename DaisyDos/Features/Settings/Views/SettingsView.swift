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
    @Environment(TaskManager.self) private var taskManager
    @Environment(HabitManager.self) private var habitManager
    @Environment(TagManager.self) private var tagManager
    @Environment(LogbookManager.self) private var logbookManager
    @Environment(HabitNotificationManager.self) private var notificationManager: HabitNotificationManager?
    @State private var showingAbout = false
    @State private var showingNotificationSettings = false
    @State private var showingTagManagement = false

    var body: some View {
        NavigationStack {
            List {
                Section("Privacy") {
                    HStack {
                        Label("Local-Only Mode", systemImage: "lock.shield")
                        Spacer()
                        Toggle("", isOn: .constant(true))
                            .disabled(true)
                    }
                    Text("DaisyDos keeps your data private by default.")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }

                Section("Notifications") {
                    Button(action: { showingNotificationSettings = true }) {
                        HStack {
                            Label("Habit Reminders", systemImage: "bell")
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
                    .foregroundColor(.daisyText)
                }

                Section("Data Overview") {
                    HStack {
                        Label("Tasks", systemImage: "list.bullet")
                        Spacer()
                        Text("\(taskManager.taskCount)")
                            .foregroundColor(.daisyTextSecondary)
                    }
                    HStack {
                        Label("Habits", systemImage: "repeat.circle")
                        Spacer()
                        Text("\(habitManager.habitCount)")
                            .foregroundColor(.daisyTextSecondary)
                    }
                    Button(action: { showingTagManagement = true }) {
                        HStack {
                            Label("Tags", systemImage: "tag")
                            Spacer()
                            Text("\(tagManager.tagCount)")
                                .foregroundColor(.daisyTextSecondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                        }
                    }
                    .foregroundColor(.daisyText)
                }

                Section("App Information") {
                    Button(action: { showingAbout = true }) {
                        Label("About DaisyDos", systemImage: "questionmark.circle")
                    }

                    HStack {
                        Label("Version", systemImage: "apps.iphone")
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
            .sheet(isPresented: $showingNotificationSettings) {
                if notificationManager != nil {
                    HabitNotificationSettingsView()
                }
            }
            .sheet(isPresented: $showingTagManagement) {
                TagsView()
            }
        }
    }
}

// MARK: - About View

private struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "flower")
                        .font(.system(size: 64))
                        .foregroundColor(.daisyCTA)

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