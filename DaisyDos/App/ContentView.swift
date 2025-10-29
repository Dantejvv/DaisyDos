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
                    .navigationDestination(for: String.self) { _ in
                        // TODO: Add navigation destinations in future phases
                        Text("Navigation destination placeholder")
                    }
            }
            .tabItem {
                TabType.today.tabLabel
            }
            .tag(TabType.today)

            // MARK: - Tasks Tab

            NavigationStack(path: navigationManager.pathBinding(for: .tasks)) {
                TasksView()
                    .navigationDestination(for: String.self) { _ in
                        // TODO: Add navigation destinations in future phases
                        Text("Navigation destination placeholder")
                    }
            }
            .tabItem {
                TabType.tasks.tabLabel
            }
            .tag(TabType.tasks)

            // MARK: - Habits Tab

            NavigationStack(path: navigationManager.pathBinding(for: .habits)) {
                HabitsView()
                    .navigationDestination(for: String.self) { _ in
                        // TODO: Add navigation destinations in future phases
                        Text("Navigation destination placeholder")
                    }
            }
            .tabItem {
                TabType.habits.tabLabel
            }
            .tag(TabType.habits)

            // MARK: - Logbook Tab

            NavigationStack(path: navigationManager.pathBinding(for: .logbook)) {
                LogbookView()
                    .navigationDestination(for: String.self) { _ in
                        // TODO: Add navigation destinations in future phases
                        Text("Navigation destination placeholder")
                    }
            }
            .tabItem {
                TabType.logbook.tabLabel
            }
            .tag(TabType.logbook)

            // MARK: - Settings Tab

            NavigationStack(path: navigationManager.pathBinding(for: .settings)) {
                SettingsView()
                    .navigationDestination(for: String.self) { _ in
                        // TODO: Add navigation destinations in future phases
                        Text("Navigation destination placeholder")
                    }
            }
            .tabItem {
                TabType.settings.tabLabel
            }
            .tag(TabType.settings)
            }
            .accessibilityLabel("Main navigation")
            .accessibilityHint("Navigate between different sections of the app")
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
