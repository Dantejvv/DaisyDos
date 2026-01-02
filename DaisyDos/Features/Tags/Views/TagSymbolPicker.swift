//
//  TagSymbolPicker.swift
//  DaisyDos
//
//  Created by Claude Code on 9/26/25.
//

import SwiftUI

struct TagSymbolPicker: View {
    @Binding var selectedSymbol: String
    @State private var selectedCategory: Tag.SymbolCategory = .work

    private var filteredSymbols: [String] {
        Tag.availableSymbols(for: selectedCategory)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Category Picker
            Picker("Category", selection: $selectedCategory) {
                ForEach(Tag.SymbolCategory.allCases) { category in
                    Label(category.rawValue, systemImage: category.icon)
                        .tag(category)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Symbol Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(filteredSymbols, id: \.self) { symbolName in
                    SymbolOption(
                        symbolName: symbolName,
                        isSelected: selectedSymbol == symbolName
                    ) {
                        selectedSymbol = symbolName
                    }
                }
            }
            .padding(.horizontal)
            .animation(.easeInOut(duration: 0.2), value: selectedCategory)
        }
        .padding(.vertical)
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
    @Previewable @State var selectedSymbol = "tag"

    TagSymbolPicker(selectedSymbol: $selectedSymbol)
        .padding()
}