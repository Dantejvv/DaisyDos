//
//  DaisyDosApp.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import SwiftUI
import SwiftData
import CloudKit
#if canImport(PhotoKit)
import PhotoKit
#endif
import UserNotifications

@main
// Entry point --> sets up services, managers, and global state, then hands control to ContentView.
struct DaisyDosApp: App {
    @Environment(\.scenePhase) private var scenePhase

    /// AppDelegate for handling notification delegate setup in didFinishLaunchingWithOptions.
    /// This ensures the delegate is registered early enough to catch cold start notification taps.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let localOnlyModeManager = LocalOnlyModeManager()
    let appearanceManager = AppearanceManager()
    let navigationManager = NavigationManager()
    let notificationPreferencesManager = NotificationPreferencesManager()

    // CloudKit and network managers
    @State private var cloudKitSyncManager: CloudKitSyncManager?
    @State private var networkMonitor: NetworkMonitor?
    @State private var offlineQueueManager: OfflineQueueManager?

    // Recurrence scheduler for deferred task creation
    @State private var recurrenceScheduler: RecurrenceScheduler?

    // MARK: - Initialization

    init() {
        // Pass navigationManager to AppDelegate so it can create the NotificationDelegate
        // in didFinishLaunchingWithOptions (before .task { } runs)
        // This fixes the cold start notification bug where the delegate wasn't set early enough
        appDelegate.navigationManager = navigationManager
    }

