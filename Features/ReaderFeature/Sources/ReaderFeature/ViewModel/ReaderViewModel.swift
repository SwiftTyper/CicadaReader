//
//  ReaderViewModel.swift
//  Readify
//
//  Created by Wit Owczarek on 24/10/2025.
//

import Foundation
import Observation
import SwiftUI
@preconcurrency import TTSFeature

// MARK: - FIFO
struct Stack<T> {
    init() { values = [] }
    private var values: [T]

    mutating func pop() -> T? { values.isEmpty ? nil : values.remove(at: 0) }
    mutating func push(_ value: T) { values.append(value) }
    var isEmpty: Bool { values.isEmpty }
    var count: Int { values.count }
}


// MARK: - PIPELINE
actor Pipeline {
    init(chunker: TextChunker) {
        self.cache = .init()
        self.chunker = chunker
        self.synthesizer = .init()

        let (stream, continuation) = AsyncStream.makeStream(of: SynthesizedChunk.self)
        self.streamContinuation = continuation
        self.stream = stream
    }

    private let cache: AudioSynthesisCache
    private let chunker: TextChunker
    private let synthesizer: TtSManager

    private var buffer = Stack<SynthesizedChunk>()
    private let targetBufferSize = 2

    // Async stream for waiting
    private let stream: AsyncStream<SynthesizedChunk>
    private let streamContinuation: AsyncStream<SynthesizedChunk>.Continuation

    private var producerTask: Task<Void, Never>?
    
    func setup() async throws {
        try await synthesizer.initialize()
        startProducer()
    }
    
    // MARK: - Public API

    /// Get next chunk. If buffer is empty, will await next produced chunk.
    func next() async throws -> SynthesizedChunk {
        if let value = buffer.pop() {
            return value
        }

        // Otherwise wait for next produced value
        let value = try await waitForNextProduced()
        return value
    }

    /// Call when you want to reset buffer (optional)
    func reset() {
        buffer = .init()
    }

    // MARK: - Core

    private func waitForNextProduced() async throws -> SynthesizedChunk {
        var iterator = stream.makeAsyncIterator()
        guard let chunk = await iterator.next() else {
            throw CancellationError()
        }
        return chunk
    }

     private func startProducer() {
        producerTask = Task {
            while !Task.isCancelled {
                do {
                    try await fillBufferIfNeeded()
                } catch {
                    // stop on fatal chunker/synth errors
                    break
                }
            }
        }
    }

    /// Ensures buffer stays 2 ahead. Produces and yields each new value into the stream.
    private func fillBufferIfNeeded() async throws {
        // If buffer already big enough, pause a bit
        if buffer.count >= targetBufferSize {
            try await Task.sleep(for: .milliseconds(10))
            return
        }

        // Produce one
        let chunk = try await produce()
        buffer.push(chunk)

        // Notify waiting readers
        streamContinuation.yield(chunk)
    }


    // MARK: - Produce one chunk

    private func produce() async throws -> SynthesizedChunk {
        try Task.checkCancellation()
        let text = try await chunker.getNext()

        try Task.checkCancellation()
        let cacheKey = AudioCacheKey(text: text, rate: 1.0)
        let cachedAudio = await cache.retrieveData(for: cacheKey)

        if let cachedAudio {
            return SynthesizedChunk(content: text, audioData: cachedAudio)
        }

        try Task.checkCancellation()
        let audio = try await synthesizer.synthesize(text: text)

        try await cache.store(data: audio, for: cacheKey)

        return SynthesizedChunk(content: text, audioData: audio)
    }
}


////FIFO
//struct Stack<T> {
//    init() { values = [] }
//    
//    private var values: [T]
//    
//    mutating func pop() -> T? {
//        return values.remove(at: 0)
//    }
//    
//    mutating func push(_ value: T) {
//        values.append(value)
//    }
//    
//    var isEmpty: Bool {
//        values.isEmpty
//    }
//}
//
//class Pipeline {
//    init(chunker: TextChunker) {
//        self.cache = .init()
//        self.chunker = chunker
//        self.synthesizer = .init()
//    }
//    
//    private let cache: AudioSynthesisCache
//    private let chunker: TextChunker
//    private let synthesizer: TtSManager
//    
//    var buffer: Stack<SynthesizedChunk> = .init()
//    
//    func next() async throws -> SynthesizedChunk? {
//        guard buffer.isEmpty else {
//            return buffer.pop()
//        }
//        
//        //await the next value from the buffer it should be a stream
//    }
//    
//    func produce() async throws -> SynthesizedChunk {
//        try Task.checkCancellation()
//        let text = try await chunker.getNext()
//        
//        try Task.checkCancellation()
//        let cacheKey: AudioCacheKey = .init(text: text, rate: 1.0)
//        let cachedAudio: Data? = await cache.retrieveData(for: cacheKey)
//        
//        guard cachedAudio == nil else {
//            return SynthesizedChunk(content: text, audioData: cachedAudio!)
//        }
//        
//        try Task.checkCancellation()
//        let audio: Data = try await synthesizer.synthesize(text: text)
//        
//        try await cache.store(data: audio, for: cacheKey)
//        
//        return SynthesizedChunk(content: text, audioData: audio)
//    }
//}

