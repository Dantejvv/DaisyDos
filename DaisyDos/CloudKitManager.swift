//
//  CloudKitManager.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData
import CloudKit
import CoreData

class CloudKitManager {

    #if DEBUG
    /// Initializes CloudKit schema for development/debugging purposes only
    /// This function should NEVER be called in production builds
    static func initializeCloudKitSchemaIfNeeded() throws {
        // Use autorelease pool to ensure proper cleanup before setting up SwiftData stack
        try autoreleasepool {
            let config = ModelConfiguration()
            let desc = NSPersistentStoreDescription(url: config.url)
            let opts = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.yourteam.DaisyDos")
            desc.cloudKitContainerOptions = opts
            desc.shouldAddStoreAsynchronously = false

            // Create managed object model for current schema
            if let mom = NSManagedObjectModel.makeManagedObjectModel(for: [Item.self]) {
                let container = NSPersistentCloudKitContainer(name: "DaisyDos", managedObjectModel: mom)
                container.persistentStoreDescriptions = [desc]

                container.loadPersistentStores { _, error in
                    if let error = error {
                        print("CloudKit schema initialization failed: \(error.localizedDescription)")
                        return
                    }
                }

                // Initialize the CloudKit schema after the store finishes loading
                try container.initializeCloudKitSchema()

                // Clean up: Remove and unload the store from the persistent container
                if let store = container.persistentStoreCoordinator.persistentStores.first {
                    try container.persistentStoreCoordinator.remove(store)
                }
            }
        }
    }
    #endif

    /// Validates CloudKit availability and configuration
    static func validateCloudKitConfiguration() -> Bool {
        // CloudKit validation will be implemented when sync is enabled
        // For now, just return true since we're in local-only mode
        return true
    }
}