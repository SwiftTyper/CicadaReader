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


//FIFO
struct Stack<T> {
    init() { values = [] }
    
    private var values: [T]
    
    mutating func pop() -> T? {
        return values.remove(at: 0)
    }
    
    mutating func push(_ value: T) {
        values.append(value)
    }
    
    var isEmpty: Bool {
        values.isEmpty
    }
}

class Pipeline {
    init(chunker: TextChunker) {
        self.cache = .init()
        self.chunker = chunker
        self.synthesizer = .init()
    }
    
    private let cache: AudioSynthesisCache
    private let chunker: TextChunker
    private let synthesizer: TtSManager
    
    var buffer: Stack<SynthesizedChunk> = .init()
    
    func next() async throws -> SynthesizedChunk? {
        guard buffer.isEmpty else {
            return buffer.pop()
        }
        
        //await the next value from the buffer it should be a stream
    }
    
    func produce() async throws -> SynthesizedChunk {
        try Task.checkCancellation()
        let text = try await chunker.getNext()
        
        try Task.checkCancellation()
        let cacheKey: AudioCacheKey = .init(text: text, rate: 1.0)
        let cachedAudio: Data? = await cache.retrieveData(for: cacheKey)
        
        guard cachedAudio == nil else {
            return SynthesizedChunk(content: text, audioData: cachedAudio!)
        }
        
        try Task.checkCancellation()
        let audio: Data = try await synthesizer.synthesize(text: text)
        
        try await cache.store(data: audio, for: cacheKey)
        
        return SynthesizedChunk(content: text, audioData: audio)
    }
}

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
    @MainActor var text: String = ""

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
    
    @MainActor
    func onScrollChange() async {
        guard let text = try? await textLoader.nextChunk() else { return }
        self.text += text
    }

    @MainActor
    func setup() async {
        self.setStatus(.preparing)
        do {
            self.text = try await textLoader.nextChunk()
            await self.chunker.rechunk(basedOn: self.text, and: self.currentWordIndex)
            try await synthesizer.initialize()
        } catch {
            self.setStatus(.idle)
        }
        self.setStatus(.idle)
    }
    
    @MainActor
    func toggleAutoRead() {
        self.status.toggle()
        
        if self.status == .restartable {
            self.setWordIndex(0)
            self.currentTask = Task {
                await self.chunker.rechunk(basedOn: self.text, and: self.currentWordIndex)
                await read()
            }
            return
        }
        
        if self.status == .reading {
            let previousTask = self.currentTask
            previousTask?.cancel()
            self.currentTask = Task { [previousTask] in
                _ = await previousTask?.value
                await self.synthQueue.reset()
                await self.chunker.rechunk(basedOn: self.text, and: self.currentWordIndex)
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
                setStatus(.loading)
                let chunk: SynthesizedChunk = try await self.synthQueue.next()
                setStatus(.reading)
                
                let chunkStartIndex = self.getWordIndex()
                
                await withDiscardingTaskGroup { group in
                    group.addTask { [player] in
                        await player.queue(audio: chunk.audioData)
                    }
                    
                    group.addTask {
                        let stream = await self.player.wordStream(words: chunk.content.words, audio: chunk.audioData)
                        for await wordIndex in stream {
                            await self.setWordIndex(wordIndex + chunkStartIndex)
                        }
                    }
                }
            }
        } catch is CancellationError  {
            self.setStatus(.idle)
        } catch is ChunkingError {
            self.setStatus(.restartable)
        } catch {
            self.setError(error.localizedDescription)
        }
    }
    
    @MainActor
    func setError(_ value: String) {
        self.errorMessage = value
    }
    
    @MainActor
    private func setStatus(_ value: ReaderStatus) {
        print(value)
        self.status = value
    }
    
    @MainActor
    private func setWordIndex(_ value: Int) {
        print(value)
        self.currentWordIndex = value
    }
    
    @MainActor
    private func getWordIndex() -> Int {
        self.currentWordIndex
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
                await synthQueue.reset()
                setWordIndex(start)
                await self.chunker.rechunk(basedOn: self.text, and: start)
                await read()
            }
              
        } else if self.status == .idle || self.status == .restartable {
            self.currentWordIndex = start
        }
    }
}



