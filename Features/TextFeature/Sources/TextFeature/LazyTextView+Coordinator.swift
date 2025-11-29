//
//  File.swift
//  TextFeature
//
//  Created by Wit Owczarek on 29/11/2025.
//

import Foundation
import UIKit

extension LazyTextView {
    public class Coordinator: NSObject, UITextViewDelegate {
        var parent: LazyTextView
        var highlightLayer: CAShapeLayer?

        init(_ parent: LazyTextView) { self.parent = parent }

        func selectWord(_ wordIndex: Int, in textView: UITextView) {
            let words = textView.text.words
            guard wordIndex < words.count else { return }
            
            var loc = 0
            for i in 0..<wordIndex { loc += words[i].count + 1 }
            let range = NSRange(location: loc, length: words[wordIndex].count)
            
            guard
                let startPosition = textView.position(from: textView.beginningOfDocument, offset: range.location),
                let endPosition = textView.position(from: startPosition, offset: range.length),
                let textRange = textView.textRange(from: startPosition, to: endPosition)
            else { return }
            
            let rect = textView.firstRect(for: textRange)
            
            highlightWord(rect, in: textView)
            scrollWordRange(rect, in: textView)
        }

        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            guard let loadMore = parent.loadMore, let tv = scrollView as? UITextView else { return }
            let visibleBottom = scrollView.contentOffset.y + scrollView.bounds.height
            if visibleBottom > scrollView.contentSize.height - 200 {
                Task {
                    let moreText = await loadMore()
                    await MainActor.run { tv.text.append(moreText) }
                }
            }
        }
    }
}

extension LazyTextView.Coordinator {
    private func highlightWord(_ rect: CGRect, in textView: UITextView) {
        highlightLayer?.removeFromSuperlayer()
        
        let rect = rect.inset(by: .init(top: 0, left: -4, bottom: 0, right: -4))
        
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(roundedRect: rect, cornerRadius: 6).cgPath
        layer.fillColor = UIColor.systemYellow.withAlphaComponent(0.3).cgColor
        
        if let textLayer = textView.layer.sublayers?.first {
            textView.layer.insertSublayer(layer, below: textLayer)
        } else {
            textView.layer.insertSublayer(layer, at: 0)
        }
        
        highlightLayer = layer
    }
    
    private func scrollWordRange(_ rect: CGRect, in textView: UITextView) {
        let offsetY = max(0, rect.midY - textView.bounds.height / 2)
        let maxOffsetY = max(0, textView.contentSize.height - textView.bounds.height)
        textView.setContentOffset(CGPoint(x: 0, y: min(offsetY, maxOffsetY)), animated: true)
    }
}
