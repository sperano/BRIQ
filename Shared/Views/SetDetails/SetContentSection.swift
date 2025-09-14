//
//  SetContentSection.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI

enum ViewMode: String, CaseIterable {
    case list
    case icon
}

struct SetContentSection: View {
    let set: Set
    @AppStorage("partsMinifigsViewMode") private var viewModeRaw: String = "list"
    
    private var viewMode: ViewMode {
        get { ViewMode(rawValue: viewModeRaw) ?? .list }
        set { viewModeRaw = newValue.rawValue }
    }
    
    private var totalMinifigs: Int {
        return set.minifigsCount
    }

    private var totalParts: Int {
        return set.actualPartsCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                Button {
                    viewModeRaw = viewMode == .list ? ViewMode.icon.rawValue : ViewMode.list.rawValue
                } label: {
                    Image(systemName: viewMode == .list ? "square.grid.2x2" : "list.bullet")
                        .foregroundColor(.blue)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            Text("\(totalMinifigs) mini-figurines:")
                .font(.title2)
                .fontWeight(.bold)
            MinifigList(minifigs: (set.minifigs?.allObjects as? [SetMinifig]) ?? [], viewMode: viewMode)
            Text("\(totalParts) parts:")
                .font(.title2)
                .fontWeight(.bold)
            PartsList(parts: (set.parts?.allObjects as? [SetPart]) ?? [], viewMode: viewMode)
        }
    }
}
