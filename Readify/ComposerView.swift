//
//  ContentView.swift
//  Readify
//
//  Created by Wit Owczarek on 19/10/2025.
//

import SwiftUI
import TTSFeature
import ReaderFeature
import ImportFeature

struct ComposerView: View {
    @State private var content: ReaderContent? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ImportView { content in
                    self.content = ReaderContent(title: content.title, url: content.url)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Readify")
            .toolbarTitleDisplayMode(.inlineLarge)
            .navigationDestination(item: self.$content) { book in
                ReaderView(
                    content: book,
                    synthesizer: .init()
                )
            }
        }
    }
}

#Preview {
    ComposerView()
}
