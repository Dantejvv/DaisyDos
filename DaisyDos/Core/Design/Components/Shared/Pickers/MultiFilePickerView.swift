//
//  MultiFilePickerView.swift
//  DaisyDos
//
//  Created by Claude Code
//  Shared component for selecting multiple files
//

import SwiftUI
import UniformTypeIdentifiers

/// UIDocumentPickerViewController wrapper for selecting multiple files
struct MultiFilePickerView: UIViewControllerRepresentable {
    @Binding var selectedURLs: [URL]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: MultiFilePickerView

        init(_ parent: MultiFilePickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.selectedURLs.append(contentsOf: urls)
            parent.dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
