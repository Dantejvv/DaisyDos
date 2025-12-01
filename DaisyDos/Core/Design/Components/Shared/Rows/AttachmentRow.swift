//
//  AttachmentRow.swift
//  DaisyDos
//
//  Standardized attachment row component
//  Works with both URL (staging) and TaskAttachment model (direct)
//

import SwiftUI

/// Protocol for attachment-like data that can be displayed in AttachmentRow
protocol AttachmentDisplayable {
    var fileName: String { get }
    var fileSize: String { get }
    var sfSymbolName: String { get }
}

/// A standardized attachment row with file icon, info, and delete button.
///
/// Features:
/// - File type icon with color coding
/// - File name and size display
/// - Delete button
/// - Tap gesture for preview
/// - Generic over any AttachmentDisplayable type
/// - Accessibility support
///
/// Example:
/// ```swift
/// AttachmentRow(
///     attachment: attachment,
///     accentColor: .blue,
///     onDelete: {
///         removeAttachment(attachment)
///     },
///     onTap: {
///         showPreview(attachment)
///     }
/// )
/// ```
struct AttachmentRow<T: AttachmentDisplayable>: View {
    let attachment: T
    let accentColor: Color
    let onDelete: () -> Void
    let onTap: () -> Void

    init(
        attachment: T,
        accentColor: Color = .blue,
        onDelete: @escaping () -> Void,
        onTap: @escaping () -> Void
    ) {
        self.attachment = attachment
        self.accentColor = accentColor
        self.onDelete = onDelete
        self.onTap = onTap
    }

    var body: some View {
        HStack(spacing: 12) {
            // File type icon
            Image(systemName: attachment.sfSymbolName)
                .font(.title2)
                .foregroundStyle(accentColor)
                .frame(width: 44, height: 44)
                .background(accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityHidden(true)

            // File info
            VStack(alignment: .leading, spacing: 4) {
                Text(attachment.fileName)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(attachment.fileSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundStyle(.red)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Delete attachment")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(attachment.fileName), \(attachment.fileSize)")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap to preview, swipe for delete button")
    }
}

// MARK: - URL Wrapper

/// Wrapper for file URLs (staging mode)
struct AttachmentURLWrapper: AttachmentDisplayable {
    let fileURL: URL

    var fileName: String {
        fileURL.lastPathComponent
    }

    var fileSize: String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let size = attributes[.size] as? Int64 else {
            return "Unknown size"
        }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    var sfSymbolName: String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "gif", "heic", "heif", "bmp", "tiff"].contains(ext) {
            return "photo"
        } else if ext == "pdf" {
            return "doc.text"
        } else if ["mp4", "mov", "avi", "mkv"].contains(ext) {
            return "video"
        } else if ["mp3", "m4a", "wav", "aac"].contains(ext) {
            return "music.note"
        } else if ["zip", "rar", "7z", "tar", "gz"].contains(ext) {
            return "doc.zipper"
        } else if ["doc", "docx", "pages"].contains(ext) {
            return "doc.text"
        } else if ["xls", "xlsx", "numbers"].contains(ext) {
            return "tablecells"
        } else if ["ppt", "pptx", "key"].contains(ext) {
            return "play.rectangle"
        } else {
            return "doc"
        }
    }
}

// MARK: - TaskAttachment Wrapper

/// Wrapper to make TaskAttachment conform to AttachmentDisplayable
struct TaskAttachmentWrapper: AttachmentDisplayable {
    let attachment: TaskAttachment

    var fileName: String {
        attachment.fileName
    }

    var fileSize: String {
        attachment.formattedFileSize
    }

    var sfSymbolName: String {
        attachment.sfSymbolName
    }
}

// MARK: - Convenience Views

/// Convenience view for URL-based attachments (Add/Edit staging)
struct AttachmentRowURL: View {
    let fileURL: URL
    let accentColor: Color
    let onDelete: () -> Void
    let onTap: () -> Void

    var body: some View {
        AttachmentRow(
            attachment: AttachmentURLWrapper(fileURL: fileURL),
            accentColor: accentColor,
            onDelete: onDelete,
            onTap: onTap
        )
    }
}

/// Convenience view for TaskAttachment model (Detail/Edit)
struct AttachmentRowModel: View {
    let attachment: TaskAttachment
    let accentColor: Color
    let onDelete: () -> Void
    let onTap: () -> Void

    var body: some View {
        AttachmentRow(
            attachment: TaskAttachmentWrapper(attachment: attachment),
            accentColor: accentColor,
            onDelete: onDelete,
            onTap: onTap
        )
    }
}

// MARK: - Preview

private struct PreviewAttachment: AttachmentDisplayable {
    let fileName: String
    let fileSize: String
    let sfSymbolName: String
}

#Preview {
    VStack(spacing: 0) {
        AttachmentRow(
            attachment: PreviewAttachment(
                fileName: "Document.pdf",
                fileSize: "2.5 MB",
                sfSymbolName: "doc.text"
            ),
            onDelete: { print("Delete") },
            onTap: { print("Tap") }
        )
        .padding(.vertical, 12)

        Divider().padding(.leading, 68)

        AttachmentRow(
            attachment: PreviewAttachment(
                fileName: "Photo_2024.jpg",
                fileSize: "1.2 MB",
                sfSymbolName: "photo"
            ),
            accentColor: .green,
            onDelete: { print("Delete") },
            onTap: { print("Tap") }
        )
        .padding(.vertical, 12)

        Divider().padding(.leading, 68)

        AttachmentRow(
            attachment: PreviewAttachment(
                fileName: "Very Long Filename That Might Wrap.docx",
                fileSize: "3.7 MB",
                sfSymbolName: "doc.text"
            ),
            accentColor: .purple,
            onDelete: { print("Delete") },
            onTap: { print("Tap") }
        )
        .padding(.vertical, 12)
    }
    .background(Color.daisySurface)
    .cornerRadius(12)
    .padding()
}
