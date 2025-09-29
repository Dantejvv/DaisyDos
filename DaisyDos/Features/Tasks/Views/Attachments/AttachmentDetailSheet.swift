//
//  AttachmentDetailSheet.swift
//  DaisyDos
//
//  Created by Claude Code on 9/28/25.
//

import SwiftUI
import QuickLook

struct AttachmentDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskManager.self) private var taskManager

    let attachment: TaskAttachment
    let onDelete: () -> Void
    let onShare: () -> Void

    @State private var fullSizeImage: UIImage?
    @State private var isLoading = true
    @State private var showingDeleteConfirmation = false
    @State private var showingQuickLook = false
    @State private var showingShareSheet = false
    @State private var zoomScale: CGFloat = 1.0
    @State private var lastZoomScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                if attachment.attachmentType == .image {
                    imageDetailView
                } else {
                    documentDetailView
                }
            }
            .navigationTitle(attachment.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        menuItems
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                loadContent()
            }
        }
        .quickLookPreview($showingQuickLook, items: quickLookItems)
        .sheet(isPresented: $showingShareSheet) {
            if let url = attachment.fullFilePath {
                ShareSheet(items: [url])
            }
        }
        .alert(
            "Delete Attachment",
            isPresented: $showingDeleteConfirmation
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete '\(attachment.displayName)'? This action cannot be undone.")
        }
    }

    // MARK: - Image Detail View

    @ViewBuilder
    private var imageDetailView: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            } else if let image = fullSizeImage {
                ScrollView([.horizontal, .vertical]) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(zoomScale)
                        .clipped()
                }
                .onTapGesture(count: 2) {
                    withAnimation(.spring(response: 0.4)) {
                        if zoomScale > 1.0 {
                            zoomScale = 1.0
                        } else {
                            zoomScale = 2.0
                        }
                    }
                }
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastZoomScale
                            lastZoomScale = value
                            let newScale = zoomScale * delta
                            zoomScale = min(max(newScale, 0.5), 5.0)
                        }
                        .onEnded { _ in
                            lastZoomScale = 1.0
                            if zoomScale < 1.0 {
                                withAnimation(.spring(response: 0.4)) {
                                    zoomScale = 1.0
                                }
                            }
                        }
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "photo")
                        .font(.system(size: 64))
                        .foregroundColor(.white.opacity(0.6))

                    Text("Unable to load image")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))

                    if attachment.fileExists {
                        Button("Open in Files") {
                            showingQuickLook = true
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.regularMaterial, in: Capsule())
                    } else {
                        Text("File not found")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }

            // Image metadata overlay
            if let metadata = attachment.imageMetadata, fullSizeImage != nil {
                VStack {
                    Spacer()
                    imageMetadataOverlay(metadata)
                }
            }
        }
    }

    // MARK: - Document Detail View

    @ViewBuilder
    private var documentDetailView: some View {
        VStack(spacing: 24) {
            // Large file icon
            attachment.displayIcon
                .font(.system(size: 120))
                .foregroundColor(.white.opacity(0.8))

            VStack(spacing: 12) {
                Text(attachment.displayName)
                    .font(.title2.weight(.medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    Label(attachment.attachmentType.displayName, systemImage: attachment.attachmentType.sfSymbol)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))

                    Label(attachment.formattedFileSize, systemImage: "internaldrive")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))

                    if attachment.fileExists {
                        Label("Available", systemImage: "checkmark.circle")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    } else {
                        Label("File not found", systemImage: "exclamationmark.triangle")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                }
            }

            if attachment.fileExists {
                Button("Open Document") {
                    showingQuickLook = true
                }
                .font(.headline)
                .foregroundColor(.black)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(.white, in: Capsule())
            }
        }
        .padding()
    }

    // MARK: - Image Metadata Overlay

    @ViewBuilder
    private func imageMetadataOverlay(_ metadata: TaskAttachment.ImageMetadata) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("\(metadata.width) × \(metadata.height)", systemImage: "viewfinder")
                Spacer()
                if let dateTaken = metadata.dateTimeTaken {
                    Label(dateTaken.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                }
            }

            if let cameraMake = metadata.cameraMake, let cameraModel = metadata.cameraModel {
                Label("\(cameraMake) \(cameraModel)", systemImage: "camera")
            }

            if let location = metadata.location {
                Label("Location: \(location.latitude), \(location.longitude)", systemImage: "location")
            }
        }
        .font(.caption)
        .foregroundColor(.white)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    // MARK: - Menu Items

    @ViewBuilder
    private var menuItems: some View {
        if attachment.fileExists {
            Button(action: {
                showingQuickLook = true
            }) {
                Label("Open in Files", systemImage: "folder")
            }

            Button(action: {
                showingShareSheet = true
                onShare()
            }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }

            Divider()
        }

        Button(action: {
            showingDeleteConfirmation = true
        }) {
            Label("Delete", systemImage: "trash")
        }
        .foregroundColor(.red)
    }

    // MARK: - Helper Properties

    private var quickLookItems: [URL] {
        guard let url = attachment.fullFilePath, attachment.fileExists else { return [] }
        return [url]
    }

    // MARK: - Helper Methods

    private func loadContent() {
        guard attachment.attachmentType == .image else {
            isLoading = false
            return
        }

        // Load full-size image
        if let filePath = attachment.fullFilePath,
           FileManager.default.fileExists(atPath: filePath.path) {
            _Concurrency.Task {
                let image = await loadImageFromFile(filePath)
                await MainActor.run {
                    fullSizeImage = image
                    isLoading = false
                }
            }
        } else {
            isLoading = false
        }
    }

    private func loadImageFromFile(_ url: URL) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let image = UIImage(contentsOfFile: url.path)
                continuation.resume(returning: image)
            }
        }
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - QuickLook Preview Extension

extension View {
    func quickLookPreview(_ isPresented: Binding<Bool>, items: [URL]) -> some View {
        self.sheet(isPresented: isPresented) {
            QuickLookPreview(urls: items)
        }
    }
}

struct QuickLookPreview: UIViewControllerRepresentable {
    let urls: [URL]

    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(urls: urls)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let urls: [URL]

        init(urls: [URL]) {
            self.urls = urls
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            urls.count
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            urls[index] as QLPreviewItem
        }
    }
}

#Preview("Image Detail") {
    AttachmentDetailSheet(
        attachment: .sampleImage,
        onDelete: {},
        onShare: {}
    )
}

#Preview("Document Detail") {
    AttachmentDetailSheet(
        attachment: .sampleDocument,
        onDelete: {},
        onShare: {}
    )
}