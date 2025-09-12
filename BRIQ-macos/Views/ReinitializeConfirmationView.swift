//
//  ReinitializeConfirmationView.swift
//  SharedBRIQ
//
//  Created by Éric Spérano on 9/10/25.
//

import SwiftUI

public struct ReinitializeConfirmationView: View {
    @Binding var preserveUserData: Bool
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    public init(preserveUserData: Binding<Bool>, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void = {}) {
        self._preserveUserData = preserveUserData
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Re-Initialize Database")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("This will delete all data and reload from the bundled database.")
                
                Toggle("Re-import collections and favorites", isOn: $preserveUserData)
                    #if os(macOS)
                    .toggleStyle(.checkbox)
                    #endif
                
                if !preserveUserData {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("User data (favorites, owned sets) will be lost.")
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }
            
            HStack(spacing: 0) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary, lineWidth: 1)
                )
                .keyboardShortcut(.cancelAction)
                
                Button("Re-Initialize") {
                    onConfirm()
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(4)
                .keyboardShortcut(.return)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}
