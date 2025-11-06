//
//  AudioPlayerManager.swift
//
//
//  Created by Wit Owczarek on 19/02/2024.
//

import Foundation
import AVFoundation
import SwiftUI
import Accelerate

actor StreamingAudioPlayer {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let format: AVAudioFormat!
    
    init() {
        self.format = .init(
            commonFormat: .pcmFormatInt16,
            sampleRate: 24000,
            channels: 1,
            interleaved: false
        )
        self.engine.attach(self.playerNode)
        self.engine.connect(self.playerNode, to: self.engine.mainMixerNode, format: self.format)
        self.engine.prepare()
        
        do {
            try self.engine.start()
        } catch {
            //MARK: not sure to do about it yet
        }
        
        self.playerNode.play()
    }
    
    func queue(audio data: Data) async {
        let data = stripWavHeader(data)
        let frameCount = UInt32(data.count) / format.streamDescription.pointee.mBytesPerFrame
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        data.withUnsafeBytes { rawBufferPointer in
            guard let baseAddress = rawBufferPointer.bindMemory(to: Int16.self).baseAddress else { return }
            memcpy(buffer.int16ChannelData![0], baseAddress, Int(buffer.frameLength) * MemoryLayout<Int16>.size)
        }
        
        if Task.isCancelled { return }
        
        if !playerNode.isPlaying {
            playerNode.play()
        }
        
        await withTaskCancellationHandler {
            _ = await playerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack)
        } onCancel: {
            self.playerNode.stop()
            self.playerNode.reset()
        }
    }
    
    private func stripWavHeader(_ data: Data) -> Data {
        if data.prefix(4) == Data("RIFF".utf8) {
            return data.dropFirst(44)
        } else {
            return data
        }
    }
}

extension StreamingAudioPlayer {
    func wordStream(words: [String], audio data: Data) -> AsyncStream<Int> {
        let totalDuration = duration(of: data)
        let totalNumberOfLetters = Double(words.reduce(0) { $0 + $1.count }) + Double(words.count - 1)
        let baseLetterDuration = totalDuration / totalNumberOfLetters
        let wordDurations = words.map {
            if words.last == $0 {
                Double($0.count) * baseLetterDuration
            } else {
                Double($0.count+1) * baseLetterDuration
            }
        }
        
        return AsyncStream { continuation in
            let task = Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                var chunkStartTime: TimeInterval? = nil
                var previousIndex: Int? = nil

                while true {
                    guard
                        await playerNode.isPlaying,
                        let elapsedSeconds = await getCurrentElapsedTime()
                    else {
                        try? await Task.sleep(for: .milliseconds(50))
                        continue
                    }

                    if chunkStartTime == nil {
                        chunkStartTime = elapsedSeconds
                        continue
                    }

                    let relativeTime = elapsedSeconds - chunkStartTime!
                    
                    var index: Int = 0
                    var sum: Double = 0
                    for duration in wordDurations {
                        index += 1
                        sum += duration
                        if sum >= relativeTime {
                            break
                        }
                    }

                    if previousIndex != index && index < words.count {
                        previousIndex = index
                        continuation.yield(index+1)
                    }

                    if relativeTime >= totalDuration {
                        continuation.finish()
                        break
                    }

                    try? await Task.sleep(for: .milliseconds(25))
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    private func duration(of data: Data) -> TimeInterval {
        let bytesPerFrame = Int(format.streamDescription.pointee.mBytesPerFrame)
        let totalFrames = data.count / bytesPerFrame
        let sampleRate = format.sampleRate
        let totalDuration = Double(totalFrames) / sampleRate
        return totalDuration
    }
    
    private func getCurrentElapsedTime() -> TimeInterval? {
        guard
            let nodeTime = playerNode.lastRenderTime,
            let playerTime = playerNode.playerTime(forNodeTime: nodeTime)
        else { return nil }
        return Double(playerTime.sampleTime) / playerTime.sampleRate
    }
}
