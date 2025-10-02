//
//  SetDetailNavigationLink.swift
//  BRIQ
//
//  Created by Éric Spérano on 14/09/25.
//

import SwiftUI

struct SetDetailNavigationLink<Label: View>: View {
    let set: Set
    let selectedSet: Binding<Set?>?
    @Environment(\.refreshSetList) private var refreshSetList
    @Environment(\.setDetailNavigationDepth) private var currentDepth
    @ViewBuilder let label: () -> Label

    init(
        set: Set,
        selectedSet: Binding<Set?>? = nil,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.set = set
        self.selectedSet = selectedSet
        self.label = label
    }

    var body: some View {
        NavigationLink {
            SetDetail(
                set: set,
                selectedSet: selectedSet,
                onDisappear: currentDepth == 0 ? refreshSetList : nil
            )
            .environment(\.setDetailNavigationDepth, currentDepth + 1)
        } label: {
            label()
        }
        .buttonStyle(.plain)
    }
}