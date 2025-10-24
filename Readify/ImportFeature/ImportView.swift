//
//  ImportView.swift
//  Readify
//
//  Created by Wit Owczarek on 20/10/2025.
//

import Foundation
import SwiftUI

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
                ReaderView(book: book)
            }
            .navigationTitle("Import")
        }
    }
}
