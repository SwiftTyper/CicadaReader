//
//  TextChunker.swift
//  Readify
//
//  Created by Wit Owczarek on 28/10/2025.
//

import Foundation
import NaturalLanguage

actor TextChunker {
    private var chunkIndex: Int = 0
    private var chunks: [String]
    
    init(text: String) {
        self.chunks = text.makeChunks()
    }
    
    func rechunk(basedOn fullText: String, and wordIndex: Int) {
        self.chunkIndex = 0
        let newText = fullText.slice(beforeWordIndex: wordIndex)
        self.chunks = newText.makeChunks()
    }
    
    func getNext() throws -> String {
        guard chunkIndex < chunks.count
        else { throw ChunkingError.runOutOfChunks }

        let string = chunks[chunkIndex]
        chunkIndex += 1
        return string
    }
}

private extension String {
    nonisolated func makeChunks() -> [String] {
        let text = self.replacingOccurrences(of: "\n", with: " ")
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        var sentences: [String] = []
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = text[range].trimmingCharacters(in: .whitespacesAndNewlines)
            if !sentence.isEmpty {
                sentences.append(sentence)
            }
            return true
        }
        
        var output: [String] = []
        var i = 0
        while i < sentences.count {
            let j = min(i + 2, sentences.count)
            let group = sentences[i..<j].joined(separator: " ")
            output.append(group)
            i = j
        }
        return output
    }
    
    nonisolated func slice(beforeWordIndex n: Int) -> String {
       slice(afterWordIndex: n - 1)
    }
    
    nonisolated func slice(afterWordIndex n: Int) -> String {
         let pattern = #"\S+"#
         guard let regex = try? NSRegularExpression(pattern: pattern) else { return "" }
         let fullRange = NSRange(startIndex..., in: self)
         let matches = regex.matches(in: self, range: fullRange)
         
         guard matches.indices.contains(n + 1),
               let range = Range(matches[n + 1].range, in: self)
         else {
             return ""
         }

         return String(self[range.lowerBound...])
     }
}
