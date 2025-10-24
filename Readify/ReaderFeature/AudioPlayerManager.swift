//
//  AudioPlayerManager.swift
//
//
//  Created by Wit Owczarek on 19/02/2024.
//

import Foundation
import AVFoundation
import SwiftUI

class AudioPlayerManager {
    static let shared = AudioPlayerManager()
//    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var player: AVAudioPlayer?
    
    private init() { configure() }
    deinit { stopAllAudio() }
    
//    func play(_ file: File) {
//        if file == .background {
//            self.playSound(named: "background", numberOfLoops: -1, volume: 0.1)
//        } else {
//            self.playSound(named: file.rawValue, withExtension: file.getExtension())
//        }
//    }
//    
//    func stopAudio(_ file: File) {
//        audioPlayers[file.rawValue]?.stop()
//        audioPlayers.removeValue(forKey: file.rawValue)
//    }
//    
    func stopAllAudio() {
        player?.stop()
//        audioPlayers.values.forEach { $0.stop() }
//        audioPlayers.removeAll()
    }
}

extension AudioPlayerManager {
    private func configure() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                options: [.mixWithOthers, .duckOthers]
            )
            
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error while configuring audio session: \(error.localizedDescription)")
        }
    }
    
    func playSound(
        data: Data,
        volume: Float = 1.0
    ) {
        do {
            self.player = try AVAudioPlayer(data: data)
            player?.numberOfLoops = 1
            player?.volume = volume
            player?.prepareToPlay()
            player?.play()
            
        } catch {
            print("Error playing sound : \(error.localizedDescription)")
        }
    }
}
