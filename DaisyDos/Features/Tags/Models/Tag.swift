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
class Tag {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var name: String
    var sfSymbolName: String
    var colorName: String
    var createdDate: Date

    @Relationship(deleteRule: .nullify)
    var tasks: [Task] = []

    @Relationship(deleteRule: .nullify)
    var habits: [Habit] = []

    init(name: String, sfSymbolName: String = "tag", colorName: String = "blue") {
        self.id = UUID()
        self.name = name
        self.sfSymbolName = sfSymbolName
        self.colorName = colorName
        self.createdDate = Date()
    }

    var color: Color {
        switch colorName.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "brown": return .brown
        case "gray": return .gray
        default: return .blue
        }
    }

    var totalItemCount: Int {
        tasks.count + habits.count
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