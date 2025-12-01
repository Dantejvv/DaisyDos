//
//  MultiPhotoPickerView.swift
//  DaisyDos
//
//  Created by Claude Code
//  Shared component for selecting multiple photos from library
//

import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif

#if canImport(PhotosUI)
/// PHPickerViewController wrapper for selecting multiple photos from library
struct MultiPhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedURLs: [URL]
    @Environment(\.dismiss) private var dismiss
    var selectionLimit: Int = 10

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
        let parent: MultiPhotoPickerView

        init(_ parent: MultiPhotoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                        guard let image = object as? UIImage,
                              let imageData = image.jpegData(compressionQuality: 0.8) else { return }

                        let tempURL = FileManager.default.temporaryDirectory
                            .appendingPathComponent(UUID().uuidString)
                            .appendingPathExtension("jpg")

                        try? imageData.write(to: tempURL)

                        DispatchQueue.main.async {
                            self?.parent.selectedURLs.append(tempURL)
                        }
                    }
                }
            }
        }
    }
}
#endif
