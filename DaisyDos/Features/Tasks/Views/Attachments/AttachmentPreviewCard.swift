//
//  AttachmentPreviewCard.swift
//  DaisyDos
//
//  Created by Claude Code on 9/28/25.
//

import SwiftUI

struct AttachmentPreviewCard: View {
    let attachment: TaskAttachment
    let displayMode: DisplayMode
    let onTap: () -> Void
    let onDelete: () -> Void
    let onShare: () -> Void

    @State private var thumbnailImage: UIImage?
    @State private var isLoading = true

    enum DisplayMode {
        case grid
        case list
        case compact

        var cardSize: CGSize {
            switch self {
            case .grid:
                return CGSize(width: 120, height: 120)
            case .list:
                return CGSize(width: 60, height: 60)
            case .compact:
                return CGSize(width: 40, height: 40)
            }
        }

        var showsMetadata: Bool {
            switch self {
            case .grid, .list:
                return true
            case .compact:
                return false
            }
        }
    }

    var body: some View {
        if displayMode == .list {
            listView
        } else {
            gridView
        }
    }

    // MARK: - Grid View

    @ViewBuilder
    private var gridView: some View {
        VStack(spacing: 8) {
            // Preview/Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.daisySurface)
                    .frame(
                        width: displayMode.cardSize.width,
                        height: displayMode == .compact ? displayMode.cardSize.height : displayMode.cardSize.height - 32
                    )

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.daisyTextSecondary)
                } else if let thumbnailImage = thumbnailImage {
                    Image(uiImage: thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(
                            width: displayMode.cardSize.width - 8,
                            height: (displayMode == .compact ? displayMode.cardSize.height : displayMode.cardSize.height - 32) - 8
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    VStack(spacing: 4) {
                        attachment.displayIcon
                            .font(displayMode == .compact ? .title3 : .largeTitle)

                        if displayMode != .compact {
                            Text(attachment.fileExtension.uppercased())
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.daisyTextSecondary)
                        }
                    }
                }

                // Type indicator overlay
                if displayMode == .grid && attachment.attachmentType != .image {
                    VStack {
                        HStack {
                            Spacer()
                            attachment.displayIcon
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(.regularMaterial, in: Circle())
                        }
                        Spacer()
                    }
                    .padding(4)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            .contextMenu {
                contextMenuItems
            }

            // Metadata
            if displayMode.showsMetadata {
                VStack(spacing: 2) {
                    Text(attachment.displayName)
                        .font(.caption)
                        .lineLimit(displayMode == .grid ? 2 : 1)
                        .foregroundColor(.daisyText)
                        .multilineTextAlignment(.center)

                    if displayMode == .grid {
                        Text(attachment.formattedFileSize)
                            .font(.caption2)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }
                .frame(width: displayMode.cardSize.width)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view attachment")
        .accessibilityAddTraits(.isButton)
        .onAppear {
            loadThumbnail()
        }
    }

    // MARK: - List View

    @ViewBuilder
    private var listView: some View {
        HStack(spacing: 12) {
            // Thumbnail/Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.daisySurface)
                    .frame(width: 60, height: 60)

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .foregroundColor(.daisyTextSecondary)
                } else if let thumbnailImage = thumbnailImage {
                    Image(uiImage: thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    attachment.displayIcon
                        .font(.title2)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(attachment.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(attachment.attachmentType.displayName)
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)

                    Text(attachment.formattedFileSize)
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }

                if let metadata = attachment.imageMetadata {
                    Text("\(metadata.width) × \(metadata.height)")
                        .font(.caption2)
                        .foregroundColor(.daisyTextSecondary)
                }
            }

            Spacer()

            // Actions
            Menu {
                contextMenuItems
            } label: {
                Image(systemName: "ellipsis")
                    .font(.subheadline)
                    .foregroundColor(.daisyTextSecondary)
                    .frame(width: 44, height: 44)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to view attachment")
        .accessibilityAddTraits(.isButton)
        .onAppear {
            loadThumbnail()
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var contextMenuItems: some View {
        Button(action: onTap) {
            Label("View", systemImage: "eye")
        }

        Button(action: onShare) {
            Label("Share", systemImage: "square.and.arrow.up")
        }

        Divider()

        Button(action: onDelete) {
            Label("Delete", systemImage: "trash")
        }
        .foregroundColor(.daisyError)
    }

    // MARK: - Helper Properties

    private var accessibilityLabel: String {
        let typeDescription = attachment.attachmentType.displayName.lowercased()
        let sizeDescription = attachment.formattedFileSize
        return "\(typeDescription), \(attachment.displayName), \(sizeDescription)"
    }

    // MARK: - Helper Methods

    private func loadThumbnail() {
        guard attachment.attachmentType == .image else {
            isLoading = false
            return
        }

        // Try to load thumbnail first
        if let thumbnailPath = attachment.fullThumbnailPath,
           FileManager.default.fileExists(atPath: thumbnailPath.path),
           let image = UIImage(contentsOfFile: thumbnailPath.path) {
            thumbnailImage = image
            isLoading = false
            return
        }

        // Fallback to main image file
        if let filePath = attachment.fullFilePath,
           FileManager.default.fileExists(atPath: filePath.path),
           let image = UIImage(contentsOfFile: filePath.path) {
            // Generate thumbnail on background queue
            _Concurrency.Task {
                let thumbnail = await generateThumbnail(from: image)
                await MainActor.run {
                    thumbnailImage = thumbnail
                    isLoading = false
                }
            }
        } else {
            isLoading = false
        }
    }

    private func generateThumbnail(from image: UIImage) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let thumbnailSize = CGSize(width: 200, height: 200)
                let thumbnail = image.preparingThumbnail(of: thumbnailSize)
                continuation.resume(returning: thumbnail)
            }
        }
    }
}

#Preview("Grid Mode") {
    VStack(spacing: 16) {
        AttachmentPreviewCard(
            attachment: .sampleImage,
            displayMode: .grid,
            onTap: {},
            onDelete: {},
            onShare: {}
        )

        AttachmentPreviewCard(
            attachment: .sampleDocument,
            displayMode: .grid,
            onTap: {},
            onDelete: {},
            onShare: {}
        )
    }
    .padding()
}

#Preview("List Mode") {
    VStack(spacing: 8) {
        AttachmentPreviewCard(
            attachment: .sampleImage,
            displayMode: .list,
            onTap: {},
            onDelete: {},
            onShare: {}
        )

        AttachmentPreviewCard(
            attachment: .sampleDocument,
            displayMode: .list,
            onTap: {},
            onDelete: {},
            onShare: {}
        )
    }
    .padding()
}

#Preview("Compact Mode") {
    HStack(spacing: 8) {
        AttachmentPreviewCard(
            attachment: .sampleImage,
            displayMode: .compact,
            onTap: {},
            onDelete: {},
            onShare: {}
        )

        AttachmentPreviewCard(
            attachment: .sampleDocument,
            displayMode: .compact,
            onTap: {},
            onDelete: {},
            onShare: {}
        )
    }
    .padding()
}