//
//  ReaderViewModel.swift
//  Readify
//
//  Created by Wit Owczarek on 24/10/2025.
//

import Foundation
import Observation

@Observable
class ReaderViewModel {
    init(book: Book) {
        self.book = book
    }
    
    let book: Book
    var isReading: Bool = false
    var currentWordIndex: Int = 0
    var wpm: Double = 240
    
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

extension Int {
    static let infinity = Int.max
}

final class AsyncTimer {
    private var task: Task<Void, Never>?
    private var currentCount: Int = 0
    private var interval: Double
    private var count: Int
    private let skipInitialDelay: Bool
    private let action: (Int) -> Void
    
    var isRunning: Bool { task != nil }
    
    init(
        interval: Double,
        count: Int = .infinity,
        skipInitialDelay: Bool = false,
        action: @escaping (Int) -> Void
    ) {
        self.interval = interval
        self.count = count
        self.skipInitialDelay = skipInitialDelay
        self.action = action
    }
    
    func start() {
        guard task == nil else { return }
        
        task = Task {
            while currentCount < count {
                if !skipInitialDelay || currentCount > 0 {
                    do {
                        try await Task<Never, Never>.sleep(for: .seconds(interval))
                    } catch {
                        break
                    }
                }
                
                currentCount += 1
                action(currentCount)
            }
            task = nil
        }
    }
    
    func stop() {
        task?.cancel()
        task = nil
    }
    
    func reset() {
        stop()
        currentCount = 0
    }
    
    func restart() {
        reset()
        start()
    }
    
    func updateInterval(_ newInterval: Double) {
        guard newInterval > 0 else { return }
        interval = newInterval
        if isRunning {
            restart()
        }
    }
    
    func updateCount(_ newCount: Int) {
        guard newCount > 0 else { return }
        count = newCount
        if isRunning && currentCount >= count {
            stop()
        }
    }
    
    deinit {
        stop()
    }
}

extension Task where Success == Void, Failure == Never {
    static func timer(
        interval: Double,
        count: Int = .infinity,
        skipInitialDelay: Bool = false,
        action: @escaping (Int) -> Void
    ) -> AsyncTimer {
        let timer = AsyncTimer(
            interval: interval,
            count: count,
            skipInitialDelay: skipInitialDelay,
            action: action
        )
        timer.start()
        return timer
    }
}
