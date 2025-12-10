//
//  TagEditView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI
import SwiftData

struct TagEditView: View {
    @Environment(TagManager.self) private var tagManager
    @Environment(\.dismiss) private var dismiss

    let tag: Tag

    @State private var tagName: String = ""
    @State private var tagDescriptionAttributed: AttributedString = AttributedString()
    @State private var selectedColor: String = ""
    @State private var selectedSymbol: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingDeleteConfirmation = false

    var isFormValid: Bool {
        !tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        tagName.count <= DesignSystem.inputValidation.CharacterLimits.tagName
    }

    var tagNameCharacterCount: Int {
        tagName.count
    }

    private var tagNameCountColor: Color {
        return DesignSystem.inputValidation.characterCountColorExact(
            currentCount: tagNameCharacterCount,
            maxLength: DesignSystem.inputValidation.CharacterLimits.tagName
        )
    }

    var hasChanges: Bool {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName != tag.name ||
               tagDescriptionAttributed != tag.tagDescriptionAttributed ||
               selectedColor != tag.colorName ||
               selectedSymbol != tag.sfSymbolName
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tag Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Name")
                            Spacer()
                            TextField("Tag name", text: $tagName)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled(true)
                                .onChange(of: tagName) { _, newValue in
                                    DesignSystem.inputValidation.enforceCharacterLimit(
                                        &tagName,
                                        newValue: newValue,
                                        maxLength: DesignSystem.inputValidation.CharacterLimits.tagName
                                    )
                                }
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Tag name field")

                        HStack {
                            Spacer()
                            Text("\(tagNameCharacterCount)/\(DesignSystem.inputValidation.CharacterLimits.tagName)")
                                .font(.caption2)
                                .foregroundColor(tagNameCountColor)
                        }
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Description (optional)")
                            .font(.subheadline)
                            .foregroundColor(.daisyTextSecondary)
                            .padding(.bottom, Spacing.extraSmall)

                        RichTextEditor(
                            attributedText: $tagDescriptionAttributed,
                            placeholder: "Add tag description with formatting...",
                            maxLength: Int.max
                        )
                    }
                }

                Section("Preview") {
                    HStack {
                        Spacer()
                        TagPreview(
                            name: tagName.isEmpty ? "Preview" : tagName,
                            symbolName: selectedSymbol,
                            colorName: selectedColor
                        )
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                Section("Color") {
                    TagColorPicker(selectedColor: $selectedColor)
                }

                Section("Symbol") {
                    TagSymbolPicker(selectedSymbol: $selectedSymbol)
                }

                Section("Usage") {
                    HStack {
                        Text("Items using this tag")
                        Spacer()
                        Text("\(tag.totalItemCount)")
                            .foregroundColor(.daisyTextSecondary)
                    }

                    if tag.isInUse {
                        Text("This tag is used by \(tag.tasks?.count ?? 0) tasks and \(tag.habits?.count ?? 0) habits")
                            .font(.caption)
                            .foregroundColor(.daisyTextSecondary)
                    }
                }

                Section {
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Tag")
                        }
                        .foregroundColor(.daisyError)
                    }
                }
            }
            .navigationTitle("Edit Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!isFormValid || !hasChanges)
                }
            }
            .alert("Error Updating Tag", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog(
                "Delete Tag",
                isPresented: $showingDeleteConfirmation
            ) {
                if tag.isInUse {
                    Button("Remove from \(tag.totalItemCount) items and delete", role: .destructive) {
                        deleteTag(force: true)
                    }
                    Button("Cancel", role: .cancel) { }
                } else {
                    Button("Delete", role: .destructive) {
                        deleteTag(force: false)
                    }
                    Button("Cancel", role: .cancel) { }
                }
            } message: {
                if tag.isInUse {
                    Text("This tag is used by \(tag.tasks?.count ?? 0) tasks and \(tag.habits?.count ?? 0) habits. Deleting it will remove it from all items.")
                } else {
                    Text("This will permanently delete the '\(tag.name)' tag.")
                }
            }
            .onAppear {
                tagName = tag.name
                tagDescriptionAttributed = tag.tagDescriptionAttributed
                selectedColor = tag.colorName
                selectedSymbol = tag.sfSymbolName
            }
        }
    }

    private func saveChanges() {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            showError("Tag name cannot be empty")
            return
        }

        // Check for duplicate names only if the name changed
        if trimmedName != tag.name && !tagManager.validateTagName(trimmedName) {
            showError("A tag with this name already exists")
            return
        }

        // Update tag properties directly
        if trimmedName != tag.name {
            tag.name = trimmedName
        }
        if selectedSymbol != tag.sfSymbolName {
            tag.sfSymbolName = selectedSymbol
        }
        if selectedColor != tag.colorName {
            tag.colorName = selectedColor
        }
        if tagDescriptionAttributed != tag.tagDescriptionAttributed {
            tag.tagDescriptionAttributed = tagDescriptionAttributed
        }

        dismiss()
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }

    private func deleteTag(force: Bool) {
        let success = force ? {
            tagManager.forceDeleteTag(tag)
            return true
        }() : tagManager.deleteTag(tag)

        if success {
            dismiss()
        } else {
            showError("Failed to delete tag. The tag may be in use by other items.")
        }
    }
}

private struct TagPreview: View {
    let name: String
    let symbolName: String
    let colorName: String

    private var color: Color {
        switch colorName.lowercased() {
        case "red": return Color(.systemRed)
        case "orange": return Color(.systemOrange)
        case "yellow": return Color(.systemYellow)
        case "green": return Color(.systemGreen)
        case "blue": return Color(.systemBlue)
        case "purple": return Color(.systemPurple)
        case "pink": return Color(.systemPink)
        case "brown": return Color(.systemBrown)
        case "gray": return Color(.systemGray)
        default: return Color(.systemBlue)
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .font(.title2)
                .foregroundColor(color)

            Text(name)
                .font(.headline)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.daisySurface, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let container = try! ModelContainer(for: Tag.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let tag = Tag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")

    TagEditView(tag: tag)
        .modelContainer(container)
        .environment(TagManager(modelContext: container.mainContext))
}