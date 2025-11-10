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

@Observable
class ReaderViewModel {
    private let synthesizer: TtSManager
    private let player: StreamingAudioPlayer
    private let synthQueue: AsyncBuffer<SynthesizedChunk>
    private let chunker: TextChunker

    private var currentTask: Task<Void, Never>?
    private let text: String
    
    @MainActor var status: ReaderStatus = .idle
    @MainActor var currentWordIndex: Int = 0
    @MainActor var errorMessage: String? = nil

    init(
        synthesizer: TtSManager,
        text: String,
        bufferAhead: Int = 2,
    ) {
        self.text = text
        let textChunker = TextChunker(text: text)
        self.chunker = textChunker
        self.synthesizer = synthesizer
        self.player = .init()
        self.synthQueue = AsyncBuffer(
            targetSize: bufferAhead,
            produce: { [weak textChunker, weak synthesizer] in
                try Task.checkCancellation()
                
                guard
                    let textChunker = textChunker,
                    let synthesizer = synthesizer
                else { throw CancellationError() }
                
                let text = try await textChunker.getNext()
                try Task.checkCancellation()
                let audio: Data = try await synthesizer.synthesize(text: text)
                return SynthesizedChunk(content: text, audioData: audio)
            }
        )
    }

    func setup() async {
        self.status = .preparing
        do {
            try await synthesizer.initialize()
        } catch {
            self.status = .idle
        }
        self.status = .idle
    }
    
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
    
    private func read() async {
        do {
            while !Task.isCancelled {
                self.status = .loading
                let chunk: SynthesizedChunk = try await self.synthQueue.next()
                self.status = .reading
                
                let chunkStartIndex = self.currentWordIndex
                
                await withDiscardingTaskGroup { group in
                    group.addTask {
                        await self.player.queue(audio: chunk.audioData)
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
        } catch is TextChunker.ChunkingError {
            self.setStatus(.restartable)
        } catch {
            self.errorMessage = error.localizedDescription
        }
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
}

//MARK: Forward & Reverse Actions
extension ReaderViewModel {
    var canStepBack: Bool {
        TextService().startOfPreviousSentence(
            wordIndex: self.currentWordIndex,
            from: self.text
        ) != nil
    }
    
    var canStepForward: Bool {
        TextService().startOfNextSentence(
            wordIndex: self.currentWordIndex,
            from: self.text
        ) != nil
    }

    func skip(_ direction: SkipDirection) {
        let start: Int?
        if direction == .forward {
            start = TextService().startOfNextSentence(
                wordIndex: self.currentWordIndex,
                from: self.text
            )
        } else {
            start = TextService().startOfPreviousSentence(
                wordIndex: self.currentWordIndex,
                from: self.text
            )
        }
        guard let start else { return }
        
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
