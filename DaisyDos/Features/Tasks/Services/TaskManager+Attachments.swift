//
//  TaskManager+Attachments.swift
//  DaisyDos
//
//  Created by Claude Code
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - Attachment-specific Errors

enum AttachmentError: LocalizedError {
    case fileTooLarge(fileName: String, size: Int64, maxSize: Int64)
    case totalSizeExceeded(currentSize: Int64, maxSize: Int64)
    case fileReadFailed(fileName: String)
    case invalidFileType(fileName: String)
    case attachmentNotFound

    var errorDescription: String? {
        switch self {
        case .fileTooLarge:
            return "File Too Large"
        case .totalSizeExceeded:
            return "Storage Limit Exceeded"
        case .fileReadFailed:
            return "Unable to Read File"
        case .invalidFileType:
            return "Invalid File Type"
        case .attachmentNotFound:
            return "Attachment Not Found"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .fileTooLarge(let fileName, let size, let maxSize):
            let sizeStr = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            let maxStr = ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file)
            return "'\(fileName)' is \(sizeStr). Maximum file size is \(maxStr)."
        case .totalSizeExceeded(let currentSize, let maxSize):
            let currentStr = ByteCountFormatter.string(fromByteCount: currentSize, countStyle: .file)
            let maxStr = ByteCountFormatter.string(fromByteCount: maxSize, countStyle: .file)
            return "Adding this file would exceed the \(maxStr) limit per task. Current usage: \(currentStr)."
        case .fileReadFailed(let fileName):
            return "Unable to read '\(fileName)'. The file may be inaccessible or corrupted."
        case .invalidFileType(let fileName):
            return "'\(fileName)' is not a supported file type."
        case .attachmentNotFound:
            return "The attachment could not be found."
        }
    }
}

// MARK: - Attachment Management

extension TaskManager {
    /// Add an attachment to a task from a file URL
    /// - Parameters:
    ///   - task: The task to add the attachment to
    ///   - fileURL: URL of the file to attach
    /// - Returns: Result containing the created TaskAttachment or an error
    func addAttachment(to task: Task, from fileURL: URL) -> Result<TaskAttachment, Error> {
        // Ensure we can access the file
        guard fileURL.startAccessingSecurityScopedResource() else {
            return .failure(AttachmentError.fileReadFailed(fileName: fileURL.lastPathComponent))
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }

        do {
            // Read file data
            let fileData = try Data(contentsOf: fileURL)
            let fileName = fileURL.lastPathComponent
            let fileSize = Int64(fileData.count)

            // Validate individual file size
            guard fileSize <= TaskAttachment.maxFileSize else {
                return .failure(AttachmentError.fileTooLarge(
                    fileName: fileName,
                    size: fileSize,
                    maxSize: TaskAttachment.maxFileSize
                ))
            }

            // Validate total size wouldn't exceed limit
            let currentTotalSize = totalAttachmentSize(for: task)
            let newTotalSize = currentTotalSize + fileSize
            guard newTotalSize <= TaskAttachment.maxTotalSize else {
                return .failure(AttachmentError.totalSizeExceeded(
                    currentSize: currentTotalSize + fileSize,
                    maxSize: TaskAttachment.maxTotalSize
                ))
            }

            // Detect MIME type
            let mimeType = getMimeType(for: fileURL)

            // Create attachment
            let attachment = TaskAttachment(
                fileName: fileName,
                fileSize: fileSize,
                mimeType: mimeType,
                fileData: fileData,
                thumbnailData: nil // Could generate thumbnails in the future
            )

            // Add to task and save
            if task.attachments == nil { task.attachments = [] }
            task.attachments!.append(attachment)
            task.modifiedDate = Date()

            try modelContext.save()
            return .success(attachment)

        } catch {
            return .failure(AttachmentError.fileReadFailed(fileName: fileURL.lastPathComponent))
        }
    }

    /// Delete an attachment from a task
    /// - Parameters:
    ///   - attachment: The attachment to delete
    ///   - task: The task to remove it from
    /// - Returns: Result indicating success or failure
    func deleteAttachment(_ attachment: TaskAttachment, from task: Task) -> Result<Void, Error> {
        // Remove from task's attachments array
        if task.attachments == nil { task.attachments = [] }
        task.attachments!.removeAll { $0.id == attachment.id }
        task.modifiedDate = Date()

        // Delete the attachment model
        modelContext.delete(attachment)

        // Save changes
        do {
            try modelContext.save()
            return .success(())
        } catch {
            return .failure(AttachmentError.attachmentNotFound)
        }
    }

    /// Calculate total size of all attachments for a task
    /// - Parameter task: The task to calculate size for
    /// - Returns: Total size in bytes
    func totalAttachmentSize(for task: Task) -> Int64 {
        (task.attachments ?? []).reduce(0) { $0 + $1.fileSize }
    }

    /// Get formatted string of total attachment size and remaining capacity
    /// - Parameter task: The task to check
    /// - Returns: Formatted string like "50 MB / 200 MB"
    func formattedAttachmentSize(for task: Task) -> String {
        let currentSize = totalAttachmentSize(for: task)
        let currentStr = ByteCountFormatter.string(fromByteCount: currentSize, countStyle: .file)
        let maxStr = ByteCountFormatter.string(fromByteCount: TaskAttachment.maxTotalSize, countStyle: .file)
        return "\(currentStr) / \(maxStr)"
    }

    /// Check if adding a file of given size would exceed limits
    /// - Parameters:
    ///   - task: The task to check
    ///   - fileSize: Size of file to potentially add
    /// - Returns: True if the file can be added without exceeding limits
    func canAddAttachment(to task: Task, withSize fileSize: Int64) -> Bool {
        guard fileSize <= TaskAttachment.maxFileSize else { return false }
        let newTotal = totalAttachmentSize(for: task) + fileSize
        return newTotal <= TaskAttachment.maxTotalSize
    }

    /// Get MIME type for a file URL
    /// - Parameter url: The file URL
    /// - Returns: MIME type string
    private func getMimeType(for url: URL) -> String {
        if let uti = UTType(filenameExtension: url.pathExtension),
           let mimeType = uti.preferredMIMEType {
            return mimeType
        }
        return "application/octet-stream" // Default fallback
    }
}
