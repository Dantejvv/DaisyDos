//
//  ErrorHandlingTests.swift
//  DaisyDosTests
//
//  Tests for error handling system
//

import Testing
import Foundation
@testable import DaisyDos

@Suite("Error Handling Tests")
struct ErrorHandlingTests {

    // MARK: - Error Message Tests

    @Test("DaisyDosError displays correct user messages")
    func testUserMessages() {
        let testCases: [(error: DaisyDosError, expectedMessage: String)] = [
            (.tagLimitExceeded, "Too many tags"),
            (.circularReference, "Invalid task relationship"),
            (.networkUnavailable, "No internet connection"),
            (.persistenceFailed("task"), "Unable to save your changes"),
            (.validationFailed("title"), "Please check your information"),
            (.duplicateEntity("Task"), "Task already exists"),
            (.entityNotFound("Task"), "Task not found")
        ]

        for (error, expectedMessage) in testCases {
            #expect(error.userMessage == expectedMessage,
                   "Error \(error) should display message: '\(expectedMessage)'")
        }
    }

    @Test("DaisyDosError displays correct user reasons")
    func testUserReasons() {
        let tagLimitError = DaisyDosError.tagLimitExceeded
        #expect(tagLimitError.userReason.contains("5 tags per item"))
        #expect(tagLimitError.userReason.contains("30 total tags"))

        let circularError = DaisyDosError.circularReference
        #expect(circularError.userReason.contains("circular relationship"))
    }

    @Test("DaisyDosError provides recovery suggestions")
    func testRecoverySuggestions() {
        let error = DaisyDosError.tagLimitExceeded
        #expect(error.recoverySuggestion != nil)
        #expect(error.recoverySuggestion!.contains("Remove existing tags"))

        let circularError = DaisyDosError.circularReference
        #expect(circularError.recoverySuggestion != nil)
        #expect(circularError.recoverySuggestion!.contains("root-level tasks"))
    }

    @Test("DaisyDosError has recovery options")
    func testRecoveryOptions() {
        let error = DaisyDosError.tagLimitExceeded
        let options = error.recoveryOptions

        #expect(options.count > 0, "Error should provide recovery options")
        #expect(options.contains { $0.title == "Manage Tags" })
    }

    // MARK: - Error Priority Tests

    @Test("User errors have appropriate priority levels")
    func testErrorPriorities() {
        // Low priority - user validation errors
        #expect(DaisyDosError.validationFailed("test").priority == .low)
        #expect(DaisyDosError.tagLimitExceeded.priority == .low)
        #expect(DaisyDosError.circularReference.priority == .low)

        // Medium priority - data errors
        #expect(DaisyDosError.duplicateEntity("test").priority == .medium)
        #expect(DaisyDosError.persistenceFailed("test").priority == .medium)

        // High priority - system errors
        #expect(DaisyDosError.networkUnavailable.priority == .high)
        #expect(DaisyDosError.permissionDenied("test").priority == .high)

        // Critical priority - data integrity errors
        #expect(DaisyDosError.modelContextUnavailable.priority == .critical)
        #expect(DaisyDosError.dataCorrupted("test").priority == .critical)
    }

    // MARK: - Error Categorization Tests

    @Test("User errors are correctly identified")
    func testUserErrorIdentification() {
        // User errors
        #expect(DaisyDosError.tagLimitExceeded.isUserError == true)
        #expect(DaisyDosError.circularReference.isUserError == true)
        #expect(DaisyDosError.validationFailed("test").isUserError == true)

        // System errors
        #expect(DaisyDosError.networkUnavailable.isUserError == false)
        #expect(DaisyDosError.dataCorrupted("test").isUserError == false)
    }

    @Test("Retryable errors are correctly identified")
    func testRetryableErrors() {
        // Retryable errors
        #expect(DaisyDosError.networkUnavailable.isRetryable == true)
        #expect(DaisyDosError.persistenceFailed("test").isRetryable == true)
        #expect(DaisyDosError.integrationFailed("test").isRetryable == true)

        // Non-retryable errors
        #expect(DaisyDosError.tagLimitExceeded.isRetryable == false)
        #expect(DaisyDosError.dataCorrupted("test").isRetryable == false)
    }

    @Test("Critical errors are correctly identified")
    func testCriticalErrors() {
        // Critical errors
        #expect(DaisyDosError.dataCorrupted("test").isCritical == true)
        #expect(DaisyDosError.modelContextUnavailable.isCritical == true)
        #expect(DaisyDosError.syncConflict("test").isCritical == true)

        // Non-critical errors
        #expect(DaisyDosError.tagLimitExceeded.isCritical == false)
        #expect(DaisyDosError.networkUnavailable.isCritical == false)
    }

    // MARK: - Error Transformation Tests

    @Test("SwiftData errors transform correctly")
    func testSwiftDataErrorTransformation() {
        // Create a mock constraint error
        let constraintError = NSError(
            domain: "SwiftData",
            code: 133021,
            userInfo: [NSLocalizedDescriptionKey: "Unique constraint violation"]
        )

        let transformed = DaisyDosError.from(swiftDataError: constraintError)
        #expect(transformed == .duplicateEntity("item"))
    }

    @Test("System errors transform correctly")
    func testSystemErrorTransformation() {
        // Create a mock permission error
        let permissionError = NSError(
            domain: "System",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Permission denied to access Photos"]
        )

        let transformed = DaisyDosError.from(systemError: permissionError, context: "Photos")
        #expect(transformed == .permissionDenied("Photos"))
    }

    // MARK: - LocalizedError Integration Tests

    @Test("DaisyDosError conforms to LocalizedError")
    func testLocalizedErrorConformance() {
        let error = DaisyDosError.tagLimitExceeded

        // All LocalizedError properties should be accessible
        #expect(error.errorDescription != nil)
        #expect(error.failureReason != nil)
        #expect(error.recoverySuggestion != nil)
    }

    // MARK: - All Error Cases Coverage

    @Test("All DaisyDosError cases have complete error information")
    func testAllErrorCasesHaveMessages() {
        let allErrors: [DaisyDosError] = [
            .modelContextUnavailable,
            .dataCorrupted("test"),
            .persistenceFailed("test"),
            .validationFailed("test"),
            .tagLimitExceeded,
            .invalidRecurrence,
            .circularReference,
            .duplicateEntity("test"),
            .entityNotFound("test"),
            .networkUnavailable,
            .syncConflict("test"),
            .permissionDenied("test"),
            .integrationFailed("test"),
            .databaseError("test"),
            .exportFailed("test"),
            .importFailed("test")
        ]

        for error in allErrors {
            // Verify each error has all required information
            #expect(!error.userMessage.isEmpty,
                   "Error \(error) should have a user message")
            #expect(!error.userReason.isEmpty,
                   "Error \(error) should have a user reason")
            #expect(!error.recoveryOptions.isEmpty,
                   "Error \(error) should have recovery options")
            #expect(error.errorDescription != nil,
                   "Error \(error) should have error description")
            #expect(error.failureReason != nil,
                   "Error \(error) should have failure reason")
            #expect(error.recoverySuggestion != nil,
                   "Error \(error) should have recovery suggestion")
        }
    }
}
