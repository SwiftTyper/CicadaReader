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
    private let synthQueue: AsyncBuffer<SynthesizedChunk?>
    
    private let text: String
    private var currentTask: Task<Void, Never>?
    
    var status: ReaderStatus = .idle
    var currentWordIndex: Int = 0

    init(
        synthesizer: TtSManager,
        text: String,
        bufferAhead: Int = 2,
    ) {
        self.text = text
        let chunker = TextChunker(text: text)
        self.synthesizer = synthesizer
        self.synthQueue = AsyncBuffer(
            targetSize: bufferAhead,
            produce: {
                guard let text = await chunker.getNext() else { return nil }
                guard let audio = try? await synthesizer.synthesize(text: text) else { return nil }
                return SynthesizedChunk(content: text, audioData: audio)
            }
        )
        self.player = StreamingAudioPlayer()
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
        
        if self.status == .reading {
            self.currentTask = Task {
                await read()
            }
        } else if self.status == .idle {
            self.currentTask?.cancel()
        }
    }

    private func read() async {
        // handle errors
        guard let chunk = try? await synthQueue.next() else { return }
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
       
        await read()
    }
    
    @MainActor
    func setWordIndex(value: Int) {
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
        self.currentWordIndex = start
    }

    func stepForward() {
        let end = TextService().startOfNextSentence(
            wordIndex: self.currentWordIndex,
            from: self.text
        )
        guard let end = end else { return }
        self.currentWordIndex = end
    }
}
