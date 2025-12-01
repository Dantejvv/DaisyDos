//
//  AttachmentPreviewSection.swift
//  DaisyDos
//
//  Read-only attachment preview section for Detail views
//  Displays visual previews with tap-to-view functionality
//

import SwiftUI

/// A read-only preview section for displaying attachments in detail views.
///
/// Features:
/// - Visual grid layout for image attachments (2-3 columns)
/// - List layout for non-image attachments
/// - Tap gesture for QuickLook preview
/// - File type indicators with icons
/// - Size and metadata display
/// - Accessibility support
///
/// Example usage:
/// ```swift
/// AttachmentPreviewSection(
///     attachments: task.attachments,
///     accentColor: .daisyTask,
///     onTap: { attachment in
///         // Convert attachment to URL for QuickLook
///         attachmentToPreview = createTempURL(from: attachment)
///     }
/// )
/// ```
struct AttachmentPreviewSection<Attachment>: View where Attachment: AttachmentPreviewable {
    let attachments: [Attachment]
    let accentColor: Color
    let onTap: (Attachment) -> Void

    private let imageColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Attachments")
                .font(.headline)
                .foregroundColor(.daisyText)

            if attachments.isEmpty {
                // Empty state
                HStack {
                    Text("None")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.daisyTextSecondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
            } else {
                // Separate images and other files
                let images = attachments.filter { $0.isImage }
                let otherFiles = attachments.filter { !$0.isImage }

                // Total size and count
                HStack {
                    Image(systemName: "paperclip")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)

                    Text("\(attachments.count) \(attachments.count == 1 ? "attachment" : "attachments")")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)

                    Spacer()

                    Text(totalSize)
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
                .padding(.bottom, 8)

                // Images in grid
                if !images.isEmpty {
                    LazyVGrid(columns: imageColumns, spacing: 8) {
                        ForEach(images, id: \.id) { attachment in
                            ImagePreviewCard(
                                attachment: attachment,
                                accentColor: accentColor,
                                onTap: { onTap(attachment) }
                            )
                        }
                    }
                }

                // Other files in list
                if !otherFiles.isEmpty {
                    if !images.isEmpty {
                        Divider()
                            .padding(.vertical, 8)
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(otherFiles.enumerated()), id: \.element.id) { index, attachment in
                            VStack(spacing: 0) {
                                FilePreviewRow(
                                    attachment: attachment,
                                    accentColor: accentColor,
                                    onTap: { onTap(attachment) }
                                )
                                .padding(.vertical, 12)

                                if index < otherFiles.count - 1 {
                                    Divider()
                                        .padding(.leading, 60)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    private var totalSize: String {
        let total = attachments.reduce(0) { $0 + $1.fileSize }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
}

// MARK: - Image Preview Card

private struct ImagePreviewCard<Attachment: AttachmentPreviewable>: View {
    let attachment: Attachment
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Image preview
                if let thumbnailData = attachment.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                } else if let uiImage = UIImage(data: attachment.fileData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipped()
                } else {
                    // Fallback to icon
                    ZStack {
                        Color.daisyBackground
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.daisyTextSecondary)
                    }
                    .frame(height: 120)
                }

                // Filename overlay
                HStack {
                    Text(attachment.fileName)
                        .font(.caption2)
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Color.black.opacity(0.7),
                            in: RoundedRectangle(cornerRadius: 4)
                        )
                    Spacer()
                }
                .padding(8)
            }
            .background(Color.daisyBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.daisyTextSecondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Image: \(attachment.fileName)")
        .accessibilityHint("Tap to preview")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - File Preview Row

private struct FilePreviewRow<Attachment: AttachmentPreviewable>: View {
    let attachment: Attachment
    let accentColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // File type icon
                Image(systemName: attachment.sfSymbolName)
                    .font(.title2)
                    .foregroundColor(accentColor)
                    .frame(width: 44, height: 44)
                    .background(accentColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // File info
                VStack(alignment: .leading, spacing: 4) {
                    Text(attachment.fileName)
                        .font(.body)
                        .foregroundColor(.daisyText)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text(attachment.formattedFileSize)
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)

                        Text(attachment.createdAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }

                Spacer()

                // Chevron indicator
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(attachment.fileName), \(attachment.formattedFileSize)")
        .accessibilityHint("Tap to preview")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Attachment Previewable Protocol

/// Protocol for attachment types that can be displayed in AttachmentPreviewSection
protocol AttachmentPreviewable: Identifiable {
    var id: UUID { get }
    var fileName: String { get }
    var fileSize: Int64 { get }
    var formattedFileSize: String { get }
    var sfSymbolName: String { get }
    var isImage: Bool { get }
    var fileData: Data { get }
    var thumbnailData: Data? { get }
    var createdAt: Date { get }
}

// MARK: - TaskAttachment Conformance

extension TaskAttachment: AttachmentPreviewable {}

// MARK: - HabitAttachment Conformance

extension HabitAttachment: AttachmentPreviewable {}

// MARK: - Preview

#Preview("With Images and Files") {
    ScrollView {
        VStack(spacing: 20) {
            // Mock preview with sample data
            Text("Preview placeholder - requires actual TaskAttachment/HabitAttachment models")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
        .padding()
    }
    .background(Color.daisyBackground)
}
