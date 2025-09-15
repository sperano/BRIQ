//
//  EnvironmentKeys.swift
//  BRIQ
//
//  Created by Éric Spérano on 14/09/25.
//

import SwiftUI

struct RefreshSetListKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

struct SetDetailHasChangesKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}

struct SetDetailNavigationDepthKey: EnvironmentKey {
    static let defaultValue: Int = 0
}

extension EnvironmentValues {
    var refreshSetList: () -> Void {
        get { self[RefreshSetListKey.self] }
        set { self[RefreshSetListKey.self] = newValue }
    }

    var setDetailHasChanges: Binding<Bool>? {
        get { self[SetDetailHasChangesKey.self] }
        set { self[SetDetailHasChangesKey.self] = newValue }
    }

    var setDetailNavigationDepth: Int {
        get { self[SetDetailNavigationDepthKey.self] }
        set { self[SetDetailNavigationDepthKey.self] = newValue }
    }
}