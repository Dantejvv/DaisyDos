//
//  RecoverableError.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/24/25.
//

import Foundation

/// Protocol for errors that can provide user-friendly messages and recovery actions
/// Final tier in the three-tier error handling system (Platform → App → User)
/// Conforms to LocalizedError for seamless SwiftUI alert integration
protocol RecoverableError: Error, LocalizedError {
    /// User-friendly message that explains what went wrong
    var userMessage: String { get }

    /// User-friendly explanation of why it happened
    var userReason: String { get }

    /// Suggested recovery actions the user can take
    var recoveryOptions: [RecoveryAction] { get }

    /// Priority level for displaying this error
    var priority: ErrorPriority { get }
}

// MARK: - LocalizedError Conformance

extension RecoverableError {
    /// Maps userMessage to SwiftUI's errorDescription for alert presentation
    var errorDescription: String? { userMessage }

    /// Maps userReason to SwiftUI's recoverySuggestion for alert message
    var recoverySuggestion: String? {
        userReason.isEmpty ? nil : userReason
    }

    /// No failure reason needed - userReason provides context
    var failureReason: String? { nil }

    /// No help anchor - recovery options provide actions
    var helpAnchor: String? { nil }
}

/// Priority levels for error presentation
enum ErrorPriority: Int, CaseIterable {
    case low = 0        // Info/warning level - can be dismissed
    case medium = 1     // Standard errors - require acknowledgment
    case high = 2       // Important errors - may block workflow
    case critical = 3   // System errors - require immediate attention

    var displayDuration: TimeInterval {
        switch self {
        case .low: return 3.0
        case .medium: return 5.0
        case .high: return 0  // Manual dismissal required
        case .critical: return 0  // Manual dismissal required
        }
    }
}

/// Represents a recovery action that users can take to resolve an error
struct RecoveryAction {
    let title: String
    let style: ActionStyle
    let action: () async -> Void

    enum ActionStyle {
        case primary    // Main recovery action (e.g., "Try Again")
        case secondary  // Alternative action (e.g., "Cancel")
        case destructive // Destructive action (e.g., "Delete All")
    }

    /// Create a simple synchronous recovery action
    init(title: String, style: ActionStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = {
            await MainActor.run {
                action()
            }
        }
    }

    /// Create an async recovery action
    init(title: String, style: ActionStyle = .primary, asyncAction: @escaping () async -> Void) {
        self.title = title
        self.style = style
        self.action = asyncAction
    }
}

// MARK: - DaisyDosError + RecoverableError

extension DaisyDosError: RecoverableError {

    var userMessage: String {
        switch self {
        case .modelContextUnavailable:
            return "Unable to access your data"
        case .dataCorrupted:
            return "Your data appears to be corrupted"
        case .persistenceFailed:
            return "Unable to save your changes"
        case .validationFailed:
            return "Please check your information"
        case .tagLimitExceeded:
            return "Too many tags"
        case .invalidRecurrence:
            return "Invalid schedule settings"
        case .circularReference:
            return "Invalid task relationship"
        case .duplicateEntity(let type):
            return "\(type.capitalized) already exists"
        case .entityNotFound(let type):
            return "\(type.capitalized) not found"
        case .networkUnavailable:
            return "No internet connection"
        case .syncConflict:
            return "Sync conflict detected"
        case .permissionDenied:
            return "Permission required"
        case .integrationFailed(let service):
            return "\(service.capitalized) is temporarily unavailable"
        case .databaseError(let operation, _):
            return "Database error: \(operation)"
        case .exportFailed:
            return "Export failed"
        case .importFailed:
            return "Import failed"
        }
    }

