//
//  SetListIconView.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/31/25.
//

import SwiftUI
import CoreData

struct SetListIconView: View {
    var sets: [Set]
    @Binding var viewMode: SetListViewMode
    @Binding var selectedTheme: Theme?
    #if os(iOS)
    @Binding var showSettings: Bool
    #endif
    @State private var iconSize: CGFloat = 120
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: iconSize), spacing: 16)
            ], spacing: 16) {
                ForEach(sets) { set in
                    NavigationLink {
                        SetDetail(set: set)
                        //                            .onDisappear {
                        //                                loadSets() TODO
                        //                            }
                    } label: {
                        SetIconView(set: set, size: iconSize)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .toolbar {
            ThemeDropdownToolbarItem(selectedTheme: $selectedTheme)
            #if !os(iOS)
            IconSizeSliderToolbarItem(iconSize: $iconSize)
            #endif
            ViewModeMenuToolbarItem(viewMode: $viewMode)
            #if os(iOS)
            SettingsButtonToolbarItem(showSettings: $showSettings)
            #endif
        }
    }
}

#if DEBUG
#Preview {
}
#endif
