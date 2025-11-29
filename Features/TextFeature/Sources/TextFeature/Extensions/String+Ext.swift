//
//  File.swift
//  TextFeature
//
//  Created by Wit Owczarek on 29/11/2025.
//

import Foundation

extension String {
    var words: [IdentifiableString] {
        let pattern = #"\S+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(startIndex..., in: self)

        return regex.matches(in: self, range: nsRange).compactMap { match in
            guard let range = Range(match.range, in: self) else { return nil }

            let start = match.range.location
            let end = match.range.location + match.range.length

            return IdentifiableString(
                String(self[range]),
                start: start,
                end: end
            )
        }
    }
}
