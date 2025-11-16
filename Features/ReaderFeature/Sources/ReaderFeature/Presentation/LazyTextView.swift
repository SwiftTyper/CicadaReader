//
//  File.swift
//  ReaderFeature
//
//  Created by Wit Owczarek on 16/11/2025.
//

import Foundation
import SwiftUI

struct LazyTextView: View {
    let rows: [[Int]]
    let words: [String]
    let currentWordIndex: Int
    let onScrollChange: (Int) -> Void
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 4) {
                    ForEach(rows[rowIndex], id: \.self) { w in
                        Text(words[w])
                            .background(
                                w == currentWordIndex ? Color.yellow.opacity(0.4) : Color.clear
                            )
                    }
                }
                .onAppear {
                    if rowIndex > Int(Double(rows.count) * 0.8) {
                        onScrollChange(rowIndex)
                    }
                }
                .id(rowIndex)
            }
        }
    }
}
