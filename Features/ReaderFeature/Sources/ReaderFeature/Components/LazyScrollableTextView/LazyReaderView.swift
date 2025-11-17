import SwiftUI
import UIKit

@Observable
final class TextLayoutCache {
    private(set) var rows: [[Int]] = []
    private(set) var dic: [Int: Int] = [:]

    private var lastText: String = ""
    private var lastWidth: CGFloat = 0

    func updateIfNeeded(
        text: String,
        width: CGFloat,
        font: UIFont = .systemFont(ofSize: 18)
    ) {
        guard text != lastText || width != lastWidth else { return }

        let words = text.words
        let newRows = layoutWords(words: words, font: font, width: width)
        let newDic = rowsToDict(newRows)

        self.rows = newRows
        self.dic = newDic
        self.lastText = text
        self.lastWidth = width
    }

    private func rowsToDict(_ rows: [[Int]]) -> [Int: Int] {
        var dict: [Int: Int] = [:]
        for (rowIndex, row) in rows.enumerated() {
            for wordIndex in row {
                dict[wordIndex] = rowIndex
            }
        }
        return dict
    }
    
    private func layoutWords(
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
}

