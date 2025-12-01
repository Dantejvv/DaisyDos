//
//  EntityManagerProtocol.swift
//  DaisyDos
//
//  Created by Claude Code on 1/11/25.
//  Protocol defining common manager operations for Task and Habit managers
//

import Foundation
import SwiftData

// MARK: - Entity Manager Protocol

/// Protocol that defines common operations for entity managers
/// Conforms to Observable for SwiftUI integration
protocol EntityManagerProtocol: Observable, AnyObject {
    associatedtype Entity: PersistentModel

    /// The model context for SwiftData operations
    var modelContext: ModelContext { get }

    // MARK: - Tag Operations

    /// Adds a tag to an entity
    /// - Parameters:
    ///   - tag: The tag to add
    ///   - entity: The entity to add the tag to
    /// - Returns: Result with success or error
    func addTag(_ tag: Tag, to entity: Entity) -> Result<Void, AnyRecoverableError>

    /// Removes a tag from an entity
    /// - Parameters:
    ///   - tag: The tag to remove
    ///   - entity: The entity to remove the tag from
    /// - Returns: Result with success or error
    func removeTag(_ tag: Tag, from entity: Entity) -> Result<Void, AnyRecoverableError>
}

// MARK: - Default Implementations

extension EntityManagerProtocol {
    // MARK: Safe Tag Operations (Bool return)

    /// Safe wrapper for add tag operation
    /// - Parameters:
    ///   - tag: The tag to add
    ///   - entity: The entity to add the tag to
    /// - Returns: True if successful, false otherwise
    func addTagSafely(_ tag: Tag, to entity: Entity) -> Bool {
        switch addTag(tag, to: entity) {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    /// Safe wrapper for remove tag operation
    /// - Parameters:
    ///   - tag: The tag to remove
    ///   - entity: The entity to remove the tag from
    /// - Returns: True if successful, false otherwise
    func removeTagSafely(_ tag: Tag, from entity: Entity) -> Bool {
        switch removeTag(tag, from: entity) {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}
