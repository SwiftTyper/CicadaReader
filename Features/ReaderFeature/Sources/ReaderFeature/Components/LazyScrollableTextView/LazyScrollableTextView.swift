//
//  File.swift
//  ReaderFeature
//
//  Created by Wit Owczarek on 17/11/2025.
//

import Foundation
import SwiftUI

struct LazyScrollableTextView: View {
    let words: [String]
    let wordIndex: Int
    let loadMoreCallback: () async -> [String]
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var isHorizontal: Bool {
        verticalSizeClass == .compact
    }
    
    var body: some View {
        WrappingHStack(words, id: \.self, alignment: .leading, spacing: .constant(8), lineSpacing: 8, scrollToElement: wordIndex) { word, words in
            let isCurrent = words[self.wordIndex] == word
            Text(word)
                .opacity(isCurrent ? 0 : 1)
                .fontDesign(.serif)
                .font(.body)
                .background {
                    Text(word)
                        .fontDesign(.serif)
                        .bold(isCurrent)
                        .opacity(isCurrent ? 1 : 0)
                        .fixedSize()
                        .padding(2)
                        .background(isCurrent ? Color.yellow.opacity(0.35) : Color.clear)
                        .clipShape(.rect(cornerRadius: 8))
                }
        } loadMoreData: {
           await loadMoreCallback()
        }
        .scrollClipDisabled(true)
        .padding(.horizontal, isHorizontal ? .zero : 16)
    }
}
