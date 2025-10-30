//
//  TextChunker.swift
//  Readify
//
//  Created by Wit Owczarek on 28/10/2025.
//

import Foundation
import NaturalLanguage

actor TextChunker {
    var currentIndex: Int = 0
    var chunks: [String] = []
    
    init(text: String) {
        self.chunks = self.chunk(text: text)
    }
    
    func getNext() -> String? {
        guard currentIndex < chunks.count else { return nil }
        let string = chunks[currentIndex]
    
//        if currentIndex < chunks.count - 1 {
            currentIndex += 1
//        }
        
        return string
    }
    
    private nonisolated func chunk(text: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text

        var sentences: [Substring] = []
        var ranges: [Range<String.Index>] = []

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = text[range]
            if !sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                sentences.append(sentence)
                ranges.append(range)
            }
            return true
        }

        var output: [String] = []
        var i = 0
        while i < sentences.count {
            let j = min(i + 2, sentences.count)
            let group = sentences[i..<j].joined(separator: " ")
//            let start = ranges[i].lowerBound
//            let end = ranges[j - 1].upperBound
//            let chunkRange = start..<end

//            let chunk = Chunk(
//                text: group.trimmingCharacters(in: .whitespacesAndNewlines),
//                pauseAfterMs: 200,
//                textRange: text.distance(from: text.startIndex, to: start)..<text.distance(from: text.startIndex, to: end)
//            )
            output.append(group)
            i = j
        }
        return output
    }
}
