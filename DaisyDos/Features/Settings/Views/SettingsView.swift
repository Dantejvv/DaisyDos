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
    @State private var showingAbout = false
    @State private var showingTestViews = false

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
                        .foregroundColor(.secondary)
                }

                Section("Data Overview") {
                    HStack {
                        Label("Tasks", systemImage: "list.bullet")
                        Spacer()
                        Text("\(taskManager.taskCount)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Habits", systemImage: "repeat.circle")
                        Spacer()
                        Text("\(habitManager.habitCount)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Label("Tags", systemImage: "tag")
                        Spacer()
                        Text("\(tagManager.tagCount)")
                            .foregroundColor(.secondary)
                    }
                }

                Section("App Information") {
                    Button(action: { showingAbout = true }) {
                        Label("About DaisyDos", systemImage: "questionmark.circle")
                    }

                    Button(action: { showingTestViews = true }) {
                        Label("Developer Tools", systemImage: "hammer.circle")
                    }

                    HStack {
                        Label("Version", systemImage: "apps.iphone")
                        Spacer()
                        Text("1.0.0 Beta")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingTestViews) {
                DeveloperToolsView()
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
                        .foregroundColor(.blue)

                    Text("DaisyDos")
                        .font(.largeTitle.bold())

                    Text("A unified productivity app for tasks and habits")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text("DaisyDos combines task management and habit tracking in a single, privacy-first application. Built with SwiftUI and SwiftData, it focuses on simplicity, accessibility, and keeping your data private.")
                        .font(.body)
                        .foregroundColor(.secondary)
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

// MARK: - Developer Tools View

private struct DeveloperToolsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TabView {
                ModelTestView()
                    .tabItem {
                        Label("Models", systemImage: "hammer.circle")
                    }

                ManagerTestView()
                    .tabItem {
                        Label("Managers", systemImage: "gearshape.circle")
                    }

                ErrorHandlingTestView()
                    .tabItem {
                        Label("Errors", systemImage: "exclamationmark.triangle.fill")
                    }

                DesignSystemTestView()
                    .tabItem {
                        Label("Design", systemImage: "paintpalette.fill")
                    }

                ComponentTestView()
                    .tabItem {
                        Label("Components", systemImage: "square.stack.3d.up.fill")
                    }
            }
            .navigationTitle("Developer Tools")
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