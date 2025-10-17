//
//  AttributedString+Persistence.swift
//  DaisyDos
//
//  Created by Claude Code on 10/15/25.
//

import Foundation
import SwiftUI

/// Extensions for persisting AttributedString to SwiftData
/// Provides encoding/decoding for rich text storage
extension AttributedString {

    // MARK: - Persistence

    /// Encode AttributedString to Data for storage
    func toData() -> Data? {
        do {
            let nsAttributedString = try NSAttributedString(self, including: \.uiKit)
            return try NSKeyedArchiver.archivedData(
                withRootObject: nsAttributedString,
                requiringSecureCoding: false
            )
        } catch {
            // Silent failure - return nil for encoding errors
            return nil
        }
    }

    /// Decode AttributedString from Data
    static func fromData(_ data: Data) -> AttributedString? {
        do {
            guard let nsAttributedString = try NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSAttributedString.self,
                from: data
            ) else {
                return nil
            }

            return try AttributedString(nsAttributedString, including: \.uiKit)
        } catch {
            // Silent failure - return nil for decoding errors
            return nil
        }
    }

    // MARK: - Conversion Helpers

    /// Convert plain String to AttributedString with default attributes
    static func fromPlainText(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)

        // Apply default font and color
        attributedString.font = .preferredFont(forTextStyle: .body)
        attributedString.foregroundColor = UIColor(Colors.Primary.text)

        return attributedString
    }

    /// Extract plain text from AttributedString
    var plainText: String {
        String(self.characters)
    }

    // MARK: - Validation

    /// Check if AttributedString contains only plain text (no formatting)
    var isPlainText: Bool {
        for run in runs {
            // Check for any formatting attributes
            if run.attributes.inlinePresentationIntent != nil ||
               run.attributes.underlineStyle != nil ||
               run.attributes.strikethroughStyle != nil ||
               run.attributes.foregroundColor != nil ||
               run.attributes.backgroundColor != nil {
                return false
            }
        }
        return true
    }

    /// Character count (for validation against limits)
    var characterCount: Int {
        self.characters.count
    }
}

// MARK: - SwiftData Migration Helpers

extension AttributedString {

    /// Migrate existing plain text String to AttributedString with Data storage
    /// Used during model migration from String to Data-backed AttributedString
    static func migrate(from plainText: String) -> Data? {
        let attributedString = AttributedString.fromPlainText(plainText)
        return attributedString.toData()
    }

    /// Safely extract text for legacy compatibility
    /// Returns plain text string for backwards compatibility or display
    static func extractText(from data: Data?) -> String {
        guard let data = data else { return "" }
        return AttributedString.fromData(data)?.plainText ?? ""
    }
}

// MARK: - Debugging Helpers

#if DEBUG
extension AttributedString {

    /// Debug description showing runs and attributes
    var debugDescription: String {
        var description = "AttributedString (\(characterCount) characters):\n"

        for run in runs {
            let text = String(self[run.range].characters)
            description += "  - \"\(text)\"\n"

            if let intent = run.attributes.inlinePresentationIntent {
                description += "    Intent: \(intent)\n"
            }
            if let underline = run.attributes.underlineStyle {
                description += "    Underline: \(underline)\n"
            }
        }

        return description
    }
}
#endif
