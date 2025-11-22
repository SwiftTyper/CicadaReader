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
                    lazyTextView
                }
                .onAppear {
                    self.cache.updateIfNeeded(text: self.text, width: geo.size.width - 32)
                }
                .onChange(of: text) { _, newText in
                    self.cache.updateIfNeeded(text: newText, width: geo.size.width - 32)
                }
                .onChange(of: geo.size.width) { _, newWidth in
                    self.cache.updateIfNeeded(text: self.text, width: newWidth)
                }
                .onChange(of: wordIndex) { _, newIndex in
                    guard let rowIndex = self.cache.dic[newIndex] else { return }
                    
                    DispatchQueue.main.async {
                        withAnimation(.linear(duration: 0.5)){
                            proxy.scrollTo(rowIndex, anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    var lazyTextView: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(self.cache.rows.indices, id: \.self) { rowIndex in
                HStack(spacing: self.cache.spaceWidth) {
                    ForEach(self.cache.rows[rowIndex], id: \.self) { w in
                        Text(self.cache.words[w])
                            .font(.system(size: self.cache.font.pointSize))
                            .background(
                                w == self.wordIndex ? Color.yellow.opacity(0.4) : Color.clear
                            )
                    }
                }
                .onAppear {
                    if rowIndex > max(self.cache.rows.count - 20, 0) {
                        self.loadMoreCallback()
                    }
                }
                .id(rowIndex)
            }
        }
        .padding(.horizontal, 16)
    }
}