    // Shared model container - created first so managers can use its context
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: DaisyDosSchemaV8.self)

        // Dynamic CloudKit configuration based on LocalOnlyModeManager
        // Note: Changing this requires app restart, handled in LocalOnlyModeManager
        // Default to true (local-only) if key doesn't exist - privacy-first approach
        let isLocalOnly = UserDefaults.standard.object(forKey: "localOnlyMode") as? Bool ?? true
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = isLocalOnly ? .none : .automatic

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: cloudKitDatabase
        )

        #if DEBUG
        // CloudKit schema initialization for development
        // Only runs in DEBUG builds to set up CloudKit schema
        if !isLocalOnly {
            do {
                try CloudKitManager.initializeCloudKitSchemaIfNeeded()
                print("✅ CloudKit schema initialization completed (DEBUG mode)")
            } catch {
                print("⚠️ CloudKit schema initialization failed: \(error.localizedDescription)")
            }
        }
        #endif

        do {
            // No migration plan - we don't have user data to migrate yet
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Clear any orphaned badge on app launch
                    await clearBadgeOnLaunch()

                    // Set ModelContext on NavigationManager for deep linking entity fetches
                    navigationManager.setModelContext(sharedModelContainer.mainContext)

                    // Initialize CloudKit managers if sync is enabled
                    if !localOnlyModeManager.isLocalOnlyMode {
                        cloudKitSyncManager = CloudKitSyncManager(modelContext: sharedModelContainer.mainContext)
                        networkMonitor = NetworkMonitor()
                        offlineQueueManager = OfflineQueueManager(
                            modelContext: sharedModelContainer.mainContext,
                            networkMonitor: networkMonitor!
                        )
                    }

                    // Inject managers into the NotificationDelegate that was created in AppDelegate.
                    // The delegate was registered early in didFinishLaunchingWithOptions to catch cold start
                    // notification taps. Now that SwiftData is ready, we can inject the managers.
                    // This processes any pending actions/markFired calls that arrived before managers were ready.
                    let taskManager = TaskManager(modelContext: sharedModelContainer.mainContext)
                    let habitMgr = HabitManager(modelContext: sharedModelContainer.mainContext)
                    let taskNotifMgr = TaskNotificationManager(modelContext: sharedModelContainer.mainContext)
                    let habitNotifMgr = HabitNotificationManager(modelContext: sharedModelContainer.mainContext)
                    appDelegate.notificationDelegate?.setManagers(
                        habitManager: habitMgr,
                        taskManager: taskManager,
                        taskNotificationManager: taskNotifMgr,
                        habitNotificationManager: habitNotifMgr
                    )

                    // Initialize recurrence scheduler
                    recurrenceScheduler = RecurrenceScheduler(modelContext: sharedModelContainer.mainContext)

                    // Process any pending recurrences on app launch
                    await processPendingRecurrences()

                    // Run logbook housekeeping on app launch (if needed)
                    await runLogbookHousekeepingIfNeeded()

                    // Mark navigation system as ready after all initialization is complete
                    // This processes any pending navigation from notification cold start
                    navigationManager.markReady()
                }
                .onChange(of: scenePhase) {
                    // Process pending recurrences when app comes to foreground
                    if scenePhase == .active {
                        _Concurrency.Task {
                            await processPendingRecurrences()
                        }
                    }
                }
                .onOpenURL { url in
                    // Handle deep links from external sources
                    navigationManager.handleDeepLink(url: url)
                }
                .applyAppearance(appearanceManager)
        }
        .modelContainer(sharedModelContainer)
        .environment(navigationManager)
        .environment(localOnlyModeManager)
        .environment(appearanceManager)
        .environment(notificationPreferencesManager)
        .environment(TaskManager(modelContext: sharedModelContainer.mainContext))
        .environment(TaskNotificationManager(modelContext: sharedModelContainer.mainContext))
        .environment(HabitManager(modelContext: sharedModelContainer.mainContext))
        .environment(AnalyticsManager(modelContext: sharedModelContainer.mainContext))
        .environment(TagManager(modelContext: sharedModelContainer.mainContext))
        .environment(HabitNotificationManager(modelContext: sharedModelContainer.mainContext))
        .environment(LogbookManager(modelContext: sharedModelContainer.mainContext))
        .environment(recurrenceScheduler)
        .environment(cloudKitSyncManager)
        .environment(networkMonitor)
        .environment(offlineQueueManager)
    }

    // MARK: - Badge Management

    /// Clear any orphaned badge count on app launch
    private func clearBadgeOnLaunch() async {
        let center = UNUserNotificationCenter.current()
        // Remove all delivered notifications and clear badge
        center.removeAllDeliveredNotifications()
        try? await center.setBadgeCount(0)
    }

    // MARK: - Logbook Housekeeping

    /// Run logbook housekeeping if it hasn't run in the last 24 hours
    private func runLogbookHousekeepingIfNeeded() async {
        let lastRunKey = "lastLogbookHousekeeping"
        let lastRun = UserDefaults.standard.object(forKey: lastRunKey) as? Date
        let now = Date()

        // Run if never run or last run was >24 hours ago
        guard lastRun == nil || now.timeIntervalSince(lastRun!) > 86400 else {
            return
        }

        // Perform housekeeping in background
        let manager = LogbookManager(modelContext: sharedModelContainer.mainContext)
        let result = manager.performHousekeeping()

        switch result {
        case .success(let stats):
            #if DEBUG
            print("Logbook housekeeping completed: \(stats.tasksArchived) archived, \(stats.tasksDeleted) tasks deleted, \(stats.logsDeleted) logs deleted")
            #endif
            UserDefaults.standard.set(now, forKey: lastRunKey)

        case .failure(let error):
            #if DEBUG
            print("Logbook housekeeping failed: \(error.userMessage)")
            #endif
        }
    }

    // MARK: - Pending Recurrences

    /// Process pending recurrences that are ready (scheduled time has passed)
    private func processPendingRecurrences() async {
        guard let scheduler = recurrenceScheduler else { return }

        let result = scheduler.processPendingRecurrences()

        switch result {
        case .success(let createdTasks):
            if !createdTasks.isEmpty {
                #if DEBUG
                print("✅ Created \(createdTasks.count) recurring task(s) from pending recurrences")
                for task in createdTasks {
                    print("   - '\(task.title)' due \(task.dueDate?.formatted() ?? "no date")")
                }
                #endif
            }

        case .failure(let error):
            #if DEBUG
            print("❌ Failed to process pending recurrences: \(error.userMessage)")
            #endif
        }
    }

}
