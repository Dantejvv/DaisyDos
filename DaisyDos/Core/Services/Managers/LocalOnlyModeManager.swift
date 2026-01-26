//
//  LocalOnlyModeManager.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftUI
import CloudKit

@Observable
class LocalOnlyModeManager {
    /// Controls whether the app operates in local-only mode (privacy-first default)
    var isLocalOnlyMode: Bool {
        get {
            UserDefaults.standard.object(forKey: "localOnlyMode") as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "localOnlyMode")
        }
    }

    /// Tracks CloudKit availability status
    private(set) var cloudKitStatus: CloudKitStatus = .unknown

    /// CloudKit availability states
    enum CloudKitStatus: Equatable {
        case unknown
        case available
        case noAccount
        case restricted
        case temporarilyUnavailable
        case error(String)
    }

    init() {
        // Only check CloudKit status if user has enabled sync
        // This avoids CloudKit entitlement errors in local-only mode
        if !isLocalOnlyMode {
            checkCloudKitStatus()
        }
    }

    /// Disables CloudKit sync and switches to local-only mode
    /// Note: Requires app restart to take effect
    func enableLocalOnlyMode() {
        isLocalOnlyMode = true
        UserDefaults.standard.set(true, forKey: "localOnlyMode")

        #if DEBUG
        print("✅ Switched to local-only mode. App restart required to disable sync.")
        #endif
    }

    /// Checks CloudKit account status
    private func checkCloudKitStatus() {
        let container = CKContainer(identifier: "iCloud.com.BKD7HH7ZDH.DaisyDos")

        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.cloudKitStatus = .error(error.localizedDescription)
                    return
                }

                switch status {
                case .available:
                    self?.cloudKitStatus = .available
                case .noAccount:
                    self?.cloudKitStatus = .noAccount
                case .restricted:
                    self?.cloudKitStatus = .restricted
                case .temporarilyUnavailable:
                    self?.cloudKitStatus = .temporarilyUnavailable
                case .couldNotDetermine:
                    self?.cloudKitStatus = .error("Could not determine account status")
                @unknown default:
                    self?.cloudKitStatus = .error("Unknown account status")
                }
            }
        }
    }

    /// Provides user-friendly description of CloudKit status
    var cloudKitStatusDescription: String {
        switch cloudKitStatus {
        case .unknown:
            return "Checking iCloud status..."
        case .available:
            return "iCloud available"
        case .noAccount:
            return "No iCloud account configured"
        case .restricted:
            return "iCloud account restricted"
        case .temporarilyUnavailable:
            return "iCloud temporarily unavailable"
        case .error(let message):
            return "iCloud error: \(message)"
        }
    }

    /// Indicates whether CloudKit sync could be enabled
    var canEnableCloudSync: Bool {
        return cloudKitStatus == .available && !isLocalOnlyMode
    }
}