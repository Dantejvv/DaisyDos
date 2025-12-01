//
//  AppearanceModifier.swift
//  DaisyDos
//
//  Created by Claude Code on 11/13/25.
//

import SwiftUI

/// View modifier that applies the current appearance settings (theme and accent color)
struct AppearanceModifier: ViewModifier {
    let appearanceManager: AppearanceManager

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(appearanceManager.currentColorScheme)
            .tint(appearanceManager.currentAccentColor)
    }
}

extension View {
    /// Applies the current appearance settings from AppearanceManager
    func applyAppearance(_ appearanceManager: AppearanceManager) -> some View {
        modifier(AppearanceModifier(appearanceManager: appearanceManager))
    }
}
