//
//  ContentView.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(NavigationManager.self) private var navigationManager
    @Environment(TaskNotificationManager.self) private var taskNotificationManager
    @Environment(HabitNotificationManager.self) private var habitNotificationManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TaskCompletionToastContainer(config: .task()) {
            HabitCompletionToastContainer(config: .habit()) {
            TabView(selection: Binding(
                get: { navigationManager.selectedTab },
                set: { navigationManager.selectedTab = $0 }
            )) {

            // MARK: - Today Tab

            NavigationStack(path: navigationManager.pathBinding(for: .today)) {
                TodayView()
                    .navigationDestination(for: Task.self) { task in
                        TaskDetailView(task: task)
                    }
                    .navigationDestination(for: Habit.self) { habit in
                        HabitDetailView(habit: habit)
                    }
            }
            .tabItem {
                TabType.today.tabLabel
            }
            .tag(TabType.today)

            // MARK: - Tasks Tab

            NavigationStack(path: navigationManager.pathBinding(for: .tasks)) {
                TasksView()
                    .navigationDestination(for: Task.self) { task in
                        TaskDetailView(task: task)
                    }
            }
            .tabItem {
                TabType.tasks.tabLabel
            }
            .tag(TabType.tasks)

            // MARK: - Habits Tab

            NavigationStack(path: navigationManager.pathBinding(for: .habits)) {
                HabitsView()
                    .navigationDestination(for: Habit.self) { habit in
                        HabitDetailView(habit: habit)
                    }
            }
            .tabItem {
                TabType.habits.tabLabel
            }
            .tag(TabType.habits)

            // MARK: - Logbook Tab

            NavigationStack(path: navigationManager.pathBinding(for: .logbook)) {
                LogbookView()
                    .navigationDestination(for: Task.self) { task in
                        TaskDetailView(task: task)
                    }
            }
            .tabItem {
                TabType.logbook.tabLabel
            }
            .tag(TabType.logbook)

            // MARK: - Settings Tab

            NavigationStack(path: navigationManager.pathBinding(for: .settings)) {
                SettingsView()
            }
            .tabItem {
                TabType.settings.tabLabel
            }
            .tag(TabType.settings)
            }
            .accessibilityLabel("Main navigation")
            .accessibilityHint("Navigate between different sections of the app")
            .alert("Navigation Error", isPresented: Binding(
                get: { navigationManager.showingErrorAlert },
                set: { navigationManager.showingErrorAlert = $0 }
            )) {
                Button("OK", role: .cancel) {
                    navigationManager.showingErrorAlert = false
                }
            } message: {
                if let errorMessage = navigationManager.errorMessage {
                    Text(errorMessage)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                // Re-check notification permissions when app returns to foreground
                if newPhase == .active {
                    taskNotificationManager.checkNotificationPermissions()
                    habitNotificationManager.checkNotificationPermissions()
                }
            }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: Task.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    return ContentView()
        .modelContainer(container)
        .environment(NavigationManager())
        .environment(TaskManager(modelContext: container.mainContext))
        .environment(HabitManager(modelContext: container.mainContext))
        .environment(TagManager(modelContext: container.mainContext))
        .environment(LocalOnlyModeManager())
}
