//
//  SearchEmptyStateView.swift
//  DaisyDos
//
//  Created by Claude Code on 10/27/25.
//  Shared component for "no search results" empty state
//

import SwiftUI

struct SearchEmptyStateView: View {
    let searchText: String

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary)

                Text("No results for '\(searchText)'")
                    .font(.title2.bold())

                Text("Try adjusting your search terms")
                    .foregroundColor(.secondary)
            }
            .padding()
            Spacer()
        }
    }
}

#Preview {
    SearchEmptyStateView(searchText: "test query")
}
