import Foundation
import SwiftUI

//    .task {
//                    do {
//
//                        let manager = TtSManager()
//                        try await manager.initialize()
//
//                        // Synthesize speech to memory (not to a file)
//                        let audioData = try await manager.synthesize(text: "Hello, world! This is a test.")
//                        self.data = audioData
//
//                    } catch {
//                        print(error.localizedDescription)
//                    }
//                      do {
//                          let models = try await TtsModels.download(variants: [.fiveSecond])
//                          TtSManager.initialize()
//                          let kokoroModel = models.model(for: .fiveSecond)
////                        let data = try await KokoroModel.synthesize(text: "Hello from FluidAudio.")
////                        try data.write(to: URL(fileURLWithPath: "out.wav"))
//                      } catch {
//                        print("TTS error: \(error)")
//                      }
//                }

struct ReaderView: View {
    @State private var model: ReaderViewModel
    @State private var scrollPosition = ScrollPosition()
    
    init(book: Book) {
        _model = State(wrappedValue: ReaderViewModel(book: book))
    }

    var body: some View {
        ScrollView {
            TextComposerView(
                words: model.book.content.words,
                currentWordIndex: model.currentWordIndex
            )
        }
        .scrollPosition($scrollPosition, anchor: .center)
        .onChange(of: model.currentWordIndex) { _, newValue in
            withAnimation {
                self.scrollPosition = .init(id: String(newValue))
            }
        }
        .onAppear {
            self.scrollPosition = .init(id: String(model.currentWordIndex))
        }
        .navigationTitle(model.book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    model.stepBack()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!model.canStepBack)
                
                Button {
                    model.stepForward()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(!model.canStepForward)
            }
            
            ToolbarItem(placement: .bottomBar) {
                Button {
                    model.toggleAutoRead()
                } label: {
                    Image(systemName: model.isReading ? "pause.fill" : "play.fill")
                }
                .contentTransition(.symbolEffect(.replace))
            }
        }
    }
}


#Preview {
    let sample = Book(content: """
    This is a sample book content. It has multiple words and sentences to demonstrate the reader view. Try changing the speed or auto-reading to see the word highlight move. This is a sample book content. It has multiple words and sentences to demonstrate the reader view. Try changing the speed or auto-reading to see the word highlight move. This is a sample book content. It has multiple words and sentences to demonstrate the reader view. Try changing the speed or auto-reading to see the word highlight move. This is a sample book content. It has multiple words and sentences to demonstrate the reader view. Try changing the speed or auto-reading to see the word highlight move.
    """)

    NavigationStack {
        ReaderView(book: sample)
    }
}
