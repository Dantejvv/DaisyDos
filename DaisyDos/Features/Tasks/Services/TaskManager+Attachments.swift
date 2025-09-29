//
//  TaskManager+Attachments.swift
//  DaisyDos
//
//  Created by Claude Code on 9/28/25.
//

import Foundation
import SwiftData

// MARK: - Enhanced Attachment Management

extension TaskManager {

    // MARK: - Batch Operations

    /// Add multiple attachments to a task
    func addAttachmentsBatch(
        _ attachments: [TaskAttachment],
        to task: Task
    ) -> Result<[TaskAttachment], AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "add attachments batch",
            entityType: "task"
        ) {
            var addedAttachments: [TaskAttachment] = []
            var totalSizeAfterAddition: Int64 = task.totalAttachmentSize

            // Validate all attachments before adding any
            for attachment in attachments {
                // Check individual file size
                guard attachment.isValidFileSize else {
                    throw DaisyDosError.attachmentTooLarge(attachment.formattedFileSize)
                }

                // Check total size limit
                totalSizeAfterAddition += attachment.fileSizeBytes
                guard totalSizeAfterAddition <= TaskAttachment.maxTotalSizePerTask else {
                    throw DaisyDosError.attachmentTotalSizeExceeded
                }

                // Check if file exists
                guard attachment.fileExists else {
                    throw DaisyDosError.attachmentFileNotFound(attachment.displayName)
                }
            }

            // Add all attachments if validation passes
            for attachment in attachments {
                guard task.addAttachment(attachment) else {
                    throw DaisyDosError.attachmentLimitExceeded
                }
                modelContext.insert(attachment)
                addedAttachments.append(attachment)
            }

            try modelContext.save()
            return addedAttachments
        }
    }

    /// Remove multiple attachments from a task
    func removeAttachmentsBatch(
        _ attachments: [TaskAttachment],
        from task: Task
    ) -> Result<Int, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "remove attachments batch",
            entityType: "task"
        ) {
            var removedCount = 0

            for attachment in attachments {
                // Delete the physical file
                _ = attachment.deleteFile()

                // Remove from task and context
                task.removeAttachment(attachment)
                modelContext.delete(attachment)
                removedCount += 1
            }

            try modelContext.save()
            return removedCount
        }
    }

    // MARK: - File Operations

    /// Validate attachment before adding
    func validateAttachment(
        _ attachment: TaskAttachment,
        for task: Task
    ) -> Result<Void, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "validate attachment",
            entityType: "attachment"
        ) {
            // Check file size
            guard attachment.isValidFileSize else {
                throw DaisyDosError.attachmentTooLarge(attachment.formattedFileSize)
            }

            // Check MIME type
            guard TaskAttachment.isValidMimeType(attachment.mimeType) else {
                throw DaisyDosError.unsupportedFileType(attachment.fileExtension)
            }

            // Check total size after addition
            let newTotalSize = task.totalAttachmentSize + attachment.fileSizeBytes
            guard newTotalSize <= TaskAttachment.maxTotalSizePerTask else {
                throw DaisyDosError.attachmentTotalSizeExceeded
            }

            // Check if file exists
            guard attachment.fileExists else {
                throw DaisyDosError.attachmentFileNotFound(attachment.displayName)
            }
        }
    }

    /// Generate thumbnails for all image attachments in a task
    func generateThumbnailsForTask(
        _ task: Task
    ) -> Result<Int, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "generate thumbnails",
            entityType: "task"
        ) {
            var generatedCount = 0

            for attachment in task.attachments {
                if attachment.attachmentType == .image && attachment.thumbnailPath == nil {
                    if attachment.generateThumbnail() {
                        generatedCount += 1
                    }
                }
            }

            if generatedCount > 0 {
                try modelContext.save()
            }

            return generatedCount
        }
    }

    /// Clean up orphaned attachment files (files without corresponding database entries)
    func cleanupOrphanedAttachmentFiles() -> Result<Int, AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "cleanup orphaned files",
            entityType: "filesystem"
        ) {
            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw DaisyDosError.documentDirectoryUnavailable
            }

            let attachmentsDirectory = documentsDirectory.appendingPathComponent("attachments")
            let thumbnailsDirectory = documentsDirectory.appendingPathComponent("thumbnails")

            var cleanedCount = 0

            // Get all attachment file paths from database
            let descriptor = FetchDescriptor<TaskAttachment>()
            let allAttachments = try modelContext.fetch(descriptor)
            let validFilePaths = Set(allAttachments.compactMap { $0.relativeFilePath })
            let validThumbnailPaths = Set(allAttachments.compactMap { $0.thumbnailPath })

            // Clean attachments directory
            if FileManager.default.fileExists(atPath: attachmentsDirectory.path) {
                let attachmentFiles = try FileManager.default.contentsOfDirectory(at: attachmentsDirectory, includingPropertiesForKeys: nil)
                for fileURL in attachmentFiles {
                    let relativePath = "attachments/\(fileURL.lastPathComponent)"
                    if !validFilePaths.contains(relativePath) {
                        try FileManager.default.removeItem(at: fileURL)
                        cleanedCount += 1
                    }
                }
            }

            // Clean thumbnails directory
            if FileManager.default.fileExists(atPath: thumbnailsDirectory.path) {
                let thumbnailFiles = try FileManager.default.contentsOfDirectory(at: thumbnailsDirectory, includingPropertiesForKeys: nil)
                for fileURL in thumbnailFiles {
                    let relativePath = "thumbnails/\(fileURL.lastPathComponent)"
                    if !validThumbnailPaths.contains(relativePath) {
                        try FileManager.default.removeItem(at: fileURL)
                        cleanedCount += 1
                    }
                }
            }

            return cleanedCount
        }
    }

    // MARK: - Attachment Statistics

    /// Get attachment statistics for all tasks
    func getAttachmentStatistics() -> AttachmentStatistics {
        let descriptor = FetchDescriptor<TaskAttachment>()
        let allAttachments = (try? modelContext.fetch(descriptor)) ?? []

        let totalSize = allAttachments.reduce(0) { $0 + $1.fileSizeBytes }
        let imageCount = allAttachments.filter { $0.attachmentType == .image }.count
        let documentCount = allAttachments.filter { $0.attachmentType == .document }.count
        let otherCount = allAttachments.filter { $0.attachmentType == .other }.count

        return AttachmentStatistics(
            totalCount: allAttachments.count,
            totalSize: totalSize,
            imageCount: imageCount,
            documentCount: documentCount,
            otherCount: otherCount,
            averageSize: allAttachments.isEmpty ? 0 : totalSize / Int64(allAttachments.count)
        )
    }

    /// Find duplicate attachments across all tasks
    func findDuplicateAttachments() -> Result<[DuplicateAttachmentGroup], AnyRecoverableError> {
        return ErrorTransformer.safely(
            operation: "find duplicate attachments",
            entityType: "attachment"
        ) {
            let descriptor = FetchDescriptor<TaskAttachment>()
            let allAttachments = try modelContext.fetch(descriptor)

            // Group by file hash (if available) or by name and size
            let grouped = Dictionary(grouping: allAttachments) { attachment in
                if let hash = attachment.fileHash {
                    return hash
                } else {
                    return "\(attachment.originalFileName)_\(attachment.fileSizeBytes)"
                }
            }

            let duplicateGroups = grouped.compactMap { (key, attachments) -> DuplicateAttachmentGroup? in
                guard attachments.count > 1 else { return nil }
                return DuplicateAttachmentGroup(
                    identifier: key,
                    attachments: attachments,
                    totalSize: attachments.reduce(0) { $0 + $1.fileSizeBytes }
                )
            }

            return duplicateGroups.sorted { $0.totalSize > $1.totalSize }
        }
    }

    // MARK: - Convenience Methods (Safe versions)

    /// Safely add attachment with validation
    func addAttachmentSafely(
        _ attachment: TaskAttachment,
        to task: Task
    ) -> Bool {
        switch addAttachment(attachment, to: task) {
        case .success:
            return true
        case .failure(let error):
            lastError = error.wrapped
            return false
        }
    }

    /// Safely remove attachment with file cleanup
    func removeAttachmentSafely(
        _ attachment: TaskAttachment,
        from task: Task
    ) -> Bool {
        // Delete physical file first
        _ = attachment.deleteFile()

        switch removeAttachment(attachment, from: task) {
        case .success:
            return true
        case .failure(let error):
            lastError = error.wrapped
            return false
        }
    }

    /// Safely generate thumbnails for task
    func generateThumbnailsForTaskSafely(_ task: Task) -> Int {
        switch generateThumbnailsForTask(task) {
        case .success(let count):
            return count
        case .failure(let error):
            lastError = error.wrapped
            return 0
        }
    }
}

