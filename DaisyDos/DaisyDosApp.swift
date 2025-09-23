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

    var sharedModelContainer: ModelContainer = {
        let schema = Schema(versionedSchema: DaisyDosSchemaV1.self)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        #if DEBUG
        // Initialize CloudKit schema for development (disabled by default)
        // This is only for schema preparation and does not enable sync
        do {
            try CloudKitManager.initializeCloudKitSchemaIfNeeded()
            print("CloudKit schema initialization completed (DEBUG mode)")
        } catch {
            print("CloudKit schema initialization failed: \(error.localizedDescription)")
        }
        #endif

        do {
            return try ModelContainer(for: schema, migrationPlan: DaisyDosMigrationPlan.self, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .environment(localOnlyModeManager)
    }
}
