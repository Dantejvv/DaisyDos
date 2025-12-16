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
struct DaisyDosApp: App {
    let localOnlyModeManager = LocalOnlyModeManager()
    let appearanceManager = AppearanceManager()
    let navigationManager = NavigationManager()
    let notificationPreferencesManager = NotificationPreferencesManager()

    // CloudKit and network managers
    @State private var cloudKitSyncManager: CloudKitSyncManager?
    @State private var networkMonitor: NetworkMonitor?
    @State private var offlineQueueManager: OfflineQueueManager?

    // Store notification delegate to prevent deallocation
    @State private var notificationDelegate: NotificationDelegate?

    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: DaisyDosSchemaV7.self)

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

                    // Create and set up notification delegate (stored to prevent deallocation)
                    let taskManager = TaskManager(modelContext: sharedModelContainer.mainContext)
                    let habitMgr = HabitManager(modelContext: sharedModelContainer.mainContext)
                    let taskNotificationManager = TaskNotificationManager(modelContext: sharedModelContainer.mainContext)
                    let delegate = NotificationDelegate(
                        navigationManager: navigationManager,
                        habitManager: habitMgr,
                        taskManager: taskManager,
                        taskNotificationManager: taskNotificationManager
                    )
                    notificationDelegate = delegate
                    UNUserNotificationCenter.current().delegate = delegate

                    // Run logbook housekeeping on app launch (if needed)
                    await runLogbookHousekeepingIfNeeded()
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
        .environment(cloudKitSyncManager)
        .environment(networkMonitor)
        .environment(offlineQueueManager)
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
}
