//
//  AudioFile.swift
//  Plugin
//
//  Created by Austen Mack on 5/20/21.
//  Copyright © 2021 Max Lynch. All rights reserved.
//

import Foundation
import AVFoundation

public class MyAudioFile {
    public let engine: AVAudioEngine = AVAudioEngine()
    public let player: AVAudioPlayerNode = AVAudioPlayerNode()
    public let eq: AVAudioUnitEQ = AVAudioUnitEQ(numberOfBands: 3)
    public var audioFile: AVAudioFile?
    public var audioSampleRate: Double = 0
    public var audioLengthSeconds: Double = 0
    public var audioLengthSamples: AVAudioFramePosition = 0
    public var needsFileScheduled = true
    public var seekFrame: AVAudioFramePosition = 0
    
    init(){
        player.volume = 1.0
    }
    
    // MARK: Setup
    
    public func setupAudio(audioFilePath: NSURL) {
      do {
        let file = try AVAudioFile(forReading: audioFilePath as URL)
        let format = file.processingFormat
        
        audioLengthSamples = file.length
        audioSampleRate = format.sampleRate
        audioLengthSeconds = Double(audioLengthSamples) / audioSampleRate
        audioFile = file
        
        setupEQ(with: format)
      } catch {
        print("Error reading the audio file: \(error.localizedDescription)")
      }
    }
    
    public func setupEQ(with format: AVAudioFormat) {
        let lowEndEQ = eq.bands[0]
        lowEndEQ.filterType = .lowShelf
        lowEndEQ.frequency = 150.0
        lowEndEQ.gain = 0.0
        lowEndEQ.bypass = false
        
        let midEQ = eq.bands[1]
        midEQ.filterType = .parametric
        midEQ.frequency = 1200.0
        midEQ.bandwidth = 0.35
        midEQ.gain = 0.0
        midEQ.bypass = false
        
        let highEndEQ = eq.bands[2]
        highEndEQ.filterType = .highShelf
        highEndEQ.frequency = 10000.0
        highEndEQ.gain = 0.0
        highEndEQ.bypass = false
        
        configureEngine(with: format)
    }
    
    public func configureEngine(with format: AVAudioFormat) {
        engine.attach(player)
        engine.attach(eq)
      
        engine.connect(player, to: eq, format: format)
        engine.connect(eq, to: engine.mainMixerNode, format: format)
        engine.prepare()
      
      do {
        try engine.start()
        
        scheduleAudioFile()
//        isPlayerReady = true
      } catch {
        print("Error starting the player: \(error.localizedDescription)")
      }
    }
    
    public func scheduleAudioFile() {
      guard let file = audioFile, needsFileScheduled else {
        return
      }
      
        needsFileScheduled = false
        seekFrame = 0
        player.volume = 1
        player.scheduleFile(file, at: nil) {
        self.needsFileScheduled = true
      }
        // playOrPause()
    }
    
    // MARK: Player Controls
    
    public func playOrPause() -> String {
        if (player.isPlaying) {
            player.pause()
            return "pause"
        } else {
          if (needsFileScheduled) {
            scheduleAudioFile()
          }
            player.play()
            return "play"
        }
    }
    
    public func stop() -> String {
        player.stop()
        return "stop"
//        needsFileScheduled = true
        // TODO: find out why playing after stop is quieter than initial play
    }
    
    public func isPlaying() -> Bool {
        return player.isPlaying
    }
    
    public func adjustVolume(volume: Float) {
        player.volume = volume
    }
    
    public func getCurrentVolume() -> Float {
        return player.volume
    }
    
    public func adjustEQ(type: String, gain: Float, freq: Float) {
        switch type {
        case "bass":
            let lowEndEQ = eq.bands[0]
            lowEndEQ.gain = gain
            lowEndEQ.frequency = freq
            
        case "mid":
            let midEQ = eq.bands[1]
            midEQ.gain = gain
            midEQ.frequency = freq
            
        case "high":
            let highEndEQ = eq.bands[2]
            highEndEQ.gain = gain
            highEndEQ.frequency = freq
            
        default:
            print("adjustEQ: invalid eq type")
        }
    }
}
