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
    
    private var previousTail: [Int16] = []
    private var maxMagnitude: Float = 0.0
    private let crossfadeSamples = 240
    
    private let format: AVAudioFormat = .init(
        commonFormat: .pcmFormatInt16,
        sampleRate: 24000,
        channels: 1,
        interleaved: false
    )!
    
    init() {
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        engine.prepare()
        try? engine.start()
        playerNode.play()
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
        
        await playerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack)
    }
    
    private func duration(of data: Data) -> TimeInterval {
        let sampleRate = format.sampleRate
        let bytesPerFrame = Int(format.streamDescription.pointee.mBytesPerFrame)
        let totalFrames = data.count / bytesPerFrame
        let totalDuration = Double(totalFrames) / sampleRate
        return totalDuration
    }
    
    func wordStream(words: [String], audio data: Data) -> AsyncStream<Int> {
        let totalDuration = duration(of: data)
        let baseWordDuration = totalDuration / Double(max(words.count, 1))
        
        return AsyncStream { continuation in
            Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                var currentWordIndex = -1

                while true {
                    guard
                        await playerNode.isPlaying,
                        let nodeTime = await playerNode.lastRenderTime,
                        let playerTime = await playerNode.playerTime(forNodeTime: nodeTime)
                    else {
                        try? await Task.sleep(for: .milliseconds(50))
                        continue
                    }

                    let elapsedSeconds = Double(playerTime.sampleTime) / playerTime.sampleRate
                    let index = Int(elapsedSeconds / baseWordDuration)

                    if index != currentWordIndex, index < words.count {
                        currentWordIndex = index
                        continuation.yield(index)
                    }

                    // If finished
                    if elapsedSeconds >= totalDuration {
                        continuation.finish()
                        break
                    }

                    try? await Task.sleep(for: .milliseconds(50))
                }
            }
        }
    }
}
