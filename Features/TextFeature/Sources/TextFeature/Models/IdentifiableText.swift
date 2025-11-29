//
//  File.swift
//  TextFeature
//
//  Created by Wit Owczarek on 29/11/2025.
//

import Foundation

struct IdentifiableString {
    init(_ text: String, start: Int, end: Int) {
        self.text = text
        self.start = start
        self.end = end
    }

    let text: String
    let start: Int
    let end: Int
}
