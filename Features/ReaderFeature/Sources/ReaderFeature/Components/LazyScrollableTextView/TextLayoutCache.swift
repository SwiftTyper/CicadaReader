import SwiftUI
import UIKit

@Observable
final class TextLayoutCache {
    private(set) var rows: [[Int]] = []
    private(set) var dic: [Int: Int] = [:]

    private var lastText: String = ""
    private var lastWidth: CGFloat = 0

    @MainActor
    func updateIfNeeded(
        text: String,
        width: CGFloat,
        font: UIFont = .preferredFont(forTextStyle: .body)
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
    
    func spaceWidth(using font: UIFont = .preferredFont(forTextStyle: .body)) -> CGFloat {
        let str = " "
        let storage = NSTextStorage(string: str, attributes: [.font: font])
        let container = NSTextContainer(size: .init(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude))
        let manager = NSLayoutManager()
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)

        let rect = manager.boundingRect(
            forGlyphRange: NSRange(location: 0, length: 1),
            in: container
        )

        return rect.width
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

        let storage = NSTextStorage(string: full, attributes: [.font: font])
        let container = NSTextContainer(size: CGSize(width: width.rounded(.down), height: .greatestFiniteMagnitude))
        container.lineBreakMode = .byWordWrapping

        let manager = NSLayoutManager()
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        
        _ = manager.glyphRange(for: container)

        var lines: [[Int]] = []
        var currentLineRect: CGRect? = nil

        var wordStartIndex = 0

        for (wordIndex, word) in words.enumerated() {
            let wordWithSpace = (wordIndex < words.count - 1) ? word + " " : word
            let wordRange = NSRange(location: wordStartIndex, length: (word as NSString).length)
            let glyphRange = manager.glyphRange(forCharacterRange: wordRange, actualCharacterRange: nil)
            let lineRect = manager.boundingRect(forGlyphRange: glyphRange, in: container)

            if currentLineRect == nil || lineRect.minY > currentLineRect!.minY {
                lines.append([])
                currentLineRect = lineRect
            }

            lines[lines.count - 1].append(wordIndex)

            wordStartIndex +=  (wordWithSpace as NSString).length
        }

        return lines
    }
}

