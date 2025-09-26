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
        let schema = Schema(versionedSchema: DaisyDosSchemaV2.self)
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
        }
        .modelContainer(sharedModelContainer)
        .environment(navigationManager)
        .environment(localOnlyModeManager)
        .environment(PerformanceMonitor.shared)
        .environment(TaskManager(modelContext: sharedModelContainer.mainContext))
        .environment(HabitManager(modelContext: sharedModelContainer.mainContext))
        .environment(TagManager(modelContext: sharedModelContainer.mainContext))
    }
}
