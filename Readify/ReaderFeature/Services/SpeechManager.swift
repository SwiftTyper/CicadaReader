//
//  AudioPlayerManager.swift
//
//
//  Created by Wit Owczarek on 19/02/2024.
//

import Foundation
import AVFoundation
import SwiftUI

actor StreamingAudioPlayer {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let format: AVAudioFormat
    
    init(format: AVAudioFormat) {
        self.format = format
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        try? engine.start()
        playerNode.play()
    }
    
    func appendAudioData(_ data: Data) async {
        let frameCount = UInt32(data.count) / format.streamDescription.pointee.mBytesPerFrame
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        data.withUnsafeBytes { rawBufferPointer in
            if let baseAddress = rawBufferPointer.bindMemory(to: Int16.self).baseAddress {
                memcpy(buffer.int16ChannelData![0], baseAddress, Int(buffer.frameLength) * MemoryLayout<Int16>.size)
            }
        }
        
        await playerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack)
    }
}
//actor SpeechManager {
//    private var player: AVAudioPlayer?
//    
//    func configure() {
//        do {
//            let audioSession = AVAudioSession.sharedInstance()
//            try audioSession.setCategory(.playback, mode: .default)
//            try audioSession.setActive(true)
//        } catch {
//            
//        }
//    }
//    
//    func play(_ audio: Data) throws {
//        let player = try AVAudioPlayer(data: audio)
//        self.player = player
//        player.play()
//    }
    
    import AVFoundation

    actor SpeechManager: NSObject, AVAudioPlayerDelegate {
        private var player: AVAudioPlayer?
        private var continuation: CheckedContinuation<Void, any Error>?

        func configure() {
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .default)
                try audioSession.setActive(true)
            } catch {
                print("Audio session error:", error)
            }
        }

        func play(_ audio: Data) async throws {
            let player = try AVAudioPlayer(data: audio)
            player.delegate = self
            self.player = player
            player.play()
            
            // Suspend until delegate notifies playback ended
            try await withCheckedThrowingContinuation { cont in
                self.continuation = cont
            }
        }

        nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
            Task { [weak self] in
                guard let self else { return }
                await self.finishPlayback(success: flag)
            }
        }

        private func finishPlayback(success: Bool) {
            continuation?.resume(
//                throwing: success ? nil : NSError(domain: "SpeechManager", code: -1, userInfo: nil)
            )
            continuation = nil
            player = nil
        }

        func stop() {
            player?.stop()
            finishPlayback(success: false)
        }
    }
    
//    func say(_ sentence: String) async throws -> AsyncStream<Int> {
//        player?.stop()
//        guard !Task.isCancelled else { throw CancellationError() }
//
//        guard let data = try await tts?.synthesize(text: sentence) else {
//          throw SpeechError.missingData
//        }
//
//        let player = try AVAudioPlayer(data: data)
//        self.player = player
//        player.play()
//
//        let words = await sentence.words
//        guard !words.isEmpty else {
//          return AsyncStream { $0.finish() }
//        }
//
//        let totalDuration = player.duration
//        let baseWordDuration = totalDuration / Double(words.count)
//
//        return AsyncStream { continuation in
//          Task {
//              var currentWordIndex = -1
//              while player.isPlaying {
//                  let currentTime = player.currentTime
//                  let index = Int(currentTime / baseWordDuration)
//
//                  if index != currentWordIndex, index < words.count {
//                      currentWordIndex = index
//                      continuation.yield(index)
//                  }
//
//                  try? await Task.sleep(for: .milliseconds(50))
//              }
//              continuation.finish()
//          }
//        }
//    }
//    
//    func stop() {
//        player?.stop()
//    }
//}

//extension SpeechManager {
//    private enum SpeechError: Error {
//        case missingData
//    }
//}
