//
//  TextService.swift
//  Readify
//
//  Created by Wit Owczarek on 24/10/2025.
//

import Foundation
import NaturalLanguage

//MARK: To Do: stop the enumartion once we find the sentecse we are looking for

struct TextService {
    func startOfPreviousSentence(wordIndex: Int, from text: String) -> Int? {
        let boundaries = sentenceBoundaries(for: text)
        guard
            let current = boundaries.first(where: { $0.start <= wordIndex && $0.end >= wordIndex }),
            let currentIndex = boundaries.firstIndex(where: { $0 == current }),
            currentIndex > 0
        else { return nil }
        return boundaries[currentIndex - 1].start
    }
    
    func startOfNextSentence(wordIndex: Int, from text: String) -> Int? {
        let boundaries = sentenceBoundaries(for: text)
        guard
            let current = boundaries.first(where: { $0.start <= wordIndex && $0.end >= wordIndex }),
            let currentIndex = boundaries.firstIndex(where: { $0 == current }),
            currentIndex < boundaries.count - 1
        else { return nil }
        return boundaries[currentIndex + 1].start
    }
    
    func getCurrentSentence(wordIndex: Int, from text: String) -> String? {
        let boundaries = sentenceBoundaries(for: text)
        guard
            let current = boundaries.first(where: { $0.start <= wordIndex && $0.end >= wordIndex }),
            let currentIndex = boundaries.firstIndex(where: { $0 == current })
        else { return nil }
        let string = text.words[wordIndex...boundaries[currentIndex].end].joined(separator: " ")
        return string
    }
    
    private func sentenceBoundaries(for text: String) -> [(start: Int, end: Int)] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        var boundaries: [(Int, Int)] = []

        var wordStartIndex = 0
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = text[range]
            let sentenceWordCount = String(sentence).words.count
            guard sentenceWordCount > 0 else {
                return true
            }
            let start = wordStartIndex
            let end = wordStartIndex + sentenceWordCount - 1
            boundaries.append((start, end))
            wordStartIndex = end + 1
            return true
        }

        return boundaries
    }
}