// MARK: - Supporting Types

struct AttachmentStatistics {
    let totalCount: Int
    let totalSize: Int64
    let imageCount: Int
    let documentCount: Int
    let otherCount: Int
    let averageSize: Int64

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var formattedAverageSize: String {
        ByteCountFormatter.string(fromByteCount: averageSize, countStyle: .file)
    }
}

struct DuplicateAttachmentGroup {
    let identifier: String
    let attachments: [TaskAttachment]
    let totalSize: Int64

    var potentialSavings: Int64 {
        guard attachments.count > 1 else { return 0 }
        return Int64(attachments.count - 1) * (attachments.first?.fileSizeBytes ?? 0)
    }

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var formattedPotentialSavings: String {
        ByteCountFormatter.string(fromByteCount: potentialSavings, countStyle: .file)
    }
}

// MARK: - Enhanced Error Types

extension DaisyDosError {
    static func attachmentTooLarge(_ size: String) -> DaisyDosError {
        .validationFailed("Attachment is too large (\(size)). Maximum size is \(ByteCountFormatter.string(fromByteCount: TaskAttachment.maxFileSizeBytes, countStyle: .file))")
    }

    static let attachmentTotalSizeExceeded = DaisyDosError.validationFailed(
        "Adding this attachment would exceed the total size limit of \(ByteCountFormatter.string(fromByteCount: TaskAttachment.maxTotalSizePerTask, countStyle: .file)) per task"
    )

    static func attachmentFileNotFound(_ fileName: String) -> DaisyDosError {
        .entityNotFound("Attachment file '\(fileName)'")
    }

    static func unsupportedFileType(_ extension: String) -> DaisyDosError {
        .validationFailed("File type '\(`extension`)' is not supported")
    }

    static let documentDirectoryUnavailable = DaisyDosError.integrationFailed("document directory access")
}