//
//  TaskAttachment.swift
//  DaisyDos
//
//  Created by Claude Code on 9/25/25.
//

import Foundation
import SwiftData
import SwiftUI
#if canImport(PhotoKit)
import PhotoKit
#endif
import UniformTypeIdentifiers

/// Task attachment system for files and photos with PhotoKit integration
/// Handles secure file storage and thumbnail generation with size limits
@Model
class TaskAttachment {

    // MARK: - Core Properties

    var id: UUID
    var fileName: String
    var originalFileName: String
    var fileExtension: String
    var mimeType: String
    var fileSizeBytes: Int64
    var createdDate: Date
    var modifiedDate: Date

    // MARK: - File Management

    var relativeFilePath: String // Relative to app container
    var thumbnailPath: String? // Optional thumbnail for images
    var fileHash: String? // For integrity verification

    // MARK: - Metadata

    var attachmentType: AttachmentType
    var imageMetadata: ImageMetadata?

    // MARK: - Relationships

    @Relationship(deleteRule: .nullify, inverse: \Task.attachments)
    var task: Task?

    // MARK: - Attachment Types

    enum AttachmentType: String, CaseIterable, Codable {
        case image = "image"
        case document = "document"
        case other = "other"

        var displayName: String {
            switch self {
            case .image:
                return "Image"
            case .document:
                return "Document"
            case .other:
                return "File"
            }
        }

        var sfSymbol: String {
            switch self {
            case .image:
                return "photo"
            case .document:
                return "doc.text"
            case .other:
                return "paperclip"
            }
        }

        var color: Color {
            switch self {
            case .image:
                return Colors.Secondary.teal
            case .document:
                return Colors.Secondary.blue
            case .other:
                return Colors.Secondary.purple
            }
        }
    }

    // MARK: - Image Metadata

    struct ImageMetadata: Codable {
        let width: Int
        let height: Int
        let orientation: Int?
        let cameraMake: String?
        let cameraModel: String?
        let dateTimeTaken: Date?
        let location: LocationData?

        struct LocationData: Codable {
            let latitude: Double
            let longitude: Double
        }
    }

    // MARK: - File Size Constraints

    static let maxFileSizeBytes: Int64 = 50 * 1024 * 1024 // 50MB per attachment
    static let maxTotalSizePerTask: Int64 = 200 * 1024 * 1024 // 200MB total per task

    static let supportedImageTypes: Set<UTType> = [.jpeg, .png, .heic, .gif, .webP]
    static let supportedDocumentTypes: Set<UTType> = [.pdf, .plainText, .rtf]

    // MARK: - Initializer

    init(
        fileName: String,
        originalFileName: String,
        fileExtension: String,
        mimeType: String,
        fileSizeBytes: Int64,
        relativeFilePath: String,
        attachmentType: AttachmentType,
        imageMetadata: ImageMetadata? = nil
    ) {
        self.id = UUID()
        self.fileName = fileName
        self.originalFileName = originalFileName
        self.fileExtension = fileExtension.lowercased()
        self.mimeType = mimeType
        self.fileSizeBytes = fileSizeBytes
        self.relativeFilePath = relativeFilePath
        self.attachmentType = attachmentType
        self.imageMetadata = imageMetadata
        self.createdDate = Date()
        self.modifiedDate = Date()
    }

    // MARK: - File Access

    var fullFilePath: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(relativeFilePath)
    }

    var fullThumbnailPath: URL? {
        guard let thumbnailPath = thumbnailPath,
              let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(thumbnailPath)
    }

    var fileExists: Bool {
        guard let path = fullFilePath else { return false }
        return FileManager.default.fileExists(atPath: path.path)
    }

    // MARK: - File Size Formatting

    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
    }

    // MARK: - Validation

    var isValidFileSize: Bool {
        return fileSizeBytes > 0 && fileSizeBytes <= Self.maxFileSizeBytes
    }

    static func isValidMimeType(_ mimeType: String) -> Bool {
        let supportedTypes = [
            // Images
            "image/jpeg", "image/png", "image/heic", "image/gif", "image/webp",
            // Documents
            "application/pdf", "text/plain", "text/rtf", "application/rtf"
        ]
        return supportedTypes.contains(mimeType.lowercased())
    }

    static func attachmentType(for mimeType: String) -> AttachmentType {
        if mimeType.hasPrefix("image/") {
            return .image
        } else if mimeType == "application/pdf" || mimeType.hasPrefix("text/") {
            return .document
        } else {
            return .other
        }
    }

    // MARK: - File Operations

    func deleteFile() -> Bool {
        guard let filePath = fullFilePath else { return false }

        do {
            // Delete main file
            if FileManager.default.fileExists(atPath: filePath.path) {
                try FileManager.default.removeItem(at: filePath)
            }

            // Delete thumbnail if exists
            if let thumbnailPath = fullThumbnailPath,
               FileManager.default.fileExists(atPath: thumbnailPath.path) {
                try FileManager.default.removeItem(at: thumbnailPath)
            }

            return true
        } catch {
            print("Failed to delete attachment file: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Thumbnail Generation

    func generateThumbnail() -> Bool {
        guard attachmentType == .image,
              let filePath = fullFilePath else {
            return false
        }

        return TaskAttachment.generateImageThumbnail(
            from: filePath,
            for: self
        )
    }

    static private func generateImageThumbnail(from filePath: URL, for attachment: TaskAttachment) -> Bool {
        guard let image = UIImage(contentsOfFile: filePath.path) else {
            return false
        }

        // Generate thumbnail (200x200 max)
        let thumbnailSize = CGSize(width: 200, height: 200)
        let thumbnail = image.preparingThumbnail(of: thumbnailSize)

        guard let thumbnailImage = thumbnail,
              let thumbnailData = thumbnailImage.jpegData(compressionQuality: 0.8) else {
            return false
        }

        // Save thumbnail
        let thumbnailFileName = "thumb_\(attachment.id.uuidString).jpg"
        let thumbnailRelativePath = "thumbnails/\(thumbnailFileName)"

        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return false
        }

        let thumbnailURL = documentsDirectory.appendingPathComponent(thumbnailRelativePath)
        let thumbnailDirectory = thumbnailURL.deletingLastPathComponent()

        do {
            // Create thumbnails directory if needed
            try FileManager.default.createDirectory(
                at: thumbnailDirectory,
                withIntermediateDirectories: true
            )

            // Write thumbnail
            try thumbnailData.write(to: thumbnailURL)
            attachment.thumbnailPath = thumbnailRelativePath
            return true
        } catch {
            print("Failed to save thumbnail: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - PhotoKit Integration

    #if canImport(PhotoKit)
    static func requestPhotoLibraryPermission() async -> PHAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                continuation.resume(returning: status)
            }
        }
    }

    static func createFromPHAsset(_ asset: PHAsset) async -> TaskAttachment? {
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.deliveryMode = .highQualityFormat

        return await withCheckedContinuation { continuation in
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, orientation, _ in
                guard let data = data else {
                    continuation.resume(returning: nil)
                    return
                }

                let fileName = UUID().uuidString
                let fileExtension = "jpg" // Default to JPEG for photos
                let originalFileName = asset.value(forKey: "filename") as? String ?? "\(fileName).\(fileExtension)"
                let mimeType = "image/jpeg"
                let fileSizeBytes = Int64(data.count)

                // Create directory structure
                let attachmentsPath = "attachments/\(fileName).\(fileExtension)"

                guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    continuation.resume(returning: nil)
                    return
                }

                let fileURL = documentsDirectory.appendingPathComponent(attachmentsPath)
                let fileDirectory = fileURL.deletingLastPathComponent()

                do {
                    try FileManager.default.createDirectory(
                        at: fileDirectory,
                        withIntermediateDirectories: true
                    )
                    try data.write(to: fileURL)

                    // Extract metadata
                    var imageMetadata: ImageMetadata?
                    if let location = asset.location {
                        imageMetadata = ImageMetadata(
                            width: Int(asset.pixelWidth),
                            height: Int(asset.pixelHeight),
                            orientation: orientation.rawValue,
                            cameraMake: nil,
                            cameraModel: nil,
                            dateTimeTaken: asset.creationDate,
                            location: ImageMetadata.LocationData(
                                latitude: location.coordinate.latitude,
                                longitude: location.coordinate.longitude
                            )
                        )
                    } else {
                        imageMetadata = ImageMetadata(
                            width: Int(asset.pixelWidth),
                            height: Int(asset.pixelHeight),
                            orientation: orientation.rawValue,
                            cameraMake: nil,
                            cameraModel: nil,
                            dateTimeTaken: asset.creationDate,
                            location: nil
                        )
                    }

                    let attachment = TaskAttachment(
                        fileName: fileName,
                        originalFileName: originalFileName,
                        fileExtension: fileExtension,
                        mimeType: mimeType,
                        fileSizeBytes: fileSizeBytes,
                        relativeFilePath: attachmentsPath,
                        attachmentType: .image,
                        imageMetadata: imageMetadata
                    )

                    // Generate thumbnail
                    _ = attachment.generateThumbnail()

                    continuation.resume(returning: attachment)
                } catch {
                    print("Failed to save photo attachment: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    #endif

    // MARK: - File Import

    static func createFromFileURL(_ fileURL: URL) async -> TaskAttachment? {
        guard fileURL.startAccessingSecurityScopedResource() else {
            return nil
        }
        defer { fileURL.stopAccessingSecurityScopedResource() }

        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0

            guard fileSize <= maxFileSizeBytes else {
                print("File too large: \(fileSize) bytes")
                return nil
            }

            let fileName = UUID().uuidString
            let fileExtension = fileURL.pathExtension.lowercased()
            let originalFileName = fileURL.lastPathComponent

            // Determine MIME type
            let mimeType = UTType(filenameExtension: fileExtension)?.preferredMIMEType ?? "application/octet-stream"

            guard isValidMimeType(mimeType) else {
                print("Unsupported file type: \(mimeType)")
                return nil
            }

            // Copy file to attachments directory
            let attachmentsPath = "attachments/\(fileName).\(fileExtension)"

            guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
            }

            let destinationURL = documentsDirectory.appendingPathComponent(attachmentsPath)
            let destinationDirectory = destinationURL.deletingLastPathComponent()

            try FileManager.default.createDirectory(
                at: destinationDirectory,
                withIntermediateDirectories: true
            )
            try FileManager.default.copyItem(at: fileURL, to: destinationURL)

            let attachment = TaskAttachment(
                fileName: fileName,
                originalFileName: originalFileName,
                fileExtension: fileExtension,
                mimeType: mimeType,
                fileSizeBytes: fileSize,
                relativeFilePath: attachmentsPath,
                attachmentType: attachmentType(for: mimeType)
            )

            // Generate thumbnail for images
            if attachment.attachmentType == .image {
                _ = attachment.generateThumbnail()
            }

            return attachment
        } catch {
            print("Failed to import file: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Display Helpers

    var displayIcon: some View {
        Image(systemName: attachmentType.sfSymbol)
            .foregroundColor(attachmentType.color)
    }

    var displayName: String {
        if originalFileName.isEmpty {
            return "\(fileName).\(fileExtension)"
        }
        return originalFileName
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension TaskAttachment {
    static var sampleImage: TaskAttachment {
        TaskAttachment(
            fileName: "sample_image",
            originalFileName: "My Photo.jpg",
            fileExtension: "jpg",
            mimeType: "image/jpeg",
            fileSizeBytes: 2048000,
            relativeFilePath: "attachments/sample_image.jpg",
            attachmentType: .image,
            imageMetadata: ImageMetadata(
                width: 1920,
                height: 1080,
                orientation: 1,
                cameraMake: "Apple",
                cameraModel: "iPhone 15 Pro",
                dateTimeTaken: Date(),
                location: nil
            )
        )
    }

    static var sampleDocument: TaskAttachment {
        TaskAttachment(
            fileName: "sample_doc",
            originalFileName: "Important Document.pdf",
            fileExtension: "pdf",
            mimeType: "application/pdf",
            fileSizeBytes: 1024000,
            relativeFilePath: "attachments/sample_doc.pdf",
            attachmentType: .document
        )
    }
}
#endif