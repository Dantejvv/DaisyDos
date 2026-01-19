//
//  ContentView.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import SwiftUI
import SwiftData
import UserNotifications

struct ContentView: View {
    @Environment(NavigationManager.self) private var navigationManager
    @Environment(TaskNotificationManager.self) private var taskNotificationManager
    @Environment(HabitNotificationManager.self) private var habitNotificationManager
    @Environment(BadgeManager.self) private var badgeManager: BadgeManager?
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
                    .navigationDestination(for: TodayRoute.self) { route in
                        switch route {
                        case .taskDetail(let task):
                            TaskDetailView(task: task)
                        case .habitDetail(let habit):
                            HabitDetailView(habit: habit)
                        }
                    }
            }
            .tabItem {
                TabType.today.tabLabel
            }
            .tag(TabType.today)

            // MARK: - Tasks Tab

            NavigationStack(path: navigationManager.pathBinding(for: .tasks)) {
                TasksView()
                    .navigationDestination(for: TasksRoute.self) { route in
                        switch route {
                        case .detail(let task):
                            TaskDetailView(task: task)
                        case .logbookDetail(let task):
                            TaskDetailView(task: task, isLogbookMode: true)
                        }
                    }
            }
            .tabItem {
                TabType.tasks.tabLabel
            }
            .tag(TabType.tasks)

            // MARK: - Habits Tab

            NavigationStack(path: navigationManager.pathBinding(for: .habits)) {
                HabitsView()
                    .navigationDestination(for: HabitsRoute.self) { route in
                        switch route {
                        case .detail(let habit):
                            HabitDetailView(habit: habit)
                        }
                    }
            }
            .tabItem {
                TabType.habits.tabLabel
            }
            .tag(TabType.habits)

            // MARK: - Logbook Tab

            NavigationStack(path: navigationManager.pathBinding(for: .logbook)) {
                LogbookView()
                    .navigationDestination(for: LogbookRoute.self) { route in
                        switch route {
                        case .taskDetail(let task):
                            TaskDetailView(task: task, isLogbookMode: true)
                        }
                    }
            }
            .tabItem {
                TabType.logbook.tabLabel
            }
            .tag(TabType.logbook)

            // MARK: - Settings Tab

            NavigationStack(path: navigationManager.pathBinding(for: .settings)) {
                SettingsView()
                    .navigationDestination(for: SettingsRoute.self) { _ in
                        // Future settings sub-pages can be handled here
                        EmptyView()
                    }
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
                // Re-check notification permissions and update badge when app returns to foreground
                if newPhase == .active {
                    taskNotificationManager.checkNotificationPermissions()
                    habitNotificationManager.checkNotificationPermissions()

                    // Mark delivered notifications as fired and update badge
                    // This handles notifications delivered while app was in background
                    // (customDismissAction callbacks are unreliable when app is backgrounded)
                    let center = UNUserNotificationCenter.current()
                    _Concurrency.Task {
                        if let delegate = center.delegate as? NotificationDelegate {
                            await delegate.markDeliveredNotificationsAsFired()
                        }

                        // Clear delivered notifications from notification center
                        center.removeAllDeliveredNotifications()

                        // Update badge to reflect current actionable items
                        // (replaces old behavior of clearing to 0)
                        await badgeManager?.updateBadge()
                    }
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
