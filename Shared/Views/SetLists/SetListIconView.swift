//
//  SetListIconView.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/31/25.
//

import CoreData
import SwiftUI

struct SetListIconView: View {
    var sets: [Set]
    @Binding var viewMode: SetListViewMode
    @Binding var selectedTheme: Theme?
    #if os(iOS)
    @Binding var showSettings: Bool
    #endif
    @AppStorage(IconSize.storageKey) private var iconSize = IconSize.defaultSize

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: iconSize), spacing: 16),
            ], spacing: 16) {
                ForEach(sets) { set in
                    SetDetailNavigationLink(set: set) {
                        SetIconView(set: set, size: iconSize)
                    }
                }
            }
            .padding()
        }
        .toolbar {
            ThemeDropdownToolbarItem(selectedTheme: $selectedTheme)
            #if !os(iOS)
            IconSizeSliderToolbarItem(iconSize: iconSizeBinding)
            #endif
            ViewModeMenuToolbarItem(viewMode: $viewMode)
            #if os(iOS)
            SettingsButtonToolbarItem(showSettings: $showSettings)
            #endif
        }
    }

    /// The slider works in `CGFloat`; `@AppStorage` stores a `Double`.
    private var iconSizeBinding: Binding<CGFloat> {
        Binding(get: { CGFloat(iconSize) }, set: { iconSize = Double($0) })
    }
}

#if DEBUG
#Preview {}
#endif
