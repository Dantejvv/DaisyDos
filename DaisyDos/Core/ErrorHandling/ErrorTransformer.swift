//
//  ErrorTransformer.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/24/25.
//

import Foundation
import SwiftData
import CloudKit

/// Central error transformation system for DaisyDos
/// Implements three-tier error handling: Platform → App → User
@Observable
class ErrorTransformer {

    // MARK: - Error Context

    /// Context information for error transformation
    struct ErrorContext {
        let operation: String
        let userAction: String?
        let entityType: String?
        let additionalInfo: [String: Any]

        init(
            operation: String,
            userAction: String? = nil,
            entityType: String? = nil,
            additionalInfo: [String: Any] = [:]
        ) {
            self.operation = operation
            self.userAction = userAction
            self.entityType = entityType
            self.additionalInfo = additionalInfo
        }

        /// Common contexts for frequent operations
        static func taskOperation(_ operation: String) -> ErrorContext {
            ErrorContext(operation: operation, entityType: "task")
        }

        static func habitOperation(_ operation: String) -> ErrorContext {
            ErrorContext(operation: operation, entityType: "habit")
        }

        static func tagOperation(_ operation: String) -> ErrorContext {
            ErrorContext(operation: operation, entityType: "tag")
        }

        static func syncOperation(_ operation: String) -> ErrorContext {
            ErrorContext(operation: operation, userAction: "syncing data")
        }
    }

    // MARK: - Primary Transformation Methods

    /// Transform any error to a RecoverableError with context
    static func transform(
        error: Error,
        context: ErrorContext
    ) -> RecoverableError {
        // First tier: Platform → App
        let daisyDosError = transformToDaisyDosError(error: error, context: context)

        // Second tier: App → User (already implemented via RecoverableError extension)
        return daisyDosError
    }

    /// Transform platform errors to DaisyDos errors with context awareness
    private static func transformToDaisyDosError(
        error: Error,
        context: ErrorContext
    ) -> DaisyDosError {

        // Handle DaisyDos errors that are already transformed
        if let daisyDosError = error as? DaisyDosError {
            return daisyDosError
        }

        // Transform SwiftData errors
        if isSwiftDataError(error) {
            return transformSwiftDataError(error, context: context)
        }

        // Transform CloudKit errors
        if isCloudKitError(error) {
            return transformCloudKitError(error, context: context)
        }

        // Transform system framework errors
        if isSystemFrameworkError(error) {
            return transformSystemFrameworkError(error, context: context)
        }

        // Handle validation errors from our domain models
        if isValidationError(error) {
            return transformValidationError(error, context: context)
        }

        // Fallback: generic error transformation
        return transformGenericError(error, context: context)
    }

    // MARK: - SwiftData Error Transformation

    private static func isSwiftDataError(_ error: Error) -> Bool {
        let description = error.localizedDescription.lowercased()
        return description.contains("swiftdata") ||
               description.contains("persistent") ||
               description.contains("constraint") ||
               description.contains("unique") ||
               description.contains("context") ||
               description.contains("fetch") ||
               description.contains("save")
    }

    private static func transformSwiftDataError(
        _ error: Error,
        context: ErrorContext
    ) -> DaisyDosError {
        let description = error.localizedDescription.lowercased()

        // Specific constraint violations
        if description.contains("unique") || description.contains("constraint") {
            if let entityType = context.entityType {
                return .duplicateEntity(entityType)
            }
            return .duplicateEntity("item")
        }

        // Context-related errors
        if description.contains("context") {
            return .modelContextUnavailable
        }

        // Data corruption indicators
        if description.contains("corrupt") || description.contains("invalid") {
            return .dataCorrupted("SwiftData: \(context.operation)")
        }

        // Validation failures
        if description.contains("validation") || description.contains("required") {
            return .validationFailed(context.entityType ?? "data")
        }

        // Save/persistence failures
        if description.contains("save") || description.contains("persist") {
            return .persistenceFailed(context.operation)
        }

        // Default SwiftData error
        return .persistenceFailed(context.operation)
    }

    // MARK: - CloudKit Error Transformation

    private static func isCloudKitError(_ error: Error) -> Bool {
        return error is CKError ||
               error.localizedDescription.lowercased().contains("cloudkit") ||
               error.localizedDescription.lowercased().contains("icloud")
    }

