//
//  SetDetail.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI
import CoreData

struct SetDetail: View {
    @ObservedObject var set: Set
    var selectedSet: Binding<Set?>? = nil
    @AppStorage("partsMinifigsViewMode") private var viewModeRaw: String = "icon"

    private var viewMode: ViewMode {
        ViewMode(rawValue: viewModeRaw) ?? .list
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                #if os(iOS)
                SetImageDisplay(set: set)
                SetDetailFields(set: set, selectedSet: selectedSet)
                #elseif os(macOS)
                HStack(alignment: .top) {
                    SetImageDisplay(set: set)
                    SetDetailFields(set: set, selectedSet: selectedSet)
                        .padding(.leading, 10)
                }
                #endif
                SetContentSection(set: set, viewMode: viewMode)
                Spacer()
            }
            .navigationTitle("\(set.number): \(set.name)")
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModeRaw = viewMode == .list ? ViewMode.icon.rawValue : ViewMode.list.rawValue
                } label: {
                    Image(systemName: viewMode == .list ? "square.grid.2x2" : "list.bullet")
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        SetDetail(set: Set.sampleData[0])
    }
    .environment(\.managedObjectContext, NSManagedObjectContext.preview)
}
#endif
