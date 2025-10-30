import Foundation
import AVFAudio
import SwiftUI
import TTSFeature

struct ReaderView: View {
    @State private var model: ReaderViewModel
    @State private var scrollPosition = ScrollPosition()
    @State private var controller: ReaderController
    
    init(book: Book) {
        _controller = State(wrappedValue: ReaderController(synthesizer: .init(), text: book.content))
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
        .overlay {
            if self.model.status == .loading {
                ProgressView()
            }
        }
        .task {
            do {
                self.model.status = .loading
                await self.controller.setup()
                self.model.status = .idle
            } catch {
                print(error.localizedDescription)
                self.model.status = .idle
            }
        }
        .navigationTitle(model.book.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ReaderViewToolbar(model: model, controller: controller) }
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

//
//struct Chunk: Identifiable, Hashable {
//    let id: UUID
//    let text: String
//    /// silence to insert after this chunk (ms)
//    let pauseAfterMs: Int
//    /// original text range (optional, for highlighting)
//    let textRange: Range<Int>?
//
//    init(text: String, pauseAfterMs: Int = 200, textRange: Range<Int>? = nil) {
//        self.id = UUID()
//        self.text = text
//        self.pauseAfterMs = pauseAfterMs
//        self.textRange = textRange
//    }
//}


struct SynthesizedChunk {
    let chunk: String
    let audioData: Data
}
//
//actor SynthQueue {
//    private let synthesizer: TtSManager
//    private let chunker: TextChunker
//    private var buffer: [SynthesizedChunk] = []
//    private let maxBufferCount: Int
//
//    // Continuation for consumers
//    private var audioContinuation: AsyncStream<SynthesizedChunk>.Continuation?
//
//    // Track synthesizer tasks so we can cancel them if needed
//    private var synthTasks: [UUID: Task<Void, Never>] = [:]
//
//    init(
//        synthesizer: TtSManager,
//        chunker: TextChunker,
//        maxBufferCount: Int = 2
//    ) {
//        self.synthesizer = synthesizer
//        self.chunker = chunker
//        self.maxBufferCount = maxBufferCount
//    }
//
//    /// Returns a stream of synthesized chunks as they become ready
//    func audioStream() -> AsyncStream<SynthesizedChunk> {
//        AsyncStream { continuation in
//            self.audioContinuation = continuation
//        }
//    }
//
//    /// Start consuming chunk stream and synthesizing ahead-of-time.
//    /// This function returns immediately; the actor handles synthesis.
//    func startProducing() async {
//        guard Task.isCancelled == false else { return }
//        let next = await chunker.getNext()
//            // Backpressure: wait until buffer has room
//            while await self.buffer.count >= self.maxBufferCount {
//                try? await Task.sleep(nanoseconds: 30_000_000)
//                if Task.isCancelled { break }
//            }
//            if Task.isCancelled { break }
//
//            // Create a structured Task for each synthesis so it can be cancelled later.
//            let t = Task { [weak self] in
//                guard let self = self else { return }
//                if Task.isCancelled { return }
//                do {
//                    let data = try await self.synthesizer.synthesize(text: chunk.text)
//                    if Task.isCancelled { return }
//                    let synthesized = SynthesizedChunk(chunk: chunk, audioData: data)
//                    await self.append(synthesized)
//                } catch {
//                    // on error we can decide to emit nothing or finish
//                    // send finish to consumers
//                    await self.finish(withError: error)
//                }
//            }
//
//            // store task to allow cancellation later
//            await storeTask(t, for: chunk.id)
//
//        // producer finished input
//        await finish()
//    }
//
//    private func storeTask(_ task: Task<Void, Never>, for chunkId: UUID) {
//        synthTasks[chunkId] = task
//    }
//
//    private func removeTask(for chunkId: UUID) {
//        synthTasks.removeValue(forKey: chunkId)
//    }
//
//    func cancelPendingSynthesis() {
//        for (_, t) in synthTasks {
//            t.cancel()
//        }
//        synthTasks.removeAll()
//    }
//
//    private func append(_ synthesized: SynthesizedChunk) {
//        buffer.append(synthesized)
//        audioContinuation?.yield(synthesized)
//        removeTask(for: synthesized.chunk.id)
//    }
//
//    private func finish() {
//        audioContinuation?.finish()
//    }
//
//    private func finish(withError: Error) {
//        // No direct way to throw into AsyncStream; finish for now
//        audioContinuation?.finish()
//    }
//
//    /// Consumer helper: take next synthesized chunk (suspends if none)
//    func takeNext() async -> SynthesizedChunk? {
//        while buffer.isEmpty {
//            // If no producer tasks and no buffer, return nil to signal end
//            if synthTasks.isEmpty { return nil }
//            try? await Task.sleep(nanoseconds: 20_000_000)
//            if Task.isCancelled { return nil }
//        }
//        return buffer.removeFirst()
//    }
//}

actor ReaderController {
    private let synthesizer: TtSManager
    private let player: StreamingAudioPlayer?
    private let synthQueue: AsyncBuffer<SynthesizedChunk?>

    init(
        synthesizer: TtSManager,
        text: String,
        bufferAhead: Int = 2,
    ) {
        let chunker = TextChunker(text: text)
        self.synthesizer = synthesizer
        self.synthQueue = AsyncBuffer(
            targetSize: bufferAhead,
            produce: {
                guard let chunk = await chunker.getNext() else { return nil }
                guard let audio = try? await synthesizer.synthesize(text: chunk) else { return nil }
                return SynthesizedChunk(chunk: chunk, audioData: audio)
            }
        )
        if let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 24000,
            channels: 1,
            interleaved: false
        ) {
            self.player = StreamingAudioPlayer(format: format)
        } else {
            self.player = nil
        }
    }
    
    func setup() async {
        try? await synthesizer.initialize()
    }

    func read() async {
        guard let chunk = try? await synthQueue.next() else { return }
        
        await self.player?.appendAudioData(chunk.audioData)
        
        await read()
    }

//    func stop() {
//        // Cancel playback task and any pending synthesis
//        playbackTask?.cancel()
//        playbackTask = nil
//
//        Task {
//            await synthQueue.cancelPendingSynthesis()
//            await player.stop()
//        }
//    }
}

actor AsyncBuffer<T> {
    private var buffer: [T] = []
    private var fillTask: Task<Void, Never>? = nil
    private let produce: @Sendable () async throws -> T
    private let targetSize: Int

    init(targetSize: Int = 2, produce: @escaping @Sendable () async throws -> T) {
        self.targetSize = targetSize
        self.produce = produce
    }

    func next() async throws -> T {
        if buffer.isEmpty {
            print("starting pred")
            let item = try await produce()
            append(item)
        }

        let item = buffer.removeFirst()
        
        startBackgroundRefill()
        
        return item
    }

    private func startBackgroundRefill() {
//        guard fillTask == nil || fillTask?.isCancelled == true else { return }
        
        guard buffer.count < targetSize else { return }
        let needed = targetSize - buffer.count
        
        fillTask = Task {
//            try? await withThrowingTaskGroup(of: T.self) { group in
//                for _ in 0..<needed {
//                    group.addTask {
            guard let produce = try? await self.produce() else { return }
            self.append(produce)
            //sth might be wrong here
                    
//                    }
//                }
//                
//                for try await newItem in group {
//                    self.append(newItem)
//                }
//            }
        }
    }

    private func append(_ item: T) {
        buffer.append(item)
    }

    func cancel() {
        fillTask?.cancel()
        fillTask = nil
    }
}