    var userReason: String {
        switch self {
        case .modelContextUnavailable:
            return "There's a problem connecting to your data storage."
        case .dataCorrupted:
            return "Some of your stored information has become corrupted."
        case .persistenceFailed:
            return "Your changes couldn't be saved right now."
        case .validationFailed:
            return "Some required information is missing or incorrect."
        case .tagLimitExceeded:
            return "You can only have 5 tags per item and 30 total tags in your system."
        case .invalidRecurrence:
            return "The schedule you've set up has invalid settings."
        case .circularReference:
            return "This would create a circular relationship between tasks."
        case .duplicateEntity:
            return "An item with this information already exists in your system."
        case .entityNotFound:
            return "The item you're looking for may have been deleted or moved."
        case .networkUnavailable:
            return "Your device isn't connected to the internet right now."
        case .syncConflict:
            return "Changes were made on multiple devices at the same time."
        case .permissionDenied(let service):
            return "DaisyDos needs permission to access \(service) to continue."
        case .integrationFailed:
            return "The external service is experiencing technical difficulties."
        case .databaseError:
            return "A database operation failed unexpectedly."
        case .exportFailed(let details):
            return "Failed to export your data: \(details)"
        case .importFailed(let details):
            return "Failed to import the data: \(details)"
        }
    }

    var recoveryOptions: [RecoveryAction] {
        switch self {
        case .modelContextUnavailable:
            return [
                RecoveryAction(title: "Retry", style: .primary) { /* Retry initialization */ },
                RecoveryAction(title: "Contact Support", style: .secondary) { /* Open support */ }
            ]

        case .dataCorrupted:
            return [
                RecoveryAction(title: "Try to Repair", style: .primary) { /* Attempt repair */ },
                RecoveryAction(title: "Restore Backup", style: .secondary) { /* Restore from backup */ },
                RecoveryAction(title: "Reset Data", style: .destructive) { /* Factory reset */ }
            ]

        case .persistenceFailed:
            return [
                RecoveryAction(title: "Try Again", style: .primary) { /* Retry save */ },
                RecoveryAction(title: "Discard Changes", style: .destructive) { /* Discard */ }
            ]

        case .validationFailed:
            return [
                RecoveryAction(title: "Fix Information", style: .primary) { /* Return to form */ },
                RecoveryAction(title: "Cancel", style: .secondary) { /* Cancel operation */ }
            ]

        case .tagLimitExceeded:
            return [
                RecoveryAction(title: "Manage Tags", style: .primary) { /* Open tag manager */ },
                RecoveryAction(title: "Remove Tags", style: .secondary) { /* Remove some tags */ },
                RecoveryAction(title: "Cancel", style: .secondary) { /* Cancel */ }
            ]

        case .invalidRecurrence:
            return [
                RecoveryAction(title: "Fix Schedule", style: .primary) { /* Return to schedule editor */ },
                RecoveryAction(title: "Use Simple Schedule", style: .secondary) { /* Set default */ },
                RecoveryAction(title: "Cancel", style: .secondary) { /* Cancel */ }
            ]

        case .circularReference:
            return [
                RecoveryAction(title: "Choose Different Parent", style: .primary) { /* Parent selection */ },
                RecoveryAction(title: "Cancel", style: .secondary) { /* Cancel */ }
            ]

        case .duplicateEntity:
            return [
                RecoveryAction(title: "Edit Existing", style: .primary) { /* Edit existing */ },
                RecoveryAction(title: "Create Different", style: .secondary) { /* Modify and retry */ },
                RecoveryAction(title: "Cancel", style: .secondary) { /* Cancel */ }
            ]

        case .entityNotFound:
            return [
                RecoveryAction(title: "Refresh", style: .primary) { /* Refresh data */ },
                RecoveryAction(title: "Go Back", style: .secondary) { /* Navigate back */ }
            ]

        case .networkUnavailable:
            return [
                RecoveryAction(title: "Try Again", style: .primary) { /* Retry operation */ },
                RecoveryAction(title: "Work Offline", style: .secondary) { /* Continue offline */ }
            ]

        case .syncConflict:
            return [
                RecoveryAction(title: "Keep Local", style: .primary) { /* Use local version */ },
                RecoveryAction(title: "Keep Remote", style: .secondary) { /* Use remote version */ },
                RecoveryAction(title: "Merge Changes", style: .secondary) { /* Manual merge */ }
            ]

        case .permissionDenied:
            return [
                RecoveryAction(title: "Open Settings", style: .primary) { /* Open system settings */ },
                RecoveryAction(title: "Continue Without", style: .secondary) { /* Skip feature */ }
            ]

        case .integrationFailed:
            return [
                RecoveryAction(title: "Try Again", style: .primary) { /* Retry integration */ },
                RecoveryAction(title: "Skip for Now", style: .secondary) { /* Skip integration */ }
            ]

        case .databaseError:
            return [
                RecoveryAction(title: "Try Again", style: .primary) { /* Retry operation */ },
                RecoveryAction(title: "Cancel", style: .secondary) { /* Cancel */ }
            ]

        case .exportFailed:
            return [
                RecoveryAction(title: "Try Again", style: .primary) { /* Retry export */ },
                RecoveryAction(title: "Cancel", style: .secondary) { /* Cancel */ }
            ]

        case .importFailed:
            return [
                RecoveryAction(title: "Choose Different File", style: .primary) { /* File picker */ },
                RecoveryAction(title: "Cancel", style: .secondary) { /* Cancel */ }
            ]
        }
    }

