//
//  CloudKitSyncManager.swift
//  DaisyDos
//
//  Created by Claude Code on 12/08/25.
//

import Foundation
import SwiftData
import CloudKit
import CoreData
import Combine

@Observable
class CloudKitSyncManager {

    // MARK: - Properties

    private let modelContext: ModelContext

    /// Current sync status
    var syncStatus: SyncStatus = .idle

    /// Last successful sync timestamp
    var lastSyncDate: Date?

    /// Current sync error
    var syncError: Error?

    /// Number of pending changes waiting to sync
    var pendingChangesCount: Int = 0

    /// Whether sync is currently in progress
    var isSyncing: Bool {
        syncStatus == .syncing
    }

    // MARK: - Sync Status

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case error(String)

        var displayText: String {
            switch self {
            case .idle:
                return "Ready to sync"
            case .syncing:
                return "Syncing..."
            case .synced:
                return "Synced"
            case .error(let message):
                return "Error: \(message)"
            }
        }
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupSyncMonitoring()
    }

    // MARK: - Sync Monitoring

    private func setupSyncMonitoring() {
        // Monitor NSPersistentCloudKitContainer notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitImportNotification(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil
        )
    }

    @objc private func handleCloudKitImportNotification(_ notification: Notification) {
        guard let cloudKitEvent = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            switch cloudKitEvent.type {
            case .setup:
                #if DEBUG
                print("☁️ CloudKit setup event")
                #endif

            case .import:
                self?.syncStatus = .syncing
                #if DEBUG
                print("☁️ CloudKit import started")
                #endif

            case .export:
                self?.syncStatus = .syncing
                #if DEBUG
                print("☁️ CloudKit export started")
                #endif

            @unknown default:
                break
            }

            // Check if event succeeded or failed
            if cloudKitEvent.succeeded {
                self?.syncStatus = .synced
                self?.lastSyncDate = Date()
                self?.syncError = nil
                #if DEBUG
                print("✅ CloudKit sync succeeded")
                #endif
            } else if let error = cloudKitEvent.error {
                self?.syncStatus = .error(error.localizedDescription)
                self?.syncError = error
                #if DEBUG
                print("❌ CloudKit sync failed: \(error.localizedDescription)")
                #endif
            }
        }
    }

    // MARK: - Manual Sync

    /// Trigger a manual sync operation
    func startManualSync() {
        #if DEBUG
        print("🔄 Manual sync requested")
        #endif

        syncStatus = .syncing

        do {
            try modelContext.save()
            // CloudKit will automatically sync after save
            #if DEBUG
            print("✅ Context saved, CloudKit sync will follow automatically")
            #endif
        } catch {
            syncStatus = .error(error.localizedDescription)
            syncError = error
            #if DEBUG
            print("❌ Failed to save context: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Conflict Resolution

    /// Handle merge conflicts using last-write-wins strategy
    func handleConflict<T: PersistentModel>(local: T, remote: T) -> ConflictResolution {
        // Get modification dates
        let localDate = getModificationDate(from: local)
        let remoteDate = getModificationDate(from: remote)

        // Last-write-wins: Keep the version with the newer modification date
        if remoteDate > localDate {
            #if DEBUG
            print("🔀 Conflict resolved: Remote version is newer, using remote")
            #endif
            return .useRemote
        } else {
            #if DEBUG
            print("🔀 Conflict resolved: Local version is newer, using local")
            #endif
            return .useLocal
        }
    }

    /// Extract modification date from a model
    private func getModificationDate<T: PersistentModel>(from model: T) -> Date {
        // Use reflection to find modifiedDate or lastModifiedDate property
        let mirror = Mirror(reflecting: model)

        for child in mirror.children {
            if let label = child.label {
                if label == "modifiedDate" || label == "lastModifiedDate" {
                    if let date = child.value as? Date {
                        return date
                    }
                }
            }
        }

        // Fallback to epoch if no modification date found
        return Date(timeIntervalSince1970: 0)
    }

    /// Conflict resolution strategy
    enum ConflictResolution {
        case useLocal
        case useRemote
        case merge
        case askUser
    }

    // MARK: - Sync Statistics

    /// Get a summary of sync status
    var syncSummary: String {
        guard let lastSync = lastSyncDate else {
            return "Never synced"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Last synced \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
    }

    /// Check if CloudKit is actively syncing
    var isCloudKitActive: Bool {
        // Check if we have a non-nil cloudKitDatabase configuration
        // This is determined at app launch based on LocalOnlyModeManager
        return !UserDefaults.standard.bool(forKey: "localOnlyMode")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
