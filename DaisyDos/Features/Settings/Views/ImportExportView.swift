//
//  ImportExportView.swift
//  DaisyDos
//
//  Created by Claude Code on 11/12/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppearanceManager.self) private var appearanceManager

    @State private var selectedFormat: ImportExportManager.ExportFormat = .json
    @State private var showingExportShareSheet = false
    @State private var exportURL: URL?
    @State private var showingImportPicker = false
    @State private var isExporting = false
    @State private var error: DaisyDosError?
    @State private var importSummary: ImportExportManager.ImportSummary?
    @State private var showingImportSuccess = false

    private var importExportManager: ImportExportManager {
        ImportExportManager(modelContext: modelContext)
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Export Section
                Section {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(ImportExportManager.ExportFormat.allCases) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button(action: exportData) {
                        if isExporting {
                            HStack {
                                Label("Exporting...", systemImage: "arrow.down.doc")
                                Spacer()
                                ProgressView()
                            }
                        } else {
                            Label("Export Data", systemImage: "arrow.down.doc")
                        }
                    }
                    .disabled(isExporting)
                } header: {
                    Text("Export")
                } footer: {
                    Text("Export all tasks, habits, and tags. Note: Attachments are not included in exports.")
                        .foregroundColor(.daisyTextSecondary)
                }

                // MARK: - Import Section
                Section {
                    Button(action: { showingImportPicker = true }) {
                        Label("Import Data", systemImage: "arrow.up.doc")
                    }
                } header: {
                    Text("Import")
                } footer: {
                    Text("Import data from a DaisyDos JSON export file. Only JSON format is supported for imports.")
                        .foregroundColor(.daisyTextSecondary)
                }

                // MARK: - Important Notes
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.daisyWarning)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Attachments Not Included")
                                    .font(.subheadline.weight(.semibold))
                                Text("File attachments are not included in exports due to size limitations.")
                                    .font(.caption)
                                    .foregroundColor(.daisyTextSecondary)
                            }
                        }

                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "info.circle")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Import Creates New Items")
                                    .font(.subheadline.weight(.semibold))
                                Text("Importing data creates new items. It does not merge with or replace existing data.")
                                    .font(.caption)
                                    .foregroundColor(.daisyTextSecondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Important Notes")
                }
            }
            .navigationTitle("Import/Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingExportShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .alert("Error", isPresented: .constant(error != nil), presenting: error) { _ in
                Button("OK") {
                    error = nil
                }
            } message: { error in
                Text(error.userMessage)
            }
            .alert("Import Successful", isPresented: $showingImportSuccess, presenting: importSummary) { _ in
                Button("OK") {
                    importSummary = nil
                }
            } message: { summary in
                Text("Imported \(summary.tasksImported) tasks, \(summary.habitsImported) habits, and \(summary.tagsImported) tags.")
            }
        }
        .applyAppearance(appearanceManager)
    }

    // MARK: - Actions

    private func exportData() {
        isExporting = true

        // Simulate brief delay for UX
        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

            let result = importExportManager.exportData(format: selectedFormat)

            await MainActor.run {
                isExporting = false

                switch result {
                case .success(let url):
                    exportURL = url
                    showingExportShareSheet = true
                case .failure(let error):
                    self.error = error
                }
            }
        }
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            let result = importExportManager.importData(from: url)
            switch result {
            case .success(let summary):
                importSummary = summary
                showingImportSuccess = true
            case .failure(let error):
                self.error = error
            }

        case .failure(let error):
            self.error = .importFailed("Failed to select file: \(error.localizedDescription)")
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ImportExportView()
        .modelContainer(for: [Task.self, Habit.self], inMemory: true)
}
