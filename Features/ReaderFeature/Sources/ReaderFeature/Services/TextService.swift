//
//  TextService.swift
//  Readify
//
//  Created by Wit Owczarek on 24/10/2025.
//

import Foundation
import NaturalLanguage

struct TextService {
    /// Scans sentence-by-sentence, stops as soon as the answer is known.
    static func findSentenceBoundary(
        wordIndex: Int,
        in text: String,
        direction: Direction
    ) -> Int? {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        var currStart = 0
        var prevStart: Int?
        var currEnd: Int?
        var foundCurrent = false

        let _ = tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentenceText = String(text[range])
            let wordCount = sentenceText.words.count
            
            if wordCount == 0 { return true }
            
            let start = currStart
            let end = currStart + wordCount - 1

            if !foundCurrent {
                if start <= wordIndex && end >= wordIndex {
                    currStart = start
                    currEnd = end
                    foundCurrent = true

                    if direction == .backward {
                        return false
                    }
                } else {
                    prevStart = start
                }
            } else {
                if direction == .forward {
                    currStart = start
                    return false
                }
            }

            currStart = end + 1
            return true
        }

        switch direction {
            case .backward:
                return prevStart
            case .forward:
                return currStart == currEnd ? nil : currStart
        }
    }
}
