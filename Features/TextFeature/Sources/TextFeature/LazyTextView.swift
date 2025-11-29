//
//  File.swift
//  TextFeature
//
//  Created by Wit Owczarek on 29/11/2025.
//

import Foundation
import SwiftUI

public struct LazyTextView: UIViewRepresentable {
    var currentWordIndex: Int?
    var initialText: String
    var loadMore: (() async -> String)?
    
    public init(currentWordIndex: Int? = nil, initialText: String, loadMore: (() async -> String)? = nil) {
        self.currentWordIndex = currentWordIndex
        self.initialText = initialText
        self.loadMore = loadMore
    }

    public func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        
        tv.isEditable = false
        tv.isScrollEnabled = true
        tv.delegate = context.coordinator
        tv.clipsToBounds = false
        
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 6
        style.paragraphSpacing = 10

        let attributed = NSAttributedString(
            string: initialText,
            attributes: [
                .paragraphStyle: style,
                .kern: 1.4,
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.label
            ]
        )

        tv.attributedText = attributed
        
        return tv
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        guard let currentWordIndex else { return }
        context.coordinator.selectWord(currentWordIndex, in: uiView)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
