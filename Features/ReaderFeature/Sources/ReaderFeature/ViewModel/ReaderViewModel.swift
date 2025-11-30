//
//  ReaderViewModel.swift
//  Readify
//
//  Created by Wit Owczarek on 24/10/2025.
//

import Foundation
import Observation
import SwiftUI
import AsyncAlgorithms
@preconcurrency import TTSFeature

struct Stack<T> {
    init() { values = [] }
    private var values: [T]

    mutating func pop() -> T? { values.isEmpty ? nil : values.remove(at: 0) }
    mutating func push(_ value: T) { values.append(value) }
    var isEmpty: Bool { values.isEmpty }
    var count: Int { values.count }
}


class Pipeline: @unchecked Sendable {
    init(chunker: TextChunker) {
        self.cache = .init()
        self.chunker = chunker
        self.synthesizer = .init()
    }

    private let cache: AudioSynthesisCache
    private let chunker: TextChunker
    private let synthesizer: TtSManager

    private var buffer = Stack<SynthesizedChunk>()
    private let targetBufferSize = 2

    // Track ongoing production to avoid duplicate work
    private var isProducing = false
    private var waiters: [CheckedContinuation<SynthesizedChunk, Error>] = []
    
    func setup() async throws {
        try await synthesizer.initialize()
    }
    
    // MARK: - Public API

    /// Get next chunk. If buffer is empty, will await next produced chunk.
    func next() async throws -> SynthesizedChunk {
        // First, check if we have a buffered chunk
        if let value = buffer.pop() {
            // Kick off background production to refill buffer (non-blocking)
            Task { await self.ensureBufferFilled() }
            return value
        }

        // No buffered chunk - we need to wait for production
        return try await withCheckedThrowingContinuation { continuation in
            waiters.append(continuation)
            
            // Kick off production if not already running
            Task { await self.ensureBufferFilled() }
        }
    }
    
    func reset(from wordIndex: Int) {
        for waiter in waiters {
            waiter.resume(throwing: CancellationError())
        }
        waiters.removeAll()
        
        
        
        
    }
    
    /// Call when you want to reset buffer
    func reset() {
        buffer = .init()
        
        // Cancel any waiters
        for waiter in waiters {
            waiter.resume(throwing: CancellationError())
        }
        waiters.removeAll()
    }

    // MARK: - Core Production

    /// Ensures buffer stays filled. Can be called multiple times safely.
    private func ensureBufferFilled() async {
        // Prevent concurrent production
        guard !isProducing else { return }
        isProducing = true
        
        defer { isProducing = false }
        
        do {
            // Produce until buffer is full OR all waiters are satisfied
            while buffer.count < targetBufferSize || !waiters.isEmpty {
                try Task.checkCancellation()
                
                let chunk = try await produce()
                
                // First, satisfy any waiting consumers
                if !waiters.isEmpty {
                    let waiter = waiters.removeFirst()
                    waiter.resume(returning: chunk)
                } else {
                    // Otherwise, buffer it
                    buffer.push(chunk)
                }
                
                // Yield to allow other actor calls to process
                await Task.yield()
            }
        } catch {
            // Fail all waiters
            for waiter in waiters {
                waiter.resume(throwing: error)
            }
            waiters.removeAll()
        }
    }

    private func produce(wordIndex: Int? = nil) async throws -> SynthesizedChunk {
        try Task.checkCancellation()
        let text: String
        if let wordIndex {
            text = try await chunker.get(from: wordIndex)
        } else {
            text = try await chunker.getNext()
        }
        
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

@Observable
final class ReaderViewModel: @unchecked Sendable {
    private let player: StreamingAudioPlayer
    private let textLoader: TextLoader
    private let pipeline: Pipeline
    
//    private let synthQueue: AsyncBuffer<SynthesizedChunk>

    private var currentTask: Task<Void, Never>?
    
    @MainActor var status: ReaderStatus = .idle
    @MainActor var currentWordIndex: Int = 0
    @MainActor var errorMessage: String? = nil
    @ObservationIgnored private(set) var text: String = ""

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
    
    func onScrollChange() async -> String {
        guard let text = try? await textLoader.nextChunk() else { return "" }
        await MainActor.run {
            self.text += text
        }
        return text
    }

    func setup() async {
        await MainActor.run {
            self.status = .preparing
        }
        do {
            _ = await onScrollChange()
            try await self.pipeline.setup()
        } catch {
            await MainActor.run {
                self.status = .idle
            }
        }
        await MainActor.run {
            self.status = .idle
        }
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
        var isFirst: Bool = true
        do {
            while !Task.isCancelled {
                await MainActor.run {
                    self.status = .loading
                }
                
                let chunk: SynthesizedChunk = try await self.pipeline.next()
                
                await MainActor.run {
                    self.status = .reading
                }
                
                let chunkStartIndex = await self.currentWordIndex
                
                await withDiscardingTaskGroup { group in
                    group.addTask {
                        await self.player.queue(audio: chunk.audioData)
                    }
                    group.addTask {
                        let stream = await self.player.wordStream(words: chunk.content.words, audio: chunk.audioData)
                        for await wordIndex in stream {
                            await MainActor.run {
                                self.currentWordIndex = wordIndex + chunkStartIndex
                            }
                        }
                    }
                }
            }
        } catch is CancellationError  {
            await MainActor.run {
                self.status = .idle
            }
        } catch is ChunkingError {
            await MainActor.run {
                self.status = .restartable
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Unexpected error: \(error)"
            }
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
