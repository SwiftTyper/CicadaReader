//
//  File.swift
//  ReaderFeature
//
//  Created by Wit Owczarek on 16/11/2025.
//

import Foundation
import SwiftUI

struct LazyReaderView: View {
    let text: String
    let currentWordIndex: Int
    let width: CGFloat
    let onScrollPositionChange: (Int) -> Void

    var words: [String] {
        text.words
    }
    
    private var rows: [[Int]] {
        layoutWords(words: words, font: UIFont.systemFont(ofSize: 18), width: width)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyTextView(
                    rows: rows,
                    words: words,
                    currentWordIndex: currentWordIndex,
                    onScrollChange: onScrollPositionChange
                )
                .padding(.horizontal)
            }
            .onChange(of: currentWordIndex) { _, newIndex in
                guard let rowIndex = rows.firstIndex(where: { $0.contains(newIndex) })
                else { return }
                
                withAnimation {
                    proxy.scrollTo(rowIndex, anchor: .center)
                }
            }
        }
    }
}
