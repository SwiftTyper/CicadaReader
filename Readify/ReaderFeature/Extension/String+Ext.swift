//
//  String+Ext.swift
//  Readify
//
//  Created by Wit Owczarek on 24/10/2025.
//

import Foundation

extension String {
    var words: [String] {
        let pattern = #"\S+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(startIndex..., in: self)

        return regex.matches(in: self, range: range).compactMap {
            Range($0.range, in: self).map { String(self[$0]) }
        }
    }
}
