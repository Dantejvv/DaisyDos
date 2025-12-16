//
//  NotificationPreferencesManager.swift
//  DaisyDos
//
//  Created by Claude Code on 12/15/25.
//

import Foundation
import Observation

/// Manages global notification preferences across the app
@Observable
class NotificationPreferencesManager {
    /// Global toggle for all notifications (tasks and habits)
    /// When false, no notifications will be scheduled regardless of individual item settings
    var isGlobalNotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isGlobalNotificationsEnabled, forKey: UserDefaultsKeys.globalNotificationsEnabled)

            // Notify both task and habit notification managers
            NotificationCenter.default.post(
                name: .globalNotificationSettingChanged,
                object: nil,
                userInfo: ["enabled": isGlobalNotificationsEnabled]
            )
        }
    }

    init() {
        // Default to true for fresh installs
        // If key doesn't exist, registerDefaults ensures it starts as true
        UserDefaults.standard.register(defaults: [
            UserDefaultsKeys.globalNotificationsEnabled: true
        ])

        self.isGlobalNotificationsEnabled = UserDefaults.standard.bool(forKey: UserDefaultsKeys.globalNotificationsEnabled)
    }
}

// MARK: - UserDefaults Keys

private enum UserDefaultsKeys {
    static let globalNotificationsEnabled = "globalNotificationsEnabled"
}

// MARK: - Notification Names

extension Notification.Name {
    static let globalNotificationSettingChanged = Notification.Name("globalNotificationSettingChanged")
}
