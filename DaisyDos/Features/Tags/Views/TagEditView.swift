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
    @State private var selectedColor: String = ""
    @State private var selectedSymbol: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    var isFormValid: Bool {
        !tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasChanges: Bool {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName != tag.name ||
               selectedColor != tag.colorName ||
               selectedSymbol != tag.sfSymbolName
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tag Details") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Tag name", text: $tagName)
                            .multilineTextAlignment(.trailing)
                            .textFieldStyle(.plain)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Tag name field")
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
                            .foregroundColor(.secondary)
                    }

                    if tag.isInUse {
                        Text("This tag is currently in use and cannot be deleted")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
            .onAppear {
                tagName = tag.name
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

        let success = tagManager.updateTag(
            tag,
            name: trimmedName != tag.name ? trimmedName : nil,
            sfSymbolName: selectedSymbol != tag.sfSymbolName ? selectedSymbol : nil,
            colorName: selectedColor != tag.colorName ? selectedColor : nil
        )

        if success {
            dismiss()
        } else {
            showError("Failed to update tag. Please try again.")
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
    let tag = Tag(name: "Work", sfSymbolName: "briefcase", colorName: "blue")

    TagEditView(tag: tag)
        .modelContainer(container)
        .environment(TagManager(modelContext: container.mainContext))
}