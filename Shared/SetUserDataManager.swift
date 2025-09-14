//
//  SetUserDataManager.swift
//  BRIQ
//
//  Created by Éric Spérano on 7/25/25.
//

import SwiftUI
import CoreData

struct SetUserDataManager {
    let set: Set
    let context: NSManagedObjectContext
    
    var ownedBinding: Binding<Bool> {
        Binding(
            get: { set.userData?.owned ?? false },
            set: { newValue in
                ensureUserData()
                set.userData?.owned = newValue
                cleanupIfNeeded()
                do { try context.save() } catch { print("Save error: \(error)") }
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
                do { try context.save() } catch { print("Save error: \(error)") }
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
                do { try context.save() } catch { print("Save error: \(error)") }
            }
        )
    }
    
    var instructionsQualityBinding: Binding<Int> {
        Binding(
            get: { Int(set.userData?.instructionsQuality ?? 0) },
            set: { newValue in
                ensureUserData()
                set.userData?.instructionsQuality = Int32(newValue)
                cleanupIfNeeded()
                do { try context.save() } catch { print("Save error: \(error)") }
            }
        )
    }
    
    private func ensureUserData() {
        if set.userData == nil {
            let userData = SetUserData.create(in: context, number: set.number)
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