    private static func transformCloudKitError(
        _ error: Error,
        context: ErrorContext
    ) -> DaisyDosError {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .networkUnavailable, .networkFailure:
                return .networkUnavailable

            case .serverRecordChanged, .serverRejectedRequest:
                return .syncConflict("Server changes conflict with local changes")

            case .notAuthenticated, .permissionFailure:
                return .permissionDenied("iCloud")

            case .quotaExceeded:
                return .integrationFailed("iCloud storage is full")

            case .zoneNotFound:
                return .entityNotFound(context.entityType ?? "item")

            case .constraintViolation:
                return .duplicateEntity(context.entityType ?? "item")

            default:
                return .integrationFailed("iCloud")
            }
        }

        // Handle CloudKit errors not wrapped in CKError
        let description = error.localizedDescription.lowercased()
        if description.contains("network") {
            return .networkUnavailable
        } else if description.contains("conflict") {
            return .syncConflict("CloudKit sync conflict")
        } else if description.contains("permission") || description.contains("auth") {
            return .permissionDenied("iCloud")
        } else {
            return .integrationFailed("iCloud")
        }
    }

    // MARK: - System Framework Error Transformation

    private static func isSystemFrameworkError(_ error: Error) -> Bool {
        let description = error.localizedDescription.lowercased()
        return description.contains("eventkit") ||
               description.contains("photokit") ||
               description.contains("usernotifications") ||
               description.contains("authorization") ||
               description.contains("permission")
    }

    private static func transformSystemFrameworkError(
        _ error: Error,
        context: ErrorContext
    ) -> DaisyDosError {
        let description = error.localizedDescription.lowercased()

        if description.contains("authorization") || description.contains("permission") {
            if description.contains("eventkit") || description.contains("calendar") {
                return .permissionDenied("Calendar")
            } else if description.contains("photokit") || description.contains("photo") {
                return .permissionDenied("Photos")
            } else if description.contains("notification") {
                return .permissionDenied("Notifications")
            } else {
                return .permissionDenied("system service")
            }
        }

        if description.contains("eventkit") {
            return .integrationFailed("Calendar")
        } else if description.contains("photokit") {
            return .integrationFailed("Photos")
        } else if description.contains("notification") {
            return .integrationFailed("Notifications")
        } else {
            return .integrationFailed("system service")
        }
    }

    // MARK: - Validation Error Transformation

    private static func isValidationError(_ error: Error) -> Bool {
        let description = error.localizedDescription.lowercased()
        return description.contains("validation") ||
               description.contains("invalid") ||
               description.contains("required") ||
               description.contains("limit") ||
               description.contains("maximum")
    }

    private static func transformValidationError(
        _ error: Error,
        context: ErrorContext
    ) -> DaisyDosError {
        let description = error.localizedDescription.lowercased()

        if description.contains("tag") && (description.contains("limit") || description.contains("maximum")) {
            return .tagLimitExceeded
        }

        if description.contains("recurrence") || description.contains("schedule") {
            return .invalidRecurrence(error.localizedDescription)
        }

        return .validationFailed(context.entityType ?? "data")
    }

    // MARK: - Generic Error Transformation

    private static func transformGenericError(
        _ error: Error,
        context: ErrorContext
    ) -> DaisyDosError {
        let description = error.localizedDescription.lowercased()

        // Network-related
        if description.contains("network") || description.contains("internet") || description.contains("connection") {
            return .networkUnavailable
        }

        // Permission-related
        if description.contains("permission") || description.contains("authorization") || description.contains("access") {
            return .permissionDenied(context.operation)
        }

        // Not found errors
        if description.contains("not found") || description.contains("missing") {
            return .entityNotFound(context.entityType ?? "item")
        }

        // Duplicate/conflict errors
        if description.contains("duplicate") || description.contains("exists") || description.contains("conflict") {
            return .duplicateEntity(context.entityType ?? "item")
        }

        // Default fallback based on context
        if context.operation.contains("save") || context.operation.contains("create") || context.operation.contains("update") {
            return .persistenceFailed(context.operation)
        } else if context.operation.contains("sync") {
            return .syncConflict("Sync operation failed")
        } else {
            return .integrationFailed(context.operation)
        }
    }

    // MARK: - Convenience Transform Methods

    /// Transform error for task operations
    static func transformTaskError(
        _ error: Error,
        operation: String,
        userAction: String? = nil
    ) -> RecoverableError {
        let context = ErrorContext(
            operation: operation,
            userAction: userAction,
            entityType: "task"
        )
        return transform(error: error, context: context)
    }

    /// Transform error for habit operations
    static func transformHabitError(
        _ error: Error,
        operation: String,
        userAction: String? = nil
    ) -> RecoverableError {
        let context = ErrorContext(
            operation: operation,
            userAction: userAction,
            entityType: "habit"
        )
        return transform(error: error, context: context)
    }

    /// Transform error for tag operations
    static func transformTagError(
        _ error: Error,
        operation: String,
        userAction: String? = nil
    ) -> RecoverableError {
        let context = ErrorContext(
            operation: operation,
            userAction: userAction,
            entityType: "tag"
        )
        return transform(error: error, context: context)
    }

    /// Transform error for sync operations
    static func transformSyncError(
        _ error: Error,
        operation: String
    ) -> RecoverableError {
        let context = ErrorContext(
            operation: operation,
            userAction: "syncing data"
        )
        return transform(error: error, context: context)
    }
}

// MARK: - Result Extensions for Clean Error Handling

extension Result where Failure == Error {
    /// Transform the error case to a RecoverableError
    func mapErrorToRecoverable(
        operation: String,
        entityType: String? = nil
    ) -> Result<Success, AnyRecoverableError> {
        return self.mapError { error in
            let context = ErrorTransformer.ErrorContext(
                operation: operation,
                entityType: entityType
            )
            let recoverableError = ErrorTransformer.transform(error: error, context: context)
            return AnyRecoverableError(recoverableError)
        }
    }
}

// MARK: - Async Error Transformation

extension ErrorTransformer {
    /// Safely execute an async throwing operation and transform any errors
    static func safely<T>(
        operation: String,
        entityType: String? = nil,
        execute: () async throws -> T
    ) async -> Result<T, AnyRecoverableError> {
        do {
            let result = try await execute()
            return .success(result)
        } catch {
            let context = ErrorContext(operation: operation, entityType: entityType)
            let recoverableError = transform(error: error, context: context)
            return .failure(AnyRecoverableError(recoverableError))
        }
    }

    /// Safely execute a sync throwing operation and transform any errors
    static func safely<T>(
        operation: String,
        entityType: String? = nil,
        execute: () throws -> T
    ) -> Result<T, AnyRecoverableError> {
        do {
            let result = try execute()
            return .success(result)
        } catch {
            let context = ErrorContext(operation: operation, entityType: entityType)
            let recoverableError = transform(error: error, context: context)
            return .failure(AnyRecoverableError(recoverableError))
        }
    }
}