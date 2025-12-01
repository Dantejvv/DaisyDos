//
//  TaskAttachment.swift
//  DaisyDos
//
//  Created by Claude Code
//

import Foundation
import SwiftData
import UniformTypeIdentifiers

/// Represents a file attachment associated with a task
@Model
final class TaskAttachment {
    // MARK: - Properties

    /// Unique identifier for the attachment
    var id: UUID

    /// Original filename of the attached file
    var fileName: String

    /// Size of the file in bytes
    var fileSize: Int64

    /// MIME type of the file (e.g., "image/png", "application/pdf")
    var mimeType: String

    /// The actual file data stored in SwiftData
    @Attribute(.externalStorage)
    var fileData: Data

    /// Optional thumbnail data for preview (primarily for images)
    @Attribute(.externalStorage)
    var thumbnailData: Data?

    /// Date when the attachment was added
    var createdAt: Date

    /// Relationship to the parent task
    var task: Task?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        fileName: String,
        fileSize: Int64,
        mimeType: String,
        fileData: Data,
        thumbnailData: Data? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.fileData = fileData
        self.thumbnailData = thumbnailData
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    /// Human-readable file size (e.g., "1.5 MB")
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    /// File extension derived from filename
    var fileExtension: String {
        (fileName as NSString).pathExtension.lowercased()
    }

    /// Whether this attachment is an image
    var isImage: Bool {
        ["jpg", "jpeg", "png", "gif", "heic", "heif", "bmp", "tiff"].contains(fileExtension)
    }

    /// Whether this attachment is a PDF
    var isPDF: Bool {
        fileExtension == "pdf"
    }

    /// SF Symbol name appropriate for this file type
    var sfSymbolName: String {
        if isImage {
            return "photo"
        } else if isPDF {
            return "doc.text"
        } else if ["mp4", "mov", "avi", "mkv"].contains(fileExtension) {
            return "video"
        } else if ["mp3", "m4a", "wav", "aac"].contains(fileExtension) {
            return "music.note"
        } else if ["zip", "rar", "7z", "tar", "gz"].contains(fileExtension) {
            return "doc.zipper"
        } else if ["doc", "docx", "pages"].contains(fileExtension) {
            return "doc.text"
        } else if ["xls", "xlsx", "numbers"].contains(fileExtension) {
            return "tablecells"
        } else if ["ppt", "pptx", "key"].contains(fileExtension) {
            return "play.rectangle"
        } else {
            return "doc"
        }
    }
}

// MARK: - Constants

extension TaskAttachment {
    /// Maximum size for a single attachment (50 MB)
    static let maxFileSize: Int64 = 50 * 1024 * 1024

    /// Maximum total size for all attachments per task (200 MB)
    static let maxTotalSize: Int64 = 200 * 1024 * 1024
}
