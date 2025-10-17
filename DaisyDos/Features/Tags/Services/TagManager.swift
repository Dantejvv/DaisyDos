//
//  TagManager.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class TagManager {
    private let modelContext: ModelContext

    // Error handling
    var lastError: (any RecoverableError)?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Computed Properties for Filtered Data

    var allTags: [Tag] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    var usedTags: [Tag] {
        allTags.filter { $0.isInUse }
    }

    var unusedTags: [Tag] {
        allTags.filter { !$0.isInUse }
    }

    var tagsByUsage: [Tag] {
        let descriptor = FetchDescriptor<Tag>(sortBy: [SortDescriptor(\.createdDate, order: .reverse)])
        let tags = (try? modelContext.fetch(descriptor)) ?? []
        return tags.sorted { $0.totalItemCount > $1.totalItemCount }
    }

    var canCreateNewTag: Bool {
        Tag.canCreateNewTag(in: modelContext)
    }

    // MARK: - CRUD Operations

    func createTag(name: String, sfSymbolName: String = "tag", colorName: String = "blue", tagDescription: String = "") -> Tag? {
        // Check if we can create a new tag (system limit)
        guard canCreateNewTag else {
            lastError = DaisyDosError.tagLimitExceeded
            return nil
        }

        // Check if tag name already exists
        let existingTagDescriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.name == name
            }
        )

        if let existingTags = try? modelContext.fetch(existingTagDescriptor),
           !existingTags.isEmpty {
            lastError = DaisyDosError.duplicateEntity("tag")
            return nil
        }

        let tag = Tag(name: name, sfSymbolName: sfSymbolName, colorName: colorName, tagDescription: tagDescription)
        modelContext.insert(tag)

        do {
            try modelContext.save()
            return tag
        } catch {
            lastError = ErrorTransformer.transformTagError(error, operation: "create tag")
            return nil
        }
    }

    func updateTag(_ tag: Tag, name: String? = nil, sfSymbolName: String? = nil, colorName: String? = nil, tagDescription: String? = nil) -> Bool {
        // If updating name, check for duplicates
        if let newName = name, newName != tag.name {
            // Check for duplicates manually for now
            let existingTags = allTags.filter { $0.name == newName && $0.id != tag.id }

            if !existingTags.isEmpty {
                lastError = DaisyDosError.duplicateEntity("tag")
                return false
            }
            tag.name = newName
        }

        if let sfSymbolName = sfSymbolName {
            tag.sfSymbolName = sfSymbolName
        }

        if let colorName = colorName {
            tag.colorName = colorName
        }

        if let tagDescription = tagDescription {
            tag.tagDescription = tagDescription
        }

        do {
            try modelContext.save()
            return true
        } catch {
            lastError = ErrorTransformer.transformTagError(error, operation: "update tag")
            return false
        }
    }

    func deleteTag(_ tag: Tag) -> Bool {
        // Check if tag is in use
        if tag.isInUse {
            lastError = DaisyDosError.validationFailed("Cannot delete tag in use")
            return false
        }

        modelContext.delete(tag)

        do {
            try modelContext.save()
            return true
        } catch {
            lastError = ErrorTransformer.transformTagError(error, operation: "delete tag")
            return false
        }
    }

    func forceDeleteTag(_ tag: Tag) {
        // Force delete tag even if in use (removes from all tasks/habits)
        modelContext.delete(tag)

        do {
            try modelContext.save()
        } catch {
            lastError = ErrorTransformer.transformTagError(error, operation: "force delete tag")
        }
    }

    func deleteTags(_ tags: [Tag]) -> [Tag] {
        var deletedTags: [Tag] = []

        for tag in tags {
            if !tag.isInUse {
                modelContext.delete(tag)
                deletedTags.append(tag)
            }
        }

        do {
            try modelContext.save()
        } catch {
            lastError = ErrorTransformer.transformTagError(error, operation: "delete tags")
        }

        return deletedTags
    }

    // MARK: - Search and Filtering

    func searchTags(query: String) -> [Tag] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return allTags
        }

        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.name.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func tagsWithColor(_ colorName: String) -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.colorName == colorName
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func tagsWithSymbol(_ symbolName: String) -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.sfSymbolName == symbolName
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Usage Analytics

    var tagCount: Int {
        allTags.count
    }

    var usedTagCount: Int {
        usedTags.count
    }

    var unusedTagCount: Int {
        unusedTags.count
    }

    var averageTagUsage: Double {
        let tags = allTags
        guard !tags.isEmpty else { return 0.0 }
        let totalUsage = tags.reduce(0) { $0 + $1.totalItemCount }
        return Double(totalUsage) / Double(tags.count)
    }

    var mostUsedTag: Tag? {
        allTags.max { $0.totalItemCount < $1.totalItemCount }
    }

    var leastUsedTag: Tag? {
        usedTags.min { $0.totalItemCount < $1.totalItemCount }
    }

    // MARK: - Tag Creation Helpers

    static var availableColors: [String] {
        Tag.availableColors()
    }

    static var availableSymbols: [String] {
        Tag.availableSymbols()
    }

    func suggestTagColor() -> String {
        let usedColors = allTags.map(\.colorName)
        let availableColors = Self.availableColors

        // Find least used color
        let colorCounts = availableColors.map { color in
            (color, usedColors.filter { $0 == color }.count)
        }

        let leastUsedColor = colorCounts.min { $0.1 < $1.1 }?.0 ?? "blue"
        return leastUsedColor
    }

    func suggestTagSymbol() -> String {
        let usedSymbols = allTags.map(\.sfSymbolName)
        let availableSymbols = Self.availableSymbols

        // Find least used symbol
        let symbolCounts = availableSymbols.map { symbol in
            (symbol, usedSymbols.filter { $0 == symbol }.count)
        }

        let leastUsedSymbol = symbolCounts.min { $0.1 < $1.1 }?.0 ?? "tag"
        return leastUsedSymbol
    }

    // MARK: - Validation Helpers

    func validateTagName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if name is not empty
        guard !trimmedName.isEmpty else { return false }

        // Check if name doesn't already exist
        let existingTagDescriptor = FetchDescriptor<Tag>(
            predicate: #Predicate<Tag> { tag in
                tag.name == trimmedName
            }
        )

        let existingTags = (try? modelContext.fetch(existingTagDescriptor)) ?? []
        return existingTags.isEmpty
    }

    var remainingTagSlots: Int {
        max(0, 30 - tagCount)
    }
}