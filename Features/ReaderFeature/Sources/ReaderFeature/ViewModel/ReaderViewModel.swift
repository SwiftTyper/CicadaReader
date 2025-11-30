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

@MainActor
@Observable
class ReaderViewModel {
    private let synthesizer: TtSManager
    private let player: StreamingAudioPlayer
    private let synthQueue: AsyncBuffer<SynthesizedChunk>
    private let chunker: TextChunker
    private let textLoader: TextLoader
    private let cache: AudioCache

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
        self.textLoader = TextLoader(url: contentUrl)
        let textChunker = TextChunker(text: "")
        self.chunker = textChunker
        self.synthesizer = synthesizer
        self.player = .init()
        let cache = AudioCache()
        self.cache = cache
        self.synthQueue = AsyncBuffer(
            targetSize: bufferAhead,
            produce: {
                try Task.checkCancellation()
                let text = try await textChunker.getNext()
                
                try Task.checkCancellation()
                let cacheKey = AudioCacheKey(text: text, rate: 1.0)
                let cachedAudio = await cache.retrieveData(for: cacheKey)

                if let cachedAudio {
                   return SynthesizedChunk(content: text, audioData: cachedAudio)
                }
                
                try Task.checkCancellation()
                let audio: Data = try await synthesizer.synthesize(text: text)
                try await cache.store(data: audio, for: cacheKey)
                return SynthesizedChunk(content: text, audioData: audio)
            }
        )
    }
    
    func onScrollChange() async -> String {
        guard let text = try? await textLoader.nextChunk() else { return "" }
        await MainActor.run {
            self.text += text
        }
        return text
    }

    @MainActor
    func setup() async {
        await self.setStatus(.preparing)
        do {
            self.text = try await textLoader.nextChunk()
            await self.chunker.rechunk(basedOn: self.text, and: self.currentWordIndex)
            try await synthesizer.initialize()
        } catch {
            await self.setStatus(.idle)
        }
        await self.setStatus(.idle)
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
                await self.setStatus(.loading)
                let chunk: SynthesizedChunk = try await self.synthQueue.next()
                await self.setStatus(.reading)
                
                let chunkStartIndex = await self.getWordIndex()
                
                let player = self.player
                let audioData = chunk.audioData
                let words = chunk.content.words
                let baseIndex = chunkStartIndex
                
                await withDiscardingTaskGroup { group in
                    group.addTask {
                        await player.queue(audio: audioData)
                    }
                    group.addTask { [baseIndex] in
                        let stream = await player.wordStream(words: words, audio: audioData)
                        for await wordIndex in stream {
                            await MainActor.run {
                                self.currentWordIndex = wordIndex + baseIndex
                            }
                        }
                    }
                }
            }
        } catch is CancellationError  {
            await self.setStatus(.idle)
        } catch is ChunkingError {
            await self.setStatus(.restartable)
        } catch {
            await self.setError(error.localizedDescription)
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
                await self.synthQueue.reset()
                await MainActor.run { self.currentWordIndex = start }
                await self.chunker.rechunk(basedOn: self.text, and: start)
                await read()
            }
              
        } else if self.status == .idle || self.status == .restartable {
            self.currentWordIndex = start
        }
    }
}
