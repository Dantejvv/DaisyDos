//
//  Tag.swift
//  DaisyDos
//
//  Created by Dante Vercelli on 9/23/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
class Tag: Identifiable {
    // CloudKit-compatible: all have defaults, no unique constraints, optional relationships
    var id: UUID = UUID()  // CloudKit doesn't support @Attribute(.unique)
    var name: String = ""  // CloudKit doesn't support #Unique - manual validation in TagManager required
    var sfSymbolName: String = "tag"
    var colorName: String = "blue"

    // Rich text description storage (Data-backed AttributedString)
    @Attribute(.externalStorage) var tagDescriptionData: Data?

    var createdDate: Date = Date()
    var lastModifiedDate: Date = Date()  // For CloudKit conflict resolution

    @Relationship(deleteRule: .nullify)
    var tasks: [Task]?

    @Relationship(deleteRule: .nullify)
    var habits: [Habit]?

    init(name: String, sfSymbolName: String = "tag", colorName: String = "blue", tagDescription: String = "") {
        self.id = UUID()
        self.name = name
        self.sfSymbolName = sfSymbolName
        self.colorName = colorName
        self.tagDescriptionData = tagDescription.isEmpty ? nil : AttributedString.migrate(from: tagDescription)
        let now = Date()
        self.createdDate = now
        self.lastModifiedDate = now
    }

    // Backward compatibility: Computed property for plain text access
    var tagDescription: String {
        get {
            guard let data = tagDescriptionData else { return "" }
            return AttributedString.extractText(from: data)
        }
        set {
            // Convert plain text to AttributedString and store as Data
            tagDescriptionData = newValue.isEmpty ? nil : AttributedString.migrate(from: newValue)
        }
    }

    // Rich text accessor for UI components
    var tagDescriptionAttributed: AttributedString {
        get {
            guard let data = tagDescriptionData else {
                return AttributedString.fromPlainText("")
            }
            return AttributedString.fromData(data) ?? AttributedString.fromPlainText("")
        }
        set {
            tagDescriptionData = newValue.characters.isEmpty ? nil : newValue.toData()
        }
    }

    // Convenience property for non-optional access
    var descriptionText: String {
        tagDescription
    }

    var color: Color {
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

    var totalItemCount: Int {
        (tasks?.count ?? 0) + (habits?.count ?? 0)
    }

    var isInUse: Bool {
        totalItemCount > 0
    }

    static func validateSystemTagLimit(in context: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<Tag>()
        let tagCount = (try? context.fetch(descriptor).count) ?? 0
        return tagCount < 30
    }

    static func canCreateNewTag(in context: ModelContext) -> Bool {
        return validateSystemTagLimit(in: context)
    }

    static func availableColors() -> [String] {
        return ["red", "orange", "yellow", "green", "blue", "purple", "pink", "brown", "gray"]
    }

    static func availableSymbols() -> [String] {
        return [
            "tag", "star", "heart", "bookmark", "flag", "pin", "paperclip",
            "folder", "house", "car", "airplane", "phone", "envelope", "calendar",
            "clock", "bell", "camera", "music.note", "gamecontroller", "book",
            "pencil", "paintbrush", "hammer", "wrench", "gear", "lightbulb",
            "leaf", "flame", "drop", "snowflake", "sun.max", "moon", "cloud"
        ]
    }
}