//
//  MinifigsList.swift
//  BRIQ
//
//  Created by Éric Spérano on 8/9/25.
//

import SwiftUI

struct MinifigList: View {
    let minifigs: [SetMinifig]
    let viewMode: ViewMode
    
    var body: some View {
        Group {
            if viewMode == .list {
                MinifigsListView(minifigs: minifigs)
            } else {
                MinifigsIconView(minifigs: minifigs)
            }
        }
    }
}

#if DEBUG
//#Preview {
//    MinifigList(minifigs: SetMinifig.sampleData, viewMode: .list)
//        .modelContainer(SampleData.shared.modelContainer)
//}
#endif
