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
    let wordIndex: Int
    let loadMoreCallback: () -> Void
    let spaceWidth: CGFloat
    let font: UIFont
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: spaceWidth) {
                    ForEach(rows[rowIndex], id: \.self) { w in
                        Text(words[w])
                            .font(.system(size: font.pointSize))
                            .background(
                                w == wordIndex ? Color.yellow.opacity(0.4) : Color.clear
                            )
                    }
                }
                .onAppear {
                    if rowIndex > max(rows.count - 20, 0) {
                        loadMoreCallback()
                    }
                }
                .id(rowIndex)
            }
        }
    }
}