    var priority: ErrorPriority {
        switch self {
        case .validationFailed, .tagLimitExceeded, .invalidRecurrence, .circularReference:
            return .low
        case .duplicateEntity, .entityNotFound, .persistenceFailed, .exportFailed, .importFailed:
            return .medium
        case .networkUnavailable, .permissionDenied, .integrationFailed, .databaseError:
            return .high
        case .modelContextUnavailable, .dataCorrupted, .syncConflict:
            return .critical
        }
    }
}

// MARK: - Convenience Extensions

extension RecoverableError {
    /// Create a simple informational error with no recovery actions
    static func info(_ message: String, reason: String = "") -> InfoError {
        InfoError(message: message, reason: reason)
    }

    /// Create a simple warning with optional retry action
    static func warning(_ message: String, reason: String = "", retryAction: (() -> Void)? = nil) -> WarningError {
        WarningError(message: message, reason: reason, retryAction: retryAction)
    }
}

// MARK: - Simple Error Implementations

struct InfoError: RecoverableError {
    let message: String
    let reason: String

    var userMessage: String { message }
    var userReason: String { reason.isEmpty ? message : reason }
    var recoveryOptions: [RecoveryAction] { [RecoveryAction(title: "OK", style: .primary) {}] }
    var priority: ErrorPriority { .low }
}

struct WarningError: RecoverableError {
    let message: String
    let reason: String
    let retryAction: (() -> Void)?

    var userMessage: String { message }
    var userReason: String { reason.isEmpty ? message : reason }
    var priority: ErrorPriority { .medium }

    var recoveryOptions: [RecoveryAction] {
        var actions: [RecoveryAction] = []

        if let retryAction = retryAction {
            actions.append(RecoveryAction(title: "Try Again", style: .primary, action: retryAction))
        }

        actions.append(RecoveryAction(title: "OK", style: .secondary) {})
        return actions
    }
}

// MARK: - Type Erased Error Wrapper

/// Concrete error type that wraps any RecoverableError for use in Result types
struct AnyRecoverableError: Error, RecoverableError {
    let wrapped: any RecoverableError

    init(_ error: any RecoverableError) {
        self.wrapped = error
    }

    // Forward RecoverableError protocol requirements to wrapped error
    var userMessage: String { wrapped.userMessage }
    var userReason: String { wrapped.userReason }
    var recoveryOptions: [RecoveryAction] { wrapped.recoveryOptions }
    var priority: ErrorPriority { wrapped.priority }
}

// Add convenience extension to convert to AnyRecoverableError
extension RecoverableError {
    var asAnyRecoverableError: AnyRecoverableError {
        AnyRecoverableError(self)
    }
}