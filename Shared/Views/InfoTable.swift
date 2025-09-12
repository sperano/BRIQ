//
//  InfoTable.swift
//  BRIQ
//
//  Created by Éric Spérano on 9/5/25.
//

import SwiftUI

struct InfoTableRow<Value: View>: View {
    let label: String
    let value: Value
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.semibold)
                .frame(width: 150, alignment: .leading)

            value.frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.all, 6)
    }
}

struct InfoTable: View {
    let rows: [(label: String, value: AnyView)?]

    var body: some View {
        VStack(spacing: 0) {
            let unwrappedRows = rows.compactMap { $0 }
            ForEach(Array(unwrappedRows.enumerated()), id: \.0) { index, row in
                InfoTableRow(label: row.label, value: row.value)
                    .background(
                        index.isMultiple(of: 2) ?
                            Color(.systemGray).opacity(0.1) : Color(.systemGray).opacity(0.3))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)  
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .shadow(radius: 2)
        //.padding()
    }
}

struct InfoTable_Previews: PreviewProvider {
    static var previews: some View {
        InfoTable(rows: [
            ("Number", AnyView(Text("375 / 6075"))),
            ("Name", AnyView(Text("Yellow Castle"))),
            nil,
            ("Year Released", AnyView(Text("1978"))),
            ("Pieces", AnyView(Text("767"))),
        ])
    }
}
