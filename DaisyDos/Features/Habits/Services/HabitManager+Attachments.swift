//
//  HabitManager+Attachments.swift
//  DaisyDos
//
//  Created by Claude Code
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - Attachment-specific Errors

enum HabitAttachmentError: LocalizedError {
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
            return "Adding this file would exceed the \(maxStr) limit per habit. Current usage: \(currentStr)."
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

extension HabitManager {
    /// Add an attachment to a habit from a file URL
    /// - Parameters:
    ///   - habit: The habit to add the attachment to
    ///   - fileURL: URL of the file to attach
    /// - Returns: Result containing the created HabitAttachment or an error
    func addAttachment(to habit: Habit, from fileURL: URL) -> Result<HabitAttachment, Error> {
        // Try to access security-scoped resource if needed
        // Note: Returns false for non-security-scoped URLs (e.g., temp directory files)
        // which is expected and not an error - we can still read those files
        let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            // Read file data
            let fileData = try Data(contentsOf: fileURL)
            let fileName = fileURL.lastPathComponent
            let fileSize = Int64(fileData.count)

            // Validate individual file size
            guard fileSize <= HabitAttachment.maxFileSize else {
                return .failure(HabitAttachmentError.fileTooLarge(
                    fileName: fileName,
                    size: fileSize,
                    maxSize: HabitAttachment.maxFileSize
                ))
            }

            // Validate total size wouldn't exceed limit
            let currentTotalSize = totalAttachmentSize(for: habit)
            let newTotalSize = currentTotalSize + fileSize
            guard newTotalSize <= HabitAttachment.maxTotalSize else {
                return .failure(HabitAttachmentError.totalSizeExceeded(
                    currentSize: currentTotalSize + fileSize,
                    maxSize: HabitAttachment.maxTotalSize
                ))
            }

            // Detect MIME type
            let mimeType = getMimeType(for: fileURL)

            // Create attachment
            let attachment = HabitAttachment(
                fileName: fileName,
                fileSize: fileSize,
                mimeType: mimeType,
                fileData: fileData,
                thumbnailData: nil // Could generate thumbnails in the future
            )

            // Add to habit and save
            if habit.attachments == nil { habit.attachments = [] }
            habit.attachments!.append(attachment)
            habit.modifiedDate = Date()

            try modelContext.save()
            return .success(attachment)

        } catch {
            return .failure(HabitAttachmentError.fileReadFailed(fileName: fileURL.lastPathComponent))
        }
    }

    /// Delete an attachment from a habit
    /// - Parameters:
    ///   - attachment: The attachment to delete
    ///   - habit: The habit to remove it from
    /// - Returns: Result indicating success or failure
    func deleteAttachment(_ attachment: HabitAttachment, from habit: Habit) -> Result<Void, Error> {
        // Remove from habit's attachments array
        if habit.attachments == nil { habit.attachments = [] }
        habit.attachments!.removeAll { $0.id == attachment.id }
        habit.modifiedDate = Date()

        // Delete the attachment model
        modelContext.delete(attachment)

        // Save changes
        do {
            try modelContext.save()
            return .success(())
        } catch {
            return .failure(HabitAttachmentError.attachmentNotFound)
        }
    }

    /// Calculate total size of all attachments for a habit
    /// - Parameter habit: The habit to calculate size for
    /// - Returns: Total size in bytes
    func totalAttachmentSize(for habit: Habit) -> Int64 {
        (habit.attachments ?? []).reduce(0) { $0 + $1.fileSize }
    }

    /// Get formatted string of total attachment size and remaining capacity
    /// - Parameter habit: The habit to check
    /// - Returns: Formatted string like "50 MB / 200 MB"
    func formattedAttachmentSize(for habit: Habit) -> String {
        let currentSize = totalAttachmentSize(for: habit)
        let currentStr = ByteCountFormatter.string(fromByteCount: currentSize, countStyle: .file)
        let maxStr = ByteCountFormatter.string(fromByteCount: HabitAttachment.maxTotalSize, countStyle: .file)
        return "\(currentStr) / \(maxStr)"
    }

    /// Check if adding a file of given size would exceed limits
    /// - Parameters:
    ///   - habit: The habit to check
    ///   - fileSize: Size of file to potentially add
    /// - Returns: True if the file can be added without exceeding limits
    func canAddAttachment(to habit: Habit, withSize fileSize: Int64) -> Bool {
        guard fileSize <= HabitAttachment.maxFileSize else { return false }
        let newTotal = totalAttachmentSize(for: habit) + fileSize
        return newTotal <= HabitAttachment.maxTotalSize
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
