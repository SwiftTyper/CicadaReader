//
//  ReaderViewModel.swift
//  Readify
//
//  Created by Wit Owczarek on 24/10/2025.
//

import Foundation
import Observation
import SwiftUI
import TTSFeature

@Observable
class ReaderViewModel {
    private let synthesizer: TtSManager
    private let player: StreamingAudioPlayer
    private let synthQueue: AsyncBuffer<SynthesizedChunk>
    
    private let text: String
    private var currentTask: Task<Void, Never>?
    private var chunker: TextChunker
    
    var status: ReaderStatus = .idle
    var currentWordIndex: Int = 0

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
            produce: {
                try Task.checkCancellation()
                let text = try await textChunker.getNext()
                try Task.checkCancellation()
                let audio = try await synthesizer.synthesize(text: text)
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
            self.cancelRead()
            self.setWordIndex(value: 0)
            self.status = .reading
        }
        
        if self.status == .reading {
            startRead()
        } else if self.status == .idle {
            print(self.text.words[currentWordIndex])
            cancelRead()
        }
    }
    
    private func startRead() {
        self.currentTask = Task {
            do {
                try await read()
            } catch is CancellationError  {
                self.status = .idle
            } catch is TextChunker.ChunkingError {
                self.status = .restartable
            } catch {
                //show error
            }
        }
    }
    
    private func cancelRead() {
        self.currentTask?.cancel()
        Task {
            await self.synthQueue.reset()
            await self.chunker.rechunk(basedOn: self.text, and: self.currentWordIndex)
        }
    }

    private func read() async throws {
        guard Task.isCancelled == false else { return }
        
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
                    await self.setWordIndex(value: wordIndex + chunkStartIndex)
                }
            }
        }
       
        try await self.read()
    }
    
    @MainActor
    private func setWordIndex(value: Int) {
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

    func stepBack() {
        let start = TextService().startOfPreviousSentence(
            wordIndex: self.currentWordIndex,
            from: self.text
        )
        guard let start else { return }
        
        if self.status == .reading || self.status == .restartable {
            self.currentTask?.cancel()
            self.currentTask = Task {
                await synthQueue.reset()
                await setWordIndex(value: start)
                await self.chunker.rechunk(basedOn: self.text, and: self.currentWordIndex)
                do {
                    try await read()
                } catch is CancellationError  {
                    self.status = .idle
                } catch is TextChunker.ChunkingError {
                    self.status = .restartable
                } catch {
                    //show error
                }
            }
        } else if self.status == .idle {
            self.currentWordIndex = start
        }
    }

    func stepForward() {
        let end = TextService().startOfNextSentence(
            wordIndex: self.currentWordIndex,
            from: self.text
        )
        guard let end = end else { return }

        if self.status == .reading || self.status == .restartable {
            self.currentTask?.cancel()
            self.currentTask = Task {
                await synthQueue.reset()
                await setWordIndex(value: end)
                await self.chunker.rechunk(basedOn: self.text, and: self.currentWordIndex)
                do {
                    try await read()
                } catch is CancellationError  {
                    self.status = .idle
                } catch is TextChunker.ChunkingError {
                    self.status = .restartable
                } catch {
                    //show error
                }
            }
        } else if self.status == .idle {
            self.currentWordIndex = end
        }
    }
}
