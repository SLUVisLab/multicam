//
//  AudioService.swift
//  bii_multi_pheno_cam
//
//  Created by Developer on 5/18/22.
//

import Foundation
import AVKit

final class AudioService: ObservableObject {
//    static let shared = AudioService()
    var player: AVAudioPlayer?
    @Published private(set) var isPlaying: Bool = false {
        didSet {
            print("isPlaying", isPlaying)
        }
    }
    
    func start(track: String) {
        guard let url = Bundle.main.url(forResource: track, withExtension: "mp3") else {
            print("Resource not found: \(track)")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
            isPlaying = true
        } catch {
            print("Failed to initialize Audio Player")
        }
    }
    
    func stop(){
        guard let player = player else {
            print("instance of audio player not found")
            return
        }
        
        if player.isPlaying {
            player.stop()
            isPlaying = false
        }
    }
}
