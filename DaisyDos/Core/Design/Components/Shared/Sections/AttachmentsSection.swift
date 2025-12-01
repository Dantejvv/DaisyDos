//
//  AttachmentsSection.swift
//  DaisyDos
//
//  Standardized attachments section for Add/Edit/Detail views
//  Displays attachments with size indicator and add button
//

import SwiftUI

/// A standardized section for displaying and managing attachments.
///
/// Features:
/// - Header with total size indicator
/// - Attachment list with dividers
/// - "Add Attachment" button
/// - Read-only mode support
/// - Consistent styling
/// - Generic over attachment types
///
/// Example with URLs (staging mode):
/// ```swift
/// AttachmentsSectionURL(
///     attachments: $attachments,
///     accentColor: .daisyTask,
///     isReadOnly: false,
///     onAdd: {
///         showingAttachmentPicker = true
///     },
///     onDelete: { url in
///         attachments.removeAll { $0 == url }
///     },
///     onTap: { url in
///         previewAttachment(url)
///     }
/// )
/// ```
struct AttachmentsSectionURL: View {
    @Binding var attachments: [URL]
    let accentColor: Color
    let isReadOnly: Bool
    let onAdd: () -> Void
    let onDelete: (URL) -> Void
    let onTap: (URL) -> Void

    init(
        attachments: Binding<[URL]>,
        accentColor: Color = .daisyTask,
        isReadOnly: Bool = false,
        onAdd: @escaping () -> Void,
        onDelete: @escaping (URL) -> Void,
        onTap: @escaping (URL) -> Void
    ) {
        self._attachments = attachments
        self.accentColor = accentColor
        self.isReadOnly = isReadOnly
        self.onAdd = onAdd
        self.onDelete = onDelete
        self.onTap = onTap
    }

    private var totalSize: Int64 {
        attachments.reduce(0) { total, url in
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let size = attributes[.size] as? Int64 else {
                return total
            }
            return total + size
        }
    }

    private var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("Attachments")
                .font(.headline)
                .foregroundColor(.daisyText)

            if !attachments.isEmpty {
                // Size indicator
                HStack {
                    Image(systemName: "doc.badge.arrow.up")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(formattedSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }

                // Attachment rows
                VStack(spacing: 0) {
                    ForEach(Array(attachments.enumerated()), id: \.element.absoluteString) { index, fileURL in
                        VStack(spacing: 0) {
                            AttachmentRowURL(
                                fileURL: fileURL,
                                accentColor: accentColor,
                                onDelete: {
                                    withAnimation {
                                        onDelete(fileURL)
                                    }
                                },
                                onTap: {
                                    onTap(fileURL)
                                }
                            )
                            .padding(.vertical, 12)

                            if index < attachments.count - 1 {
                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                }
            }

            // Add attachment button
            if !isReadOnly {
                Button(action: onAdd) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle")
                        Text("Add Attachment")
                    }
                    .font(.body)
                    .foregroundColor(accentColor)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add attachment")
            }
        }
        .padding(16)
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 16)
    }
}

/// Attachments section for TaskAttachment models (direct mode)
struct AttachmentsSectionModel: View {
    let attachments: [TaskAttachment]
    let accentColor: Color
    let isReadOnly: Bool
    let onAdd: () -> Void
    let onDelete: (TaskAttachment) -> Void
    let onTap: (TaskAttachment) -> Void

    init(
        attachments: [TaskAttachment],
        accentColor: Color = .daisyTask,
        isReadOnly: Bool = false,
        onAdd: @escaping () -> Void,
        onDelete: @escaping (TaskAttachment) -> Void,
        onTap: @escaping (TaskAttachment) -> Void
    ) {
        self.attachments = attachments
        self.accentColor = accentColor
        self.isReadOnly = isReadOnly
        self.onAdd = onAdd
        self.onDelete = onDelete
        self.onTap = onTap
    }

    private var totalSize: Int64 {
        attachments.reduce(0) { $0 + $1.fileSize }
    }

    private var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("Attachments")
                .font(.headline)
                .foregroundColor(.daisyText)

            if !attachments.isEmpty {
                // Size indicator
                HStack {
                    Image(systemName: "doc.badge.arrow.up")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(formattedSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }

                // Attachment rows
                VStack(spacing: 0) {
                    ForEach(Array(attachments.enumerated()), id: \.element.id) { index, attachment in
                        VStack(spacing: 0) {
                            AttachmentRowModel(
                                attachment: attachment,
                                accentColor: accentColor,
                                onDelete: {
                                    withAnimation {
                                        onDelete(attachment)
                                    }
                                },
                                onTap: {
                                    onTap(attachment)
                                }
                            )
                            .padding(.vertical, 12)

                            if index < attachments.count - 1 {
                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                }
            }

            // Add attachment button
            if !isReadOnly {
                Button(action: onAdd) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle")
                        Text("Add Attachment")
                    }
                    .font(.body)
                    .foregroundColor(accentColor)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add attachment")
            }
        }
        .padding(16)
        .background(Color.daisySurface)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 16)
    }
}

#Preview {
    @Previewable @State var urls: [URL] = []

    VStack(spacing: 20) {
        // Empty state
        AttachmentsSectionURL(
            attachments: $urls,
            onAdd: { print("Add tapped") },
            onDelete: { _ in },
            onTap: { _ in }
        )

        // Read-only empty state
        AttachmentsSectionURL(
            attachments: $urls,
            isReadOnly: true,
            onAdd: { print("Add tapped") },
            onDelete: { _ in },
            onTap: { _ in }
        )

        Text("Preview: Attachments would appear when added")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
}
