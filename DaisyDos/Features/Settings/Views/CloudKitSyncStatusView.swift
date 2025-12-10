//
//  CloudKitSyncStatusView.swift
//  DaisyDos
//
//  Created by Claude Code on 12/08/25.
//

import SwiftUI

struct CloudKitSyncStatusView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalOnlyModeManager.self) private var localOnlyModeManager
    @Environment(AppearanceManager.self) private var appearanceManager
    @Environment(CloudKitSyncManager.self) private var syncManager: CloudKitSyncManager?
    @Environment(NetworkMonitor.self) private var networkMonitor: NetworkMonitor?
    @Environment(OfflineQueueManager.self) private var queueManager: OfflineQueueManager?

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Sync Status
                Section("Sync Status") {
                    if let syncManager = syncManager {
                        HStack {
                            Label("Status", systemImage: "arrow.triangle.2.circlepath")
                            Spacer()
                            Text(syncManager.syncStatus.displayText)
                                .foregroundColor(syncStatusColor)
                        }

                        if let lastSync = syncManager.lastSyncDate {
                            HStack {
                                Label("Last Sync", systemImage: "clock")
                                Spacer()
                                Text(formatDate(lastSync))
                                    .foregroundColor(.daisyTextSecondary)
                            }
                        } else {
                            HStack {
                                Label("Last Sync", systemImage: "clock")
                                Spacer()
                                Text("Never")
                                    .foregroundColor(.daisyTextSecondary)
                            }
                        }

                        if let queueManager = queueManager, queueManager.pendingChangesCount > 0 {
                            HStack {
                                Label("Pending Changes", systemImage: "tray.full")
                                Spacer()
                                Text("\(queueManager.pendingChangesCount)")
                                    .foregroundColor(.daisyTextSecondary)
                            }
                        }
                    } else {
                        Text("Sync manager not available")
                            .foregroundColor(.daisyTextSecondary)
                    }
                }

                // MARK: - iCloud Account
                Section("iCloud Account") {
                    HStack {
                        Label("Status", systemImage: "icloud")
                        Spacer()
                        Text(localOnlyModeManager.cloudKitStatusDescription)
                            .foregroundColor(cloudKitStatusColor)
                    }

                    if localOnlyModeManager.cloudKitStatus != .available {
                        Text("Sign into iCloud in Settings to enable sync")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }

                // MARK: - Network
                Section("Network") {
                    if let networkMonitor = networkMonitor {
                        HStack {
                            Label("Connection", systemImage: "wifi")
                            Spacer()
                            Text(networkMonitor.statusDescription)
                                .foregroundColor(networkMonitor.isConnected ? .green : .red)
                        }

                        if !networkMonitor.isConnected {
                            Text("Sync will resume when connection is restored")
                                .font(.caption)
                                .foregroundColor(.daisyTextSecondary)
                        }
                    }
                }

                // MARK: - Actions
                Section {
                    Button(action: {
                        syncManager?.startManualSync()
                    }) {
                        Label("Sync Now", systemImage: "arrow.triangle.2.circlepath.circle")
                            .foregroundColor(.blue)
                    }
                    .disabled(syncManager?.isSyncing ?? false || networkMonitor?.isConnected == false)

                    if queueManager != nil && (queueManager?.pendingChangesCount ?? 0) > 0 {
                        Button(action: {
                            queueManager?.clearQueue()
                        }) {
                            Label("Clear Pending Queue", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }

                // MARK: - Information
                Section("About iCloud Sync") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("iCloud sync keeps your tasks, habits, and tags synchronized across all your devices signed into the same iCloud account.")
                            .font(.caption)

                        Text("Your data is stored in your private iCloud database and is not accessible to anyone else.")
                            .font(.caption)

                        Text("Sync requires an active internet connection and sufficient iCloud storage.")
                            .font(.caption)
                    }
                    .foregroundColor(.daisyTextSecondary)
                }
            }
            .navigationTitle("iCloud Sync")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .applyAppearance(appearanceManager)
    }

    private var syncStatusColor: Color {
        guard let syncManager = syncManager else { return .gray }

        switch syncManager.syncStatus {
        case .idle:
            return .gray
        case .syncing:
            return .blue
        case .synced:
            return .green
        case .error:
            return .red
        }
    }

    private var cloudKitStatusColor: Color {
        switch localOnlyModeManager.cloudKitStatus {
        case .available:
            return .green
        case .unknown:
            return .gray
        default:
            return .orange
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    CloudKitSyncStatusView()
        .environment(LocalOnlyModeManager())
        .environment(AppearanceManager())
}
