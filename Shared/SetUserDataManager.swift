//
//  SetUserDataManager.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI
import SwiftData

struct SetUserDataManager {
    let set: Set
    let context: ModelContext
    
    var ownedBinding: Binding<Bool> {
        Binding(
            get: { set.userData?.owned ?? false },
            set: { newValue in
                ensureUserData()
                set.userData?.owned = newValue
                cleanupIfNeeded()
                try? context.save()
            }
        )
    }
    
    var favoriteBinding: Binding<Bool> {
        Binding(
            get: { set.userData?.favorite ?? false },
            set: { newValue in
                ensureUserData()
                set.userData?.favorite = newValue
                cleanupIfNeeded()
                try? context.save()
            }
        )
    }
    
    var ownsInstructionsBinding: Binding<Bool> {
        Binding(
            get: { set.userData?.ownsInstructions ?? false },
            set: { newValue in
                ensureUserData()
                set.userData?.ownsInstructions = newValue
                cleanupIfNeeded()
                try? context.save()
            }
        )
    }
    
    var instructionsQualityBinding: Binding<Int> {
        Binding(
            get: { set.userData?.instructionsQuality ?? 0 },
            set: { newValue in
                ensureUserData()
                set.userData?.instructionsQuality = newValue
                cleanupIfNeeded()
                try? context.save()
            }
        )
    }
    
    private func ensureUserData() {
        if set.userData == nil {
            let userData = SetUserData(number: set.number)
            context.insert(userData)
            set.userData = userData
        }
    }
    
    private func cleanupIfNeeded() {
        guard let userData = set.userData else { return }
        
        if !userData.owned && 
           !userData.favorite && 
           !userData.ownsInstructions && 
           userData.instructionsQuality == 0 {
            context.delete(userData)
            set.userData = nil
        }
    }
}
