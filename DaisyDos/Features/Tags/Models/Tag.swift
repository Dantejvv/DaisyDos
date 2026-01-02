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
        case "teal": return Color(.systemTeal)
        case "indigo": return Color(.systemIndigo)
        case "cyan": return Color(.systemCyan)
        case "mint": return Color(.systemMint)
        case "lightgray": return Color(.systemGray3)
        case "black": return Color.black
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
        return ["red", "orange", "yellow", "green", "blue", "purple", "pink", "brown", "gray", "teal", "indigo", "cyan", "mint", "lightGray", "black"]
    }

    enum SymbolCategory: String, CaseIterable, Identifiable {
        case work = "Work"
        case life = "Life"
        case nature = "Nature"
        case creative = "Creative"
        case tools = "Tools"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .work: return "briefcase"
            case .life: return "house"
            case .nature: return "leaf"
            case .creative: return "paintbrush"
            case .tools: return "hammer"
            }
        }

        var symbols: [String] {
            switch self {
            case .work:
                return [
                    "folder", "paperclip", "envelope", "calendar", "clock", "bell",
                    "book", "pencil", "gear", "tag", "briefcase", "doc.text",
                    "checkmark.circle", "building.2", "chart.bar", "tray",
                    "paperplane", "at", "printer", "network", "server.rack",
                    "clipboard", "square.and.pencil", "doc.on.clipboard", "archivebox",
                    "magazine", "newspaper", "books.vertical", "studentdesk",
                    "list.clipboard", "note.text", "text.alignleft", "rectangle.and.pencil.and.ellipsis"
                ]
            case .life:
                return [
                    "house", "car", "airplane", "phone", "heart", "star",
                    "flag", "bookmark", "gift", "cart", "balloon", "figure.walk",
                    "person.2", "cup.and.saucer", "fork.knife", "bed.double",
                    "creditcard", "bag", "handbag", "stroller", "bicycle",
                    "scooter", "skateboard", "tennisball", "football", "basketball",
                    "dumbbell", "figure.run", "figure.yoga", "soccerball", "baseball",
                    "party.popper", "wineglass", "mug", "takeoutbag.and.cup.and.straw"
                ]
            case .nature:
                return [
                    "leaf", "flame", "drop", "snowflake", "sun.max", "moon",
                    "cloud", "tree", "pawprint", "mountain.2", "wind",
                    "bolt", "sparkles", "globe",
                    "cloud.rain", "cloud.snow", "cloud.sun", "cloud.moon", "tornado",
                    "rainbow", "sunset", "moonphase.full.moon", "moon.stars",
                    "ladybug", "ant", "hare", "tortoise",
                    "bird", "fish", "cat", "dog", "lizard"
                ]
            case .creative:
                return [
                    "paintbrush", "camera", "music.note", "gamecontroller", "lightbulb",
                    "film", "photo", "mic", "theatermasks", "guitars", "headphones",
                    "tv", "movieclapper",
                    "paintpalette", "photo.on.rectangle", "photo.stack", "rectangle.stack",
                    "video", "playpause", "play.circle", "pianokeys",
                    "metronome", "music.mic", "hifispeaker", "radio",
                    "speaker.wave.2", "books.vertical", "book.closed", "eyeglasses"
                ]
            case .tools:
                return [
                    "hammer", "wrench", "pin", "scissors", "ruler",
                    "magnifyingglass", "key", "lock", "shield", "bandage",
                    "battery.100",
                    "screwdriver", "wrench.and.screwdriver", "level", "latch.2.case",
                    "shippingbox", "cube", "point.3.filled.connected.trianglepath.dotted",
                    "gearshape.2", "checklist", "slider.horizontal.3", "location",
                    "mappin", "map", "binoculars"
                ]
            }
        }
    }

    static func availableSymbols(for category: SymbolCategory? = nil) -> [String] {
        if let category = category {
            return category.symbols
        }
        // Return all symbols when no category specified
        return SymbolCategory.allCases.flatMap { $0.symbols }
    }

    static func availableSymbols() -> [String] {
        return availableSymbols(for: nil)
    }
}