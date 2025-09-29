//
//  AttachmentPickerSheet.swift
//  DaisyDos
//
//  Created by Claude Code on 9/28/25.
//

import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
#if canImport(PhotoKit)
import PhotoKit
#endif

struct AttachmentPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TaskManager.self) private var taskManager

    let task: Task
    let onAttachmentAdded: (TaskAttachment) -> Void

    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var showingDocumentPicker = false
    @State private var showingCamera = false
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var processingMessage = ""
    @State private var errorMessage: String?

    private let maxSelectionCount = 5

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView

                // Options
                ScrollView {
                    LazyVStack(spacing: 16) {
                        photosSection
                        documentsSection
                        cameraSection

                        if task.attachmentCount > 0 {
                            currentAttachmentsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Attachment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isProcessing {
                    processingOverlay
                }
            }
            .onChange(of: selectedPhotoItems) { _, newItems in
                processSelectedPhotos(newItems)
            }
            .photosPicker(
                isPresented: .constant(false),
                selection: $selectedPhotoItems,
                maxSelectionCount: maxSelectionCount,
                matching: .any(of: [.images, .videos])
            )
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: supportedDocumentTypes,
                allowsMultipleSelection: true
            ) { result in
                processDocumentPickerResult(result)
            }
            .fullScreenCover(isPresented: $showingCamera) {
                CameraView { image in
                    processCameraImage(image)
                }
                .ignoresSafeArea()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - Header View

    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add files to")
                        .font(.subheadline)
                        .foregroundColor(.daisyTextSecondary)

                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.daisyText)
                        .lineLimit(2)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(task.attachmentCount)")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.daisyTask)

                    Text("files")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }

            if task.totalAttachmentSize > 0 {
                HStack {
                    Text("Current size: \(formatBytes(task.totalAttachmentSize))")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)

                    Spacer()

                    Text("Limit: \(formatBytes(TaskAttachment.maxTotalSizePerTask))")
                        .font(.caption)
                        .foregroundColor(.daisyTextSecondary)
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }

    // MARK: - Photos Section

    @ViewBuilder
    private var photosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos & Videos")
                .font(.headline)
                .foregroundColor(.daisyText)

            PhotosPicker(
                selection: $selectedPhotoItems,
                maxSelectionCount: maxSelectionCount,
                matching: .any(of: [.images, .videos])
            ) {
                PickerOptionCard(
                    title: "Choose from Library",
                    subtitle: "Select photos or videos from your library",
                    icon: "photo.on.rectangle.angled",
                    color: .daisyTask,
                    badge: nil
                )
            }
            .accessibilityLabel("Choose photos or videos from library")
        }
    }

    // MARK: - Documents Section

    @ViewBuilder
    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Documents")
                .font(.headline)
                .foregroundColor(.daisyText)

            Button(action: {
                showingDocumentPicker = true
            }) {
                PickerOptionCard(
                    title: "Browse Files",
                    subtitle: "Add documents, PDFs, and other files",
                    icon: "folder",
                    color: Colors.Secondary.blue,
                    badge: supportedFileTypes.count
                )
            }
            .accessibilityLabel("Browse and select documents")
        }
    }

    // MARK: - Camera Section

    @ViewBuilder
    private var cameraSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Camera")
                .font(.headline)
                .foregroundColor(.daisyText)

            Button(action: {
                showingCamera = true
            }) {
                PickerOptionCard(
                    title: "Take Photo",
                    subtitle: "Capture a new photo with your camera",
                    icon: "camera",
                    color: Colors.Secondary.teal,
                    badge: nil
                )
            }
            .accessibilityLabel("Take a new photo with camera")
        }
    }

    // MARK: - Current Attachments Section

    @ViewBuilder
    private var currentAttachmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Attachments")
                    .font(.headline)
                    .foregroundColor(.daisyText)

                Spacer()

                Text("\(task.attachmentCount)")
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.regularMaterial, in: Capsule())
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(Array(task.attachments.prefix(6)), id: \.id) { attachment in
                    AttachmentPreviewCard(
                        attachment: attachment,
                        displayMode: .compact,
                        onTap: {},
                        onDelete: {},
                        onShare: {}
                    )
                }

                if task.attachmentCount > 6 {
                    VStack {
                        Text("+\(task.attachmentCount - 6)")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.daisyTextSecondary)
                        Text("more")
                            .font(.caption2)
                            .foregroundColor(.daisyTextSecondary)
                    }
                    .frame(width: 40, height: 40)
                    .background(Color.daisySurface.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Processing Overlay

    @ViewBuilder
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.daisyTask)

                Text(processingMessage)
                    .font(.headline)
                    .foregroundColor(.daisyText)

                if processingProgress > 0 {
                    ProgressView(value: processingProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 200)
                }
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Helper Properties

    private var supportedDocumentTypes: [UTType] {
        [.pdf, .plainText, .rtf, .commaSeparatedText]
    }

    private var supportedFileTypes: [String] {
        ["PDF", "TXT", "RTF", "CSV"]
    }

    // MARK: - Processing Methods

    private func processSelectedPhotos(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }

        isProcessing = true
        processingMessage = "Processing photos..."
        processingProgress = 0.0

        _Concurrency.Task {
            let totalItems = items.count
            var processedCount = 0

            for item in items {
                await MainActor.run {
                    processingProgress = Double(processedCount) / Double(totalItems)
                    processingMessage = "Processing photo \(processedCount + 1) of \(totalItems)"
                }

                if let data = try? await item.loadTransferable(type: Data.self) {
                    await processPhotoData(data, originalItem: item)
                }

                processedCount += 1
            }

            await MainActor.run {
                isProcessing = false
                selectedPhotoItems = []
                dismiss()
            }
        }
    }

    private func processCameraPhotoData(_ data: Data) async {
        // Process camera photo without PhotosPickerItem
        await processPhotoDataCommon(data, originalFileName: "Camera Photo.jpg")
    }

    private func processPhotoData(_ data: Data, originalItem: PhotosPickerItem) async {
        // Process photos picker photo
        await processPhotoDataCommon(data, originalFileName: "Photo.jpg")
    }

    private func processPhotoDataCommon(_ data: Data, originalFileName: String) async {
        // Validate file size
        guard data.count <= TaskAttachment.maxFileSizeBytes else {
            await showError("Photo is too large. Maximum size is \(formatBytes(TaskAttachment.maxFileSizeBytes)).")
            return
        }

        // Check total size limit
        let newTotalSize = Int64(data.count) + task.totalAttachmentSize
        guard newTotalSize <= TaskAttachment.maxTotalSizePerTask else {
            await showError("Adding this photo would exceed the task attachment limit of \(formatBytes(TaskAttachment.maxTotalSizePerTask)).")
            return
        }

        // Create attachment
        let fileName = UUID().uuidString
        let fileExtension = "jpg"
        let mimeType = "image/jpeg"
        let attachmentsPath = "attachments/\(fileName).\(fileExtension)"

        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            await showError("Unable to access document directory.")
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

            let attachment = TaskAttachment(
                fileName: fileName,
                originalFileName: originalFileName,
                fileExtension: fileExtension,
                mimeType: mimeType,
                fileSizeBytes: Int64(data.count),
                relativeFilePath: attachmentsPath,
                attachmentType: .image
            )

            // Generate thumbnail
            _ = attachment.generateThumbnail()

            await MainActor.run {
                let result = taskManager.addAttachment(attachment, to: task)
                if case .success = result {
                    onAttachmentAdded(attachment)
                } else if case .failure(let error) = result {
                    errorMessage = error.userMessage
                }
            }
        } catch {
            await showError("Failed to save photo: \(error.localizedDescription)")
        }
    }

    private func processDocumentPickerResult(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            processDocumentURLs(urls)
        case .failure(let error):
            errorMessage = "Failed to access selected files: \(error.localizedDescription)"
        }
    }

    private func processDocumentURLs(_ urls: [URL]) {
        guard !urls.isEmpty else { return }

        isProcessing = true
        processingMessage = "Processing documents..."
        processingProgress = 0.0

        _Concurrency.Task {
            let totalFiles = urls.count
            var processedCount = 0

            for url in urls {
                await MainActor.run {
                    processingProgress = Double(processedCount) / Double(totalFiles)
                    processingMessage = "Processing document \(processedCount + 1) of \(totalFiles)"
                }

                if let attachment = await TaskAttachment.createFromFileURL(url) {
                    await MainActor.run {
                        let result = taskManager.addAttachment(attachment, to: task)
                        if case .success = result {
                            onAttachmentAdded(attachment)
                        } else if case .failure(let error) = result {
                            errorMessage = error.userMessage
                        }
                    }
                }

                processedCount += 1
            }

            await MainActor.run {
                isProcessing = false
                dismiss()
            }
        }
    }

    private func processCameraImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "Failed to process camera image."
            return
        }

        isProcessing = true
        processingMessage = "Processing camera photo..."

        _Concurrency.Task {
            await processCameraPhotoData(data)
            await MainActor.run {
                isProcessing = false
                dismiss()
            }
        }
    }

    private func showError(_ message: String) async {
        await MainActor.run {
            errorMessage = message
            isProcessing = false
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

// MARK: - Picker Option Card

struct PickerOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let badge: Int?

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                if let badge = badge {
                    VStack {
                        HStack {
                            Spacer()
                            Text("\(badge)")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(color, in: Capsule())
                        }
                        Spacer()
                    }
                    .frame(width: 56, height: 56)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.daisyText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.daisyTextSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.daisyTextSecondary)
        }
        .padding()
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Camera View

struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImageCaptured: onImageCaptured, dismiss: dismiss)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onImageCaptured: (UIImage) -> Void
        let dismiss: DismissAction

        init(onImageCaptured: @escaping (UIImage) -> Void, dismiss: DismissAction) {
            self.onImageCaptured = onImageCaptured
            self.dismiss = dismiss
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImageCaptured(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Task.self, TaskAttachment.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )

    let taskManager = TaskManager(modelContext: container.mainContext)
    let task = Task(title: "Sample Task for Attachments")

    container.mainContext.insert(task)
    try! container.mainContext.save()

    return AttachmentPickerSheet(
        task: task,
        onAttachmentAdded: { _ in }
    )
    .modelContainer(container)
    .environment(taskManager)
}