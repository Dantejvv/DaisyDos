//
//  DaisyDosError.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/24/25.
//

import Foundation
import SwiftData

/// App-specific error types for DaisyDos application
/// Part of the three-tier error handling system (Platform → App → User)
enum DaisyDosError: Error, LocalizedError, Equatable {

    // MARK: - Data Layer Errors

    /// ModelContext is not available or accessible
    case modelContextUnavailable

    /// Data corruption detected in SwiftData store
    case dataCorrupted(String)

    /// SwiftData persistence operation failed
    case persistenceFailed(String)

    /// Data validation failed
    case validationFailed(String)

    // MARK: - Business Logic Errors

    /// User attempted to exceed maximum tag limit (3 per item, 30 total)
    case tagLimitExceeded

    /// Invalid recurrence rule configuration
    case invalidRecurrence(String)

    /// Duplicate entity creation attempted
    case duplicateEntity(String)

    /// Required entity not found
    case entityNotFound(String)

    // MARK: - System Integration Errors

    /// Network connection unavailable
    case networkUnavailable

    /// CloudKit sync conflict detected
    case syncConflict(String)

    /// System permission denied (Calendar, Photos, Notifications)
    case permissionDenied(String)

    /// External service integration failed
    case integrationFailed(String)

    // MARK: - LocalizedError Implementation

    var errorDescription: String? {
        switch self {
        case .modelContextUnavailable:
            return "Database context is not available"
        case .dataCorrupted(let details):
            return "Data corruption detected: \(details)"
        case .persistenceFailed(let operation):
            return "Failed to save \(operation)"
        case .validationFailed(let field):
            return "Validation failed for \(field)"
        case .tagLimitExceeded:
            return "Maximum tag limit exceeded"
        case .invalidRecurrence(let details):
            return "Invalid recurrence configuration: \(details)"
        case .duplicateEntity(let type):
            return "Duplicate \(type) already exists"
        case .entityNotFound(let type):
            return "\(type) not found"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .syncConflict(let details):
            return "Sync conflict: \(details)"
        case .permissionDenied(let service):
            return "Permission denied for \(service)"
        case .integrationFailed(let service):
            return "Integration with \(service) failed"
        }
    }

    var failureReason: String? {
        switch self {
        case .modelContextUnavailable:
            return "The database connection could not be established"
        case .dataCorrupted:
            return "The stored data appears to be corrupted"
        case .persistenceFailed:
            return "The data could not be saved to the database"
        case .validationFailed:
            return "The provided data does not meet requirements"
        case .tagLimitExceeded:
            return "You can only have 3 tags per item and 30 total tags"
        case .invalidRecurrence:
            return "The recurrence pattern is not valid"
        case .duplicateEntity:
            return "An item with this information already exists"
        case .entityNotFound:
            return "The requested item could not be found"
        case .networkUnavailable:
            return "No internet connection is available"
        case .syncConflict:
            return "Multiple devices have conflicting changes"
        case .permissionDenied:
            return "The app does not have permission to access this service"
        case .integrationFailed:
            return "External service is temporarily unavailable"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .modelContextUnavailable:
            return "Try restarting the app. If the problem persists, contact support."
        case .dataCorrupted:
            return "Try refreshing the data. If the problem persists, you may need to restore from backup."
        case .persistenceFailed:
            return "Try again in a moment. Check available storage space."
        case .validationFailed:
            return "Please correct the highlighted fields and try again."
        case .tagLimitExceeded:
            return "Remove existing tags to add new ones, or delete unused tags."
        case .invalidRecurrence:
            return "Please check your recurrence settings and try again."
        case .duplicateEntity:
            return "Try using a different name or modify the existing item."
        case .entityNotFound:
            return "The item may have been deleted. Try refreshing the list."
        case .networkUnavailable:
            return "Connect to the internet and try again."
        case .syncConflict:
            return "Choose which version to keep or merge the changes manually."
        case .permissionDenied:
            return "Go to Settings and grant permission to continue."
        case .integrationFailed:
            return "Try again later or check the service status."
        }
    }

    // MARK: - Error Categorization

    /// Indicates if this error represents a user mistake vs system issue
    var isUserError: Bool {
        switch self {
        case .tagLimitExceeded, .invalidRecurrence, .validationFailed, .duplicateEntity:
            return true
        default:
            return false
        }
    }

    /// Indicates if this error can be automatically retried
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .persistenceFailed, .integrationFailed:
            return true
        default:
            return false
        }
    }

    /// Indicates if this error requires immediate user attention
    var isCritical: Bool {
        switch self {
        case .dataCorrupted, .modelContextUnavailable, .syncConflict:
            return true
        default:
            return false
        }
    }
}

// MARK: - Error Transformation from Platform Errors

extension DaisyDosError {

    /// Transform SwiftData errors to DaisyDos errors
    static func from(swiftDataError: Error) -> DaisyDosError {
        // Handle known SwiftData error patterns
        let errorMessage = swiftDataError.localizedDescription.lowercased()

        if errorMessage.contains("constraint") || errorMessage.contains("unique") {
            return .duplicateEntity("item")
        } else if errorMessage.contains("context") {
            return .modelContextUnavailable
        } else if errorMessage.contains("corrupt") {
            return .dataCorrupted(swiftDataError.localizedDescription)
        } else {
            return .persistenceFailed(swiftDataError.localizedDescription)
        }
    }

    /// Transform CloudKit errors to DaisyDos errors
    static func from(cloudKitError: Error) -> DaisyDosError {
        let errorMessage = cloudKitError.localizedDescription.lowercased()

        if errorMessage.contains("network") || errorMessage.contains("internet") {
            return .networkUnavailable
        } else if errorMessage.contains("conflict") {
            return .syncConflict(cloudKitError.localizedDescription)
        } else {
            return .integrationFailed("iCloud")
        }
    }

    /// Transform general system errors to DaisyDos errors
    static func from(systemError: Error, context: String = "") -> DaisyDosError {
        let errorMessage = systemError.localizedDescription.lowercased()

        if errorMessage.contains("permission") || errorMessage.contains("authorization") {
            return .permissionDenied(context)
        } else if errorMessage.contains("network") {
            return .networkUnavailable
        } else {
            return .integrationFailed(context.isEmpty ? "system" : context)
        }
    }
}