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
                SetContentSection(set: set)
                Spacer()
            }
            .navigationTitle("\(set.number): \(set.name)")
        }
        .padding()
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
