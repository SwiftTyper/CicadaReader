//
//  AudioPlayerManager.swift
//
//
//  Created by Wit Owczarek on 19/02/2024.
//

import Foundation
import AVFoundation
import SwiftUI
import TTSFeature

actor SpeechManager {
    private var player: AVAudioPlayer?
    private var tts: TtSManager?
    
    func configure() async throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playback, mode: .default)
        try audioSession.setActive(true)
        guard !Task.isCancelled else { return }
        self.tts = .init()
        try await tts?.initialize()
    }
    
    func say(_ sentence: String) async throws -> AsyncStream<Int> {
        player?.stop()
        guard !Task.isCancelled else { throw CancellationError() }

        guard let data = try await tts?.synthesize(text: sentence) else {
          throw SpeechError.missingData
        }

        let player = try AVAudioPlayer(data: data)
        self.player = player
        player.play()

        let words = await sentence.words
        guard !words.isEmpty else {
          return AsyncStream { $0.finish() }
        }

        let totalDuration = player.duration
        let baseWordDuration = totalDuration / Double(words.count)

        return AsyncStream { continuation in
          Task {
              var currentWordIndex = -1
              while player.isPlaying {
                  let currentTime = player.currentTime
                  let index = Int(currentTime / baseWordDuration)

                  if index != currentWordIndex, index < words.count {
                      currentWordIndex = index
                      continuation.yield(index)
                  }

                  try? await Task.sleep(for: .milliseconds(50))
              }
              continuation.finish()
          }
        }
    }
    
    func stop() {
        player?.stop()
    }
}

extension SpeechManager {
    private enum SpeechError: Error {
        case missingData
    }
}