@MainActor
@Observable
class ReaderViewModel {
    private let player: StreamingAudioPlayer
    private let textLoader: TextLoader
    private let pipeline: Pipeline
    
//    private let synthQueue: AsyncBuffer<SynthesizedChunk>

    private var currentTask: Task<Void, Never>?
    
    @MainActor var status: ReaderStatus = .idle
    @MainActor var currentWordIndex: Int = 0
    @MainActor var errorMessage: String? = nil
    var text: String = ""

    init(
        synthesizer: TtSManager,
        contentUrl: URL,
        bufferAhead: Int = 2,
    ) {
        let chunker = TextChunker()
        self.textLoader = TextLoader(url: contentUrl, chunker: chunker)
        self.pipeline = Pipeline(chunker: chunker)
        self.player = .init()
    }
    
    func onScrollChange() async {
        guard let text = try? await textLoader.nextChunk() else { return }
        
        await MainActor.run {
            self.text += text
        }
    }

    func setup() async {
        self.status = .preparing
        do {
            await onScrollChange()
            try await self.pipeline.setup()
        } catch {
            self.status = .idle
        }
        self.status = .idle
    }
    
    @MainActor
    func toggleAutoRead() {
        self.status.toggle()
        
        if self.status == .restartable {
            self.currentWordIndex = 0
            self.status = .reading
        }
        
        if self.status == .reading {
            let previousTask = self.currentTask
            previousTask?.cancel()
            self.currentTask = Task { [previousTask] in
                _ = await previousTask?.value
                await read()
            }
        } else if self.status == .idle {
            self.currentTask?.cancel()
        }
    }
    
    func cancel() {
        self.currentTask?.cancel()
    }
    
    private func read() async {
        do {
            while !Task.isCancelled {
                self.status = .loading
                let chunk: SynthesizedChunk = try await self.pipeline.next()
                self.status = .reading
                
                let chunkStartIndex = self.currentWordIndex
                
                await withDiscardingTaskGroup { group in
                    group.addTask { [player] in
                        await player.queue(audio: chunk.audioData)
                    }
                    
                    group.addTask {
                        let stream = await self.player.wordStream(words: chunk.content.words, audio: chunk.audioData)
                        for await wordIndex in stream {
//                            self.currentWordIndex = wordIndex + chunkStartIndex
                        }
                    }
                }
            }
        } catch is CancellationError  {
            self.status = .idle
        } catch is ChunkingError {
            self.status = .restartable
        } catch {
            self.errorMessage = "Unexpected error: \(error)"
        }
    }
}

//MARK: Forward & Reverse Actions
extension ReaderViewModel {
    @MainActor
    var canStepBack: Bool {
       TextService.findSentenceBoundary(
            wordIndex: self.currentWordIndex,
            in: self.text,
            direction: .backward
        ) != nil
    }
    
    @MainActor
    var canStepForward: Bool {
        TextService.findSentenceBoundary(
             wordIndex: self.currentWordIndex,
             in: self.text,
             direction: .forward
         ) != nil
    }

    @MainActor
    func skip(_ direction: Direction) {
        guard let start = TextService.findSentenceBoundary(
            wordIndex: self.currentWordIndex,
            in: self.text,
            direction: direction
        ) else { return }
        
        if self.status == .reading || self.status == .loading {
            let previousTask = self.currentTask
            previousTask?.cancel()
            self.currentTask = Task { [previousTask] in
                _ = await previousTask?.value
                await pipeline.reset()
                self.currentWordIndex = start
                await read()
            }
              
        } else if self.status == .idle || self.status == .restartable {
            self.currentWordIndex = start
        }
    }
}
