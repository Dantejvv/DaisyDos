//
//  View+NavigationCleanup.swift
//  DaisyDos
//
//  Created by Claude Code on 10/28/25.
//  Reusable navigation cleanup for tab-based views
//

import SwiftUI

extension View {
    /// Manages search state when navigating between tabs (without multi-select)
    /// - Parameters:
    ///   - navigationManager: The navigation manager observing tab changes
    ///   - currentTab: The tab this view belongs to
    ///   - searchText: Binding to the search text
    ///   - isSearchPresented: Binding to search presentation state
    /// - Returns: View with navigation cleanup applied
    func navigationTabCleanup(
        navigationManager: NavigationManager,
        currentTab: TabType,
        searchText: Binding<String>,
        isSearchPresented: Binding<Bool>
    ) -> some View {
        self.onChange(of: navigationManager.selectedTab) { oldTab, newTab in
            // Dismiss search when navigating back to this tab
            if oldTab != currentTab && newTab == currentTab {
                isSearchPresented.wrappedValue = false
            }

            // Dismiss search and clear text when switching away from this tab
            if oldTab == currentTab && newTab != currentTab {
                isSearchPresented.wrappedValue = false
                searchText.wrappedValue = ""
            }
        }
    }

    /// Manages search and multi-select state when navigating between tabs
    /// - Parameters:
    ///   - navigationManager: The navigation manager observing tab changes
    ///   - currentTab: The tab this view belongs to
    ///   - searchText: Binding to the search text
    ///   - isSearchPresented: Binding to search presentation state
    ///   - isMultiSelectMode: Binding to multi-select mode
    ///   - selectedItems: Binding to selected items set
    /// - Returns: View with navigation cleanup applied
    func navigationTabCleanup<T: Hashable>(
        navigationManager: NavigationManager,
        currentTab: TabType,
        searchText: Binding<String>,
        isSearchPresented: Binding<Bool>,
        isMultiSelectMode: Binding<Bool>,
        selectedItems: Binding<Set<T>>
    ) -> some View {
        self.onChange(of: navigationManager.selectedTab) { oldTab, newTab in
            // Dismiss search when navigating back to this tab
            if oldTab != currentTab && newTab == currentTab {
                isSearchPresented.wrappedValue = false
            }

            // Dismiss search and clear text when switching away from this tab
            if oldTab == currentTab && newTab != currentTab {
                isSearchPresented.wrappedValue = false
                searchText.wrappedValue = ""
            }

            // Deactivate multi-select mode when switching away
            if oldTab == currentTab && newTab != currentTab && isMultiSelectMode.wrappedValue {
                isMultiSelectMode.wrappedValue = false
                selectedItems.wrappedValue.removeAll()
            }
        }
    }
}
