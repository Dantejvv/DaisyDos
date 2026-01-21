//
//  Task+Transferable.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Custom UTTypes

extension UTType {
    static let daisyTask = UTType(exportedAs: "com.daisydos.task")
}

// MARK: - Task Transfer Data (Swift 6 Compatible)

// Use typealias to disambiguate from Swift's concurrency Task
typealias DaisyTask = DaisyDos.Task

/// Sendable transfer data using persistentModelID for Task drag-and-drop
/// Use this instead of Task: Transferable to avoid Sendable conformance issues
struct TaskTransferData: Codable, Sendable, Transferable {
    let persistentModelID: String  // Encoded PersistentIdentifier
    let taskId: UUID               // Fallback UUID for lookups
    let title: String              // For external app text representation

    init(from task: DaisyTask) {
        // Encode PersistentIdentifier as a string for Codable conformance
        if let encoded = try? JSONEncoder().encode(task.persistentModelID),
           let idString = String(data: encoded, encoding: .utf8) {
            self.persistentModelID = idString
        } else {
            self.persistentModelID = ""
        }
        self.taskId = task.id
        self.title = task.title
    }

    /// Resolve the Task from a ModelContext using the persistentModelID
    func resolveTask(in context: ModelContext) -> DaisyTask? {
        // Try to decode and fetch by PersistentIdentifier first
        if !persistentModelID.isEmpty,
           let data = persistentModelID.data(using: .utf8),
           let identifier = try? JSONDecoder().decode(PersistentIdentifier.self, from: data) {
            return context.model(for: identifier) as? DaisyTask
        }

        // Fallback: fetch by UUID
        let taskIdToFind = taskId
        let descriptor = FetchDescriptor<DaisyTask>(predicate: #Predicate { $0.id == taskIdToFind })
        return try? context.fetch(descriptor).first
    }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .daisyTask)

        // External apps - plain text representation of title
        ProxyRepresentation(exporting: \.title)
    }
}

// MARK: - Task Draggable Extension

extension DaisyTask {
    /// Creates transfer data for drag-and-drop operations
    var transferData: TaskTransferData {
        TaskTransferData(from: self)
    }
}


