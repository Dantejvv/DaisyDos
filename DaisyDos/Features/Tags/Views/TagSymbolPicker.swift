//
//  TagSymbolPicker.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI

struct TagSymbolPicker: View {
    @Binding var selectedSymbol: String
    let availableSymbols: [String] = Tag.availableSymbols()

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(availableSymbols, id: \.self) { symbolName in
                SymbolOption(
                    symbolName: symbolName,
                    isSelected: selectedSymbol == symbolName
                ) {
                    selectedSymbol = symbolName
                }
            }
        }
        .padding()
    }
}

private struct SymbolOption: View {
    let symbolName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbolName)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.daisyTag : Color.daisySurface)
                )
                .foregroundColor(isSelected ? .white : .daisyText)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.accentColor, lineWidth: isSelected ? 2 : 0)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Symbol \(symbolName)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @State var selectedSymbol = "tag"

    return TagSymbolPicker(selectedSymbol: $selectedSymbol)
        .padding()
}