import Foundation
import AVFAudio
import SwiftUI
import TTSFeature

struct ReaderView: View {
    @State private var vm: ReaderViewModel
    @State private var scrollPosition = ScrollPosition()
    
    private let book: Book
    
    init(
        book: Book,
        synthesizer: TtSManager,
    ) {
        self.book = book
        self._vm = State(wrappedValue: ReaderViewModel(synthesizer: synthesizer, text: book.content))
    }

    var body: some View {
        ScrollView {
            TextComposerView(
                words: book.content.words,
                currentWordIndex: vm.currentWordIndex
            )
        }
        .scrollPosition($scrollPosition, anchor: .center)
        .onChange(of: vm.currentWordIndex) { _, newValue in
            withAnimation {
                self.scrollPosition = .init(id: String(newValue))
            }
        }
        .onAppear {
            self.scrollPosition = .init(id: String(vm.currentWordIndex))
        }
        .loader(self.vm.status == .loading || self.vm.status == .preparing, isFullScreen: self.vm.status == .preparing)
        .task { await self.vm.setup() }
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ReaderViewToolbar(vm: vm) }
    }
}

#Preview {
    let text = """
    This is a sample book content. It has multiple words and sentences to demonstrate the reader view. Try changing the speed or auto-reading to see the word highlight move. This is a sample book content. It has multiple words and sentences to demonstrate the reader view. Try changing the speed or auto-reading to see the word highlight move. This is a sample book content. It has multiple words and sentences to demonstrate the reader view. Try changing the speed or auto-reading to see the word highlight move. This is a sample book content. It has multiple words and sentences to demonstrate the reader view. Try changing the speed or auto-reading to see the word highlight move.
    """
    let sample = Book(content: text)

    NavigationStack {
        ReaderView(book: sample, synthesizer: .init())
    }
}

struct SynthesizedChunk {
    let content: String
    let audioData: Data
}
