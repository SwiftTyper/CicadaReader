//
//  ReaderViewModel.swift
//  Readify
//
//  Created by Wit Owczarek on 24/10/2025.
//

import Foundation
import Observation
import SwiftUI

@Observable
class ReaderViewModel {
    init(book: Book) {
        self.book = book
    }
    
    let book: Book
    let speech: SpeechManager = .init()
    
    var status: Status = .idle
    var wpm: Double = 240
    var currentWordIndex: Int = 0
    
    var interval: TimeInterval {
        max(0.05, 60.0 / max(1, wpm))
    }
    
    private var timer: AsyncTimer? = nil
    
  
    func toggleAutoRead() {
        self.status.toggle()
        if self.status == .reading {
            let sentence = TextService().getCurrentSentence(wordIndex: currentWordIndex, from: book.content)
            guard let sentence else { return }
            let sentenceStart = currentWordIndex
            Task {
                do {
                    for await wordIndex in try await speech.say(sentence) {
                        self.currentWordIndex = sentenceStart + wordIndex
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
            
//            self.timer = AsyncTimer(interval: interval) { _ in
//                self.timerTick()
//            }
//            self.timer?.start()
        } else {
//            self.stopTimer()
        }
    }
    
    private func stopTimer() {
        self.timer?.stop()
        self.timer = nil
    }
    
    private func timerTick() {
        if self.currentWordIndex < book.content.words.count - 1 {
            self.currentWordIndex += 1
        } else {
            self.status = .idle
            self.stopTimer()
        }
    }
}

extension ReaderViewModel {
    enum Status {
        case reading
        case idle
        case loading
        
        mutating func toggle() {
            if self == .reading {
                self = .idle
            } else {
                self = .reading
            }
        }
    }
}

//MARK: Forward & Reverse Actions
extension ReaderViewModel {
    var canStepBack: Bool {
        TextService().startOfPreviousSentence(
            wordIndex: currentWordIndex,
            from: book.content
        ) != nil
    }
    
    var canStepForward: Bool {
        TextService().startOfNextSentence(
            wordIndex: currentWordIndex,
            from: book.content
        ) != nil
    }

    func stepBack() {
        let start = TextService().startOfPreviousSentence(
            wordIndex: currentWordIndex,
            from: book.content
        )
        guard let start else { return }
        self.currentWordIndex = start
    }

    func stepForward() {
        let end = TextService().startOfNextSentence(
            wordIndex: currentWordIndex,
            from: book.content
        )
        guard let end = end else { return }
        self.currentWordIndex = end
    }
}
