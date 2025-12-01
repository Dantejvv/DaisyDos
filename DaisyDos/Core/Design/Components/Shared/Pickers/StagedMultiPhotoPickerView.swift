//
//  StagedMultiPhotoPickerView.swift
//  DaisyDos
//
//  Created by Claude Code
//  Photo picker for Edit views that work with staged attachments
//

import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif

#if canImport(PhotosUI)

/// PHPickerViewController wrapper for selecting multiple photos with staged attachments
/// Uses a factory closure to create attachment items, allowing flexibility in attachment types
struct StagedMultiPhotoPickerView<AttachmentItem>: UIViewControllerRepresentable {
    @Binding var stagedAttachments: [AttachmentItem]
    @Environment(\.dismiss) private var dismiss
    var selectionLimit: Int = 10
    var createAttachment: (UUID?, URL, Bool) -> AttachmentItem

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = selectionLimit

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: StagedMultiPhotoPickerView

        init(_ parent: StagedMultiPhotoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                        guard let self = self,
                              let image = object as? UIImage,
                              let imageData = image.jpegData(compressionQuality: 0.8) else { return }

                        let tempURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent(UUID().uuidString)
                            .appendingPathExtension("jpg")

                        try? imageData.write(to: tempURL)

                        DispatchQueue.main.async {
                            let newAttachment = self.parent.createAttachment(nil, tempURL, false)
                            self.parent.stagedAttachments.append(newAttachment)
                        }
                    }
                }
            }
        }
    }
}
#endif
