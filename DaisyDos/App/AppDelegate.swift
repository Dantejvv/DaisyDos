//
//  AppDelegate.swift
//  DaisyDos
//
//  Created by Claude Code on 1/16/26.
//

import UIKit
import UserNotifications

/// AppDelegate for handling app lifecycle events that require early setup.
/// Primary purpose: Set UNUserNotificationCenterDelegate in didFinishLaunchingWithOptions
/// to ensure notification responses are captured on cold start.
class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Dependencies (injected from DaisyDosApp)

    /// NavigationManager for handling notification-triggered navigation
    /// Must be set before didFinishLaunchingWithOptions is called
    var navigationManager: NavigationManager?

    // MARK: - Notification Delegate

    /// Holds strong reference to prevent deallocation
    var notificationDelegate: NotificationDelegate?

    // MARK: - UIApplicationDelegate

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // Set up notification delegate early to catch cold start notification taps
        // This MUST happen in didFinishLaunchingWithOptions, not in SwiftUI .task { }
        // because iOS delivers notification responses immediately on app launch
        if let navManager = navigationManager {
            let delegate = NotificationDelegate(navigationManager: navManager)
            notificationDelegate = delegate
            UNUserNotificationCenter.current().delegate = delegate

            #if DEBUG
            print("AppDelegate: Notification delegate set in didFinishLaunchingWithOptions")
            #endif
        } else {
            #if DEBUG
            print("AppDelegate: WARNING - navigationManager not set before didFinishLaunchingWithOptions")
            #endif
        }

        // Register all notification categories (must be done once, together)
        registerNotificationCategories()

        return true
    }

    // MARK: - Notification Categories

    /// Register all notification categories at once (per Apple guidelines)
    /// This must be called once at launch with ALL categories together,
    /// as setNotificationCategories replaces (not merges) existing categories.
    private func registerNotificationCategories() {
        // Task actions - no .foreground option so actions run in background without launching app
        let completeTaskAction = UNNotificationAction(
            identifier: "complete_task",
            title: "Mark Complete ✓",
            options: []
        )
        let snoozeTaskAction = UNNotificationAction(
            identifier: "snooze_task",
            title: "Snooze 1 Hour",
            options: []
        )
        let taskCategory = UNNotificationCategory(
            identifier: "task_reminder",
            actions: [completeTaskAction, snoozeTaskAction],
            intentIdentifiers: [],
            options: []
        )

        // Habit actions - no .foreground option so actions run in background without launching app
        let completeHabitAction = UNNotificationAction(
            identifier: "complete_habit",
            title: "Mark Complete ✓",
            options: []
        )
        let skipHabitAction = UNNotificationAction(
            identifier: "skip_habit",
            title: "Skip Today",
            options: []
        )
        let snoozeHabitAction = UNNotificationAction(
            identifier: "snooze_habit",
            title: "Snooze 1 Hour",
            options: []
        )
        let habitCategory = UNNotificationCategory(
            identifier: "habit_reminder",
            actions: [completeHabitAction, skipHabitAction, snoozeHabitAction],
            intentIdentifiers: [],
            options: []
        )

        // Register BOTH categories in a single call
        UNUserNotificationCenter.current().setNotificationCategories([taskCategory, habitCategory])
    }
}
