//
//  StagedMultiFilePickerView.swift
//  DaisyDos
//
//  Created by Claude Code
//  File picker for Edit views that work with staged attachments
//

import SwiftUI
import UniformTypeIdentifiers

/// UIDocumentPickerViewController wrapper for selecting multiple files with staged attachments
/// Uses a factory closure to create attachment items, allowing flexibility in attachment types
struct StagedMultiFilePickerView<AttachmentItem>: UIViewControllerRepresentable {
    @Binding var stagedAttachments: [AttachmentItem]
    @Environment(\.dismiss) private var dismiss
    var createAttachment: (UUID?, URL, Bool) -> AttachmentItem

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
        let parent: StagedMultiFilePickerView

        init(_ parent: StagedMultiFilePickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                let newAttachment = parent.createAttachment(nil, url, false)
                parent.stagedAttachments.append(newAttachment)
            }
            parent.dismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.dismiss()
        }
    }
}
