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
    var isReading: Bool = false
   
    var wpm: Double = 240
    
    var currentWordIndex: Int = 0
    
    
    var interval: TimeInterval {
        max(0.05, 60.0 / max(1, wpm))
    }
    
    private var timer: AsyncTimer? = nil
  
    func toggleAutoRead() {
        self.isReading.toggle()
        if self.isReading {
            self.timer = AsyncTimer(interval: interval) { _ in
                self.timerTick()
            }
            self.timer?.start()
        } else {
            self.stopTimer()
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
            self.isReading = false
            self.stopTimer()
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
