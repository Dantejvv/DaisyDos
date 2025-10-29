//
//  Set+Selection.swift
//  DaisyDos
//
//  Created by Claude Code on 10/28/25.
//  Utility extensions for Set selection operations
//

import Foundation

extension Set where Element: Hashable {
    /// Toggles membership of an element in the set
    /// - Parameter element: The element to toggle
    mutating func toggleMembership(_ element: Element) {
        if contains(element) {
            remove(element)
        } else {
            insert(element)
        }
    }
}
