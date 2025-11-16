//
//  TextComposerView.swift
//  Readify
//
//  Created by Wit Owczarek on 24/10/2025.
//

import Foundation
import SwiftUI
import UIKit

func layoutWords(
    words: [String],
    font: UIFont,
    width: CGFloat
) -> [[Int]] {
    let full = words.joined(separator: " ")

    let storage = NSTextStorage(string: full, attributes: [
        .font: font
    ])

    let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
    container.lineFragmentPadding = 0

    let manager = NSLayoutManager()
    manager.addTextContainer(container)
    storage.addLayoutManager(manager)

    // Force layout
    _ = manager.glyphRange(for: container)

    var lines: [[Int]] = []

    var currentLine: Int = -1

    var wordStartIndex = 0

    for (wordIndex, word) in words.enumerated() {
        let range = NSRange(location: wordStartIndex, length: word.count)

        var glyphRange = NSRange()
        manager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)

        let rect = manager.boundingRect(forGlyphRange: glyphRange, in: container)

        let thisLine = Int(rect.minY / font.lineHeight)

        if thisLine != currentLine {
            lines.append([])
            currentLine = thisLine
        }

        lines[currentLine].append(wordIndex)
        
        wordStartIndex += word.count + 1
    }

    return lines
}
