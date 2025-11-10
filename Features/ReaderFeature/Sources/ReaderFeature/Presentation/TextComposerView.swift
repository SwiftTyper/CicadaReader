//
//  TextComposerView.swift
//  Readify
//
//  Created by Wit Owczarek on 24/10/2025.
//

import Foundation
import SwiftUI
import WrappingHStack

struct TextComposerView: View {
    let words: [String]
    let currentWordIndex: Int
    
    var body: some View {
        WrappingHStack(alignment: .leading, horizontalSpacing: 0) {
            ForEach(words.enumerated(), id: \.offset) { index, word in
               let isCurrent = (index == currentWordIndex)
               Text(word)
                    .opacity(isCurrent ? 0 : 1)
                    .fontDesign(.serif)
                    .font(.body)
                    .padding(3)
                    .padding(.horizontal, 2)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .foregroundStyle(isCurrent ? Color.yellow.opacity(0.35) : Color.clear)
                            .overlay {
                                Text(word)
                                    .fontDesign(.serif)
                                    .bold(isCurrent)
                                    .opacity(isCurrent ? 1 : 0)
                            }
                    }
                    .id(String(index))
           }
        }
        .padding(.horizontal)
    }
}
