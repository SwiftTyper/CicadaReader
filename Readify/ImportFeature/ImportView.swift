//
//  ImportView.swift
//  Readify
//
//  Created by Wit Owczarek on 20/10/2025.
//

import Foundation
import SwiftUI
import TTSFeature

struct Book: Hashable {
    let title: String
    let content: String
    
    init(title: String = "", content: String) {
        self.title = title
        self.content = content
    }
}

struct ImportView: View {
    @State private var book: Book? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                PasteImportView { string in
                    book = .init(content: string)
                }

                Spacer()
            }
            .navigationDestination(item: $book) { book in
//                ReaderView(book: book, synthesizer: .init())
            }
            .navigationTitle("Import")
        }
    }
}
