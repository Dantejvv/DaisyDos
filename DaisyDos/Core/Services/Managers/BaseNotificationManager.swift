//
//  BaseNotificationManager.swift
//  DaisyDos
//
//  Created by Claude Code on 12/01/25.
//

import Foundation
import UserNotifications
import SwiftData

/// Base protocol for notification managers providing shared permission and action management
protocol BaseNotificationManager: AnyObject {
    // MARK: - Required Properties

    /// The model context for database operations
    var modelContext: ModelContext { get }

    /// The notification center instance
    var notificationCenter: UNUserNotificationCenter { get }

    /// Current authorization status
    var authorizationStatus: UNAuthorizationStatus { get set }

    /// Whether permission is granted
    var isPermissionGranted: Bool { get set }

    /// Whether notifications are enabled
    var isNotificationsEnabled: Bool { get set }

    // MARK: - Required Methods

    /// Register notification actions for this notification type
    func registerNotificationActions() async

    /// Get the notification category identifier for this notification type
    var notificationCategoryIdentifier: String { get }
}

// MARK: - Default Implementations

extension BaseNotificationManager {

    // MARK: - Permission Management

    /// Request notification permissions from the user
    func requestNotificationPermissions() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )

            await MainActor.run {
                self.isPermissionGranted = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }

            if granted {
                await registerNotificationActions()
            }

            return granted
        } catch {
            print("Failed to request notification permissions: \(error)")
            return false
        }
    }

    /// Check current notification permission status
    func checkNotificationPermissions() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
                self.isPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Notification Counting

    /// Get count of scheduled notifications for this notification type
    func getScheduledNotificationsCount(prefix: String) async -> Int {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        return pendingRequests.filter { $0.identifier.hasPrefix(prefix) }.count
    }

    // MARK: - Notification Removal

    /// Remove all notifications with a specific identifier prefix
    func removeNotifications(withPrefix prefix: String) async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let identifiers = pending
            .filter { $0.identifier.hasPrefix(prefix) }
            .map { $0.identifier }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
