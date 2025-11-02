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
import TTSFeature

actor StreamingAudioPlayer {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let format: AVAudioFormat!

    private var previousTail: [Int16] = []
    private var maxMagnitude: Float = 0.0
    private let crossfadeSamples = 240
    
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
    }
    
    func queue(audio data: Data) async {
        // Convert incoming PCM16 data to buffer
        let frameCount = UInt32(data.count) / format.streamDescription.pointee.mBytesPerFrame
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        data.withUnsafeBytes { rawBufferPointer in
            guard let baseAddress = rawBufferPointer.bindMemory(to: Int16.self).baseAddress else { return }
            memcpy(buffer.int16ChannelData![0], baseAddress, Int(buffer.frameLength) * MemoryLayout<Int16>.size)
        }
        
        // Convert Int16 samples to Float for DSP
        let count = Int(buffer.frameLength)
        var floatSamples = [Float](repeating: 0, count: count)
        buffer.int16ChannelData![0].withMemoryRebound(to: Int16.self, capacity: count) { src in
            vDSP_vflt16(src, 1, &floatSamples, 1, vDSP_Length(count))
        }
        
        // Normalize to [-1, 1]
        var localMax: Float = 0
        vDSP_maxmgv(floatSamples, 1, &localMax, vDSP_Length(count))
        if localMax > 0 { vDSP_vsdiv(floatSamples, 1, &localMax, &floatSamples, 1, vDSP_Length(count)) }
        
        // Update global amplitude normalization
        maxMagnitude = max(maxMagnitude, localMax)
        if maxMagnitude > 0 {
            var divisor = maxMagnitude
            vDSP_vsdiv(floatSamples, 1, &divisor, &floatSamples, 1, vDSP_Length(count))
        }
        
        // --- CROSSFADE WITH PREVIOUS CHUNK ---
        if !previousTail.isEmpty {
            let n = min(crossfadeSamples, previousTail.count, floatSamples.count)
            if n > 0 {
                var fadeIn = [Float](repeating: 0, count: n)
                var start: Float = 0
                var step: Float = 1.0 / Float(n - 1)
                vDSP_vramp(&start, &step, &fadeIn, 1, vDSP_Length(n))
                
                var fadeOut = [Float](repeating: 1, count: n)
                vDSP_vsub(fadeIn, 1, fadeOut, 1, &fadeOut, 1, vDSP_Length(n))
                
                // Blend previous tail and next head
                var tailFloats = [Float](repeating: 0, count: n)
                vDSP_vflt16(previousTail.suffix(n), 1, &tailFloats, 1, vDSP_Length(n))
                
                vDSP_vmul(tailFloats, 1, fadeOut, 1, &tailFloats, 1, vDSP_Length(n))
                vDSP_vma(floatSamples, 1, fadeIn, 1, tailFloats, 1, &tailFloats, 1, vDSP_Length(n))
                
                // Replace next head with blended region
                tailFloats.withUnsafeBufferPointer { ptr in
                    guard let base = ptr.baseAddress else { return }
                    vDSP_vfixr16(base, 1, buffer.int16ChannelData![0], 1, vDSP_Length(n))
                }
            }
        }
        
        // Save tail for next crossfade
        let tailN = min(crossfadeSamples, count)
        previousTail = Array(UnsafeBufferPointer(start: buffer.int16ChannelData![0], count: count).suffix(tailN))
        
        if !playerNode.isPlaying {
            self.playerNode.play()
        }
        
        await playerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack)
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
            Task { [weak self] in
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
        }
    }
}
