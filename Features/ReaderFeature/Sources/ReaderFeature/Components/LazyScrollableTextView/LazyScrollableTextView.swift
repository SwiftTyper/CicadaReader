//
//  File.swift
//  ReaderFeature
//
//  Created by Wit Owczarek on 17/11/2025.
//

import Foundation
import SwiftUI

struct LazyScrollableTextView: View {
    let text: String
    let wordIndex: Int
    let loadMoreCallback: () -> Void

    @State private var cache = TextLayoutCache()

    var body: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView {
                    LazyTextView(
                        rows: cache.rows,
                        words: text.words,
                        wordIndex: wordIndex,
                        loadMoreCallback: loadMoreCallback
                    )
                    .padding(.horizontal)
                }
                .onAppear {
                    cache.updateIfNeeded(text: text, width: geo.size.width)
                }
                .onChange(of: text) { _, newText in
                    cache.updateIfNeeded(text: newText, width: geo.size.width)
                }
                .onChange(of: geo.size.width) { _, newWidth in
                    cache.updateIfNeeded(text: text, width: newWidth)
                }
                .onChange(of: wordIndex) { _, newIndex in
                    guard let rowIndex = cache.dic[newIndex] else { return }
                    DispatchQueue.main.async {
                        withAnimation {
                            proxy.scrollTo(rowIndex, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}
