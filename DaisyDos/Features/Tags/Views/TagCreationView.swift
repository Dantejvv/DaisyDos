//
//  TagCreationView.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI
import SwiftData

struct TagCreationView: View {
    @Environment(TagManager.self) private var tagManager
    @Environment(\.dismiss) private var dismiss

    @State private var tagName = ""
    @State private var tagDescriptionAttributed: AttributedString = AttributedString()
    @State private var selectedColor: String = "blue"
    @State private var selectedSymbol: String = "tag"
    @State private var showingError = false
    @State private var errorMessage = ""

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

    var remainingSlots: Int {
        tagManager.remainingTagSlots
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

                Section {
                    Text("\(remainingSlots) of 30 tag slots available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("New Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTag()
                    }
                    .disabled(!isFormValid || remainingSlots <= 0)
                }
            }
            .alert("Error Creating Tag", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                selectedColor = tagManager.suggestTagColor()
                selectedSymbol = tagManager.suggestTagSymbol()
            }
        }
    }

    private func createTag() {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            showError("Tag name cannot be empty")
            return
        }

        guard tagManager.validateTagName(trimmedName) else {
            showError("A tag with this name already exists")
            return
        }

        guard tagManager.canCreateNewTag else {
            showError("Cannot create tag: Maximum limit of 30 tags reached")
            return
        }

        // Create tag with plain text description first
        if let newTag = tagManager.createTag(
            name: trimmedName,
            sfSymbolName: selectedSymbol,
            colorName: selectedColor,
            tagDescription: ""
        ) {
            // Update with AttributedString description if present
            if !tagDescriptionAttributed.characters.isEmpty {
                newTag.tagDescriptionAttributed = tagDescriptionAttributed
            }
            dismiss()
        } else {
            showError("Failed to create tag. Please try again.")
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
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
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    let container = try! ModelContainer(for: Tag.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

    TagCreationView()
        .modelContainer(container)
        .environment(TagManager(modelContext: container.mainContext))
}