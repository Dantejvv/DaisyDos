//
//  TagsSectionView.swift
//  DaisyDos
//
//  Created by Claude Code on 1/2/25.
//  Shared component for displaying tags in row views
//

import SwiftUI

/// Reusable horizontal scrollable tags section for row views
struct TagsSectionView: View {
    let tags: [Tag]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(tags, id: \.id) { tag in
                    IconOnlyTagChipView(tag: tag)
                }
            }
            .padding(.horizontal, 4)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tags: " + tags.map(\.name).joined(separator: ", "))
    }
}
