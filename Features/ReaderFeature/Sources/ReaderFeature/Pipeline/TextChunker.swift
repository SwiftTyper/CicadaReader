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
    private var chunks: [String] = []
    
    func get(from wordIndex: Int) -> String {
        //identify chunk in which the word index is
        var currentWordIndex: Int = 0
        var currentChunkIndex: Int = 0
        for index in 0..<chunks.count {
            let wordCount = chunks[index].words.count
            if currentWordIndex + wordCount < wordIndex {
                currentWordIndex += wordCount
            } else {
                currentChunkIndex = index
                break
            }
        }
        
        //slice that chunk from word index to the end of the chunk
        let chunkSlice = chunks[currentChunkIndex].slice(beforeWordIndex: wordIndex)
        
        //set the chunk index to the next one
        self.chunkIndex += 1
        
        //return it
        return chunkSlice
    }
    
    func getNext() throws -> String {
        guard chunkIndex < chunks.count
        else {
            //TODO: Ask loader if there are any chunks left - should never happen
            throw ChunkingError.runOutOfChunks
        }

        let string = chunks[chunkIndex]
        chunkIndex += 1
        return string
    }
}

extension TextChunker {
    func compute(newText: String) {
        self.chunks.append(contentsOf: newText.makeChunks())
    }
}

private extension String {
    nonisolated func makeChunks() -> [String] {
        let text = self
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        var sentences: [Substring] = []
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let sentence = text[range]
            if !sentence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
