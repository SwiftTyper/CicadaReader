//
//  TextChunker.swift
//  Readify
//
//  Created by Wit Owczarek on 28/10/2025.
//

import Foundation
import NaturalLanguage

actor TextChunker {
    private var currentIndex: Int = 0
    nonisolated private let chunks: [String]

    init(text: String) {
        self.chunks = TextChunker.makeChunks(from: text)
    }

    func getNext() throws -> String {
        guard currentIndex < chunks.count
        else { throw ChunkingError.runOutOfChunks }

        let string = chunks[currentIndex]
        currentIndex += 1
        return string
    }

    private static nonisolated func makeChunks(from text: String) -> [String] {
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

    enum ChunkingError: Error {
        case runOutOfChunks
    }
}
