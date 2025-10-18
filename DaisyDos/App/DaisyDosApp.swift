//
//  DaisyDosApp.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import SwiftUI
import SwiftData
import CloudKit
import EventKit
#if canImport(PhotoKit)
import PhotoKit
#endif
import UserNotifications

@main
struct DaisyDosApp: App {
    let localOnlyModeManager = LocalOnlyModeManager()
    let navigationManager = NavigationManager()

    // Performance monitoring
    init() {
        PerformanceMonitor.shared.markAppLaunchStart()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: DaisyDosSchemaV4.self)
        // Explicitly disable CloudKit for local-only mode
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none  // This disables CloudKit integration
        )

        #if DEBUG && false
        // CloudKit schema initialization disabled for Phase 1.6
        // This will be enabled in Phase 10.0 when CloudKit sync is implemented
        // The schema validation was causing issues with local-only mode
        do {
            try CloudKitManager.initializeCloudKitSchemaIfNeeded()
            print("CloudKit schema initialization completed (DEBUG mode)")
        } catch {
            print("CloudKit schema initialization failed: \(error.localizedDescription)")
        }
        #endif

        do {

            let container = try ModelContainer(for: schema, migrationPlan: DaisyDosMigrationPlan.self, configurations: [modelConfiguration])
            PerformanceMonitor.shared.markModelContainerInitComplete()
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Run logbook housekeeping on app launch (if needed)
                    await runLogbookHousekeepingIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
        .environment(navigationManager)
        .environment(localOnlyModeManager)
        .environment(PerformanceMonitor.shared)
        .environment(TaskManager(modelContext: sharedModelContainer.mainContext))
        .environment(HabitManager(modelContext: sharedModelContainer.mainContext))
        .environment(TagManager(modelContext: sharedModelContainer.mainContext))
        .environment(HabitNotificationManager(modelContext: sharedModelContainer.mainContext))
        .environment(LogbookManager(modelContext: sharedModelContainer.mainContext))
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
