//
//  String+Ext.swift
//  Readify
//
//  Created by Wit Owczarek on 24/10/2025.
//

import Foundation
import NaturalLanguage

extension String {
    var words: [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = self
        var words: [String] = []
        tokenizer.enumerateTokens(in: self.startIndex..<self.endIndex) { range, _ in
            let word = String(self[range])
            guard !word.isEmpty else {
               return true
            }
            words.append(word)
            return true
        }
        return words
    }
}
