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
    let loadMoreCallback: () -> Void
    
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var isHorizontal: Bool {
        verticalSizeClass == .compact
    }
    
    var body: some View {
        WrappingHStack(0..<words.count, id: \.self, alignment: .leading, spacing: .constant(8), lineSpacing: 8, scrollToElement: wordIndex) { wordIndex in
            let isCurrent = wordIndex == self.wordIndex
            Text(words[wordIndex])
                .opacity(isCurrent ? 0 : 1)
                .fontDesign(.serif)
                .font(.body)
                .background {
                    Text(words[wordIndex])
                        .fontDesign(.serif)
                        .bold(isCurrent)
                        .opacity(isCurrent ? 1 : 0)
                        .fixedSize()
                        .padding(2)
                        .background(isCurrent ? Color.yellow.opacity(0.35) : Color.clear)
                        .clipShape(.rect(cornerRadius: 8))
                }
                .onAppear {
                    if wordIndex == self.words.count - 10 {
                        loadMoreCallback()
                    }
                }
        }
        .scrollClipDisabled(true)
        .padding(.horizontal, isHorizontal ? .zero : 16)
    }
}
