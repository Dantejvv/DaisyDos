//
//  OfflineQueueManager.swift
//  DaisyDos
//
//  Created by Claude Code on 12/08/25.
//

import Foundation
import SwiftData

@Observable
class OfflineQueueManager {

    // MARK: - Properties

    private let modelContext: ModelContext
    private let networkMonitor: NetworkMonitor

    /// Number of pending changes in the queue
    var pendingChangesCount: Int = 0

    /// Whether the queue is currently being processed
    var isProcessingQueue: Bool = false

    /// Queue of pending operations
    private var operationQueue: [PendingOperation] = []

    // MARK: - Initialization

    init(modelContext: ModelContext, networkMonitor: NetworkMonitor) {
        self.modelContext = modelContext
        self.networkMonitor = networkMonitor

        // Load persisted queue
        loadQueue()

        // Monitor network status changes
        setupNetworkMonitoring()
    }

    // MARK: - Pending Operations

    struct PendingOperation: Codable {
        let id: UUID
        let type: OperationType
        let entityType: String
        let entityId: String
        let timestamp: Date
        var retryCount: Int

        enum OperationType: String, Codable {
            case create
            case update
            case delete
        }
    }

    // MARK: - Queue Management

    /// Add an operation to the queue
    func queueOperation(type: PendingOperation.OperationType, entityType: String, entityId: String) {
        let operation = PendingOperation(
            id: UUID(),
            type: type,
            entityType: entityType,
            entityId: entityId,
            timestamp: Date(),
            retryCount: 0
        )

        operationQueue.append(operation)
        pendingChangesCount = operationQueue.count
        persistQueue()

        #if DEBUG
        print("📝 Queued \(type.rawValue) operation for \(entityType)")
        #endif

        // Try to process immediately if online
        if networkMonitor.isConnected {
            processQueue()
        }
    }

    /// Process the queue when network becomes available
    private func processQueue() {
        guard !isProcessingQueue else { return }
        guard networkMonitor.isConnected else { return }
        guard !operationQueue.isEmpty else { return }

        isProcessingQueue = true

        #if DEBUG
        print("🔄 Processing offline queue (\(operationQueue.count) operations)")
        #endif

        do {
            // Attempt to save context, which will trigger CloudKit sync
            try modelContext.save()

            // Clear successful operations
            operationQueue.removeAll()
            pendingChangesCount = 0
            persistQueue()

            #if DEBUG
            print("✅ Offline queue processed successfully")
            #endif
        } catch {
            #if DEBUG
            print("❌ Failed to process offline queue: \(error.localizedDescription)")
            #endif

            // Increment retry count for failed operations
            for index in operationQueue.indices {
                operationQueue[index].retryCount += 1
            }

            // Remove operations that have failed too many times (>5 retries)
            operationQueue.removeAll { $0.retryCount > 5 }
            pendingChangesCount = operationQueue.count
            persistQueue()
        }

        isProcessingQueue = false
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        // Note: In a real implementation, we'd use Combine to observe networkMonitor.isConnected
        // For MVP, we'll manually call processQueue when needed

        // Create a timer that checks network status periodically
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.networkMonitor.isConnected && !self.operationQueue.isEmpty {
                self.processQueue()
            }
        }
    }

    // MARK: - Persistence

    private func persistQueue() {
        if let encoded = try? JSONEncoder().encode(operationQueue) {
            UserDefaults.standard.set(encoded, forKey: "offlineQueue")
        }
    }

    private func loadQueue() {
        if let data = UserDefaults.standard.data(forKey: "offlineQueue"),
           let decoded = try? JSONDecoder().decode([PendingOperation].self, from: data) {
            operationQueue = decoded
            pendingChangesCount = operationQueue.count

            #if DEBUG
            print("📂 Loaded \(operationQueue.count) operations from offline queue")
            #endif
        }
    }

    /// Clear the entire queue (for testing/debugging)
    func clearQueue() {
        operationQueue.removeAll()
        pendingChangesCount = 0
        persistQueue()

        #if DEBUG
        print("🗑️ Offline queue cleared")
        #endif
    }

    /// Force process queue (for manual sync)
    func forceProcessQueue() {
        processQueue()
    }
}
