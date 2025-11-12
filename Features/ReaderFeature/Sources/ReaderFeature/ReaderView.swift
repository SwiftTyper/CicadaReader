import Foundation
import AVFAudio
import SwiftUI
import TTSFeature

public struct ReaderContent: Hashable {
    public init(title: String?, content: String) {
        self.title = title ?? "Untitled"
        self.content = content
    }
    
    let title: String
    let content: String
}

public struct ReaderView: View {
    @State private var vm: ReaderViewModel
    @State private var scrollPosition = ScrollPosition()
    
    private let book: ReaderContent
    
    private var alertIsPresented: Binding<Bool> {
        Binding {
            vm.errorMessage != nil
        } set: { value in
            guard value == false else { return }
            vm.errorMessage = nil
        }
    }
    
    public init(
        book: ReaderContent,
        synthesizer: TtSManager,
    ) {
        self.book = book
        self._vm = State(wrappedValue: ReaderViewModel(synthesizer: synthesizer, text: book.content))
    }

    public var body: some View {
        NavigationStack {
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
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ReaderViewToolbar(vm: vm) }
            .alert(
                "Something went wrong!",
                isPresented: alertIsPresented,
                actions: {},
                message: { Text(vm.errorMessage ?? "Please contact support")}
            )
            .loader(
                self.vm.status == .loading || self.vm.status == .preparing,
                isFullScreen: self.vm.status == .preparing
            )
            .task { await self.vm.setup() }
        }
    }
}

#Preview {
    let text = """
    This is a sample book content. It has multiple words and sentences to demonstrate the reader view. Try changing the speed or auto-reading to see the word highlight move. This is a sample book content. It has multiple words and sentences to demonstrate the reader view. Try changing the speed or auto-reading to see the word highlight move. This is a sample book content. It has multiple words and sentences to demonstrate the reader view. Try changing the speed or auto-reading to see the word highlight move. This is a sample book content. It has multiple words and sentences to demonstrate the reader view. Try changing the speed or auto-reading to see the word highlight move.
    """
    let sample = ReaderContent(title: nil, content: text)

    NavigationStack {
        ReaderView(book: sample, synthesizer: .init())
    }
}
