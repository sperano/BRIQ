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
    @Binding var showFilter: Bool
    @Binding var selectedTheme: Theme?
    
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
            ToolbarItemGroup(placement: .primaryAction) {
                ThemeDropdown(selectedTheme: $selectedTheme)
                
                HStack(spacing: 4) {
                    Image(systemName: "minus.magnifyingglass")
                        .foregroundStyle(Color.secondary)
                        .font(.caption)
                    
                    Slider(value: $iconSize, in: 80...400, step: 20)
                        .frame(width: 80)
                    
                    Image(systemName: "plus.magnifyingglass")
                        .foregroundStyle(Color.secondary)
                        .font(.caption)
                }
                
                Menu {
                    ForEach(SetListViewMode.allCases, id: \.self) { mode in
                        Button(action: {
                            viewMode = mode
                        }) {
                            Label(mode.displayName, systemImage: mode.systemImage)
                        }
                    }
                } label: {
                    Image(systemName: viewMode.systemImage)
                }
                
#if os(iOS)
                Button(action: {
                    showFilter.toggle()
                }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
#endif
            }
        }
        
    }
}

#if DEBUG
//#Preview {
//    NavigationStack {
//        SetList()
//            .modelContainer(SampleData.shared.modelContainer)
//    }
//}
#endif
