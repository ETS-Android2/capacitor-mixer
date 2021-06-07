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
    
    public let micMixer: AVAudioMixerNode = AVAudioMixerNode()
    
    public var tempTimer: Timer = Timer()
    public var elapsedTime: TimeInterval = 0
    public var elapsedTimeEventName: String = ""
    
    init(){
        player.volume = 1.0
    }
    
    // MARK: setupAudio
    
    public func setupAudio(audioFilePath: NSURL, eqSettings: EqSettings) {
      do {
        let file = try AVAudioFile(forReading: audioFilePath as URL)
        let format = file.processingFormat
        let newEqSettings = eqSettings
        
        audioLengthSamples = file.length
        audioSampleRate = format.sampleRate
        audioLengthSeconds = Double(audioLengthSamples) / audioSampleRate
        audioFile = file
        
        setupEQ(with: format, eqSettings: newEqSettings)
      } catch {
        print("Error reading the audio file: \(error.localizedDescription)")
      }
    }
    
    // MARK: setupEQ
    public func setupEQ(with format: AVAudioFormat, eqSettings: EqSettings) {
        let bassEQ = eq.bands[0]
        bassEQ.filterType = .lowShelf
        bassEQ.frequency = eqSettings.bassFrequency!
        bassEQ.gain = eqSettings.bassGain!
        bassEQ.bypass = false
        
        let midEQ = eq.bands[1]
        midEQ.filterType = .parametric
        midEQ.frequency = eqSettings.midFrequency!
        midEQ.bandwidth = 1
        midEQ.gain = eqSettings.midGain!
        midEQ.bypass = false
        
        let trebleEQ = eq.bands[2]
        trebleEQ.filterType = .highShelf
        trebleEQ.frequency = eqSettings.trebleFrequency!
        trebleEQ.gain = eqSettings.trebleGain!
        trebleEQ.bypass = false
        
        configureEngine(with: format)
    }
    
    // MARK: configureEngine
    public func configureEngine(with format: AVAudioFormat) {
//        let micInput = engine.inputNode
//        let micFormat = micInput.inputFormat(forBus: 0)
        engine.attach(player)
        engine.attach(eq)
        engine.attach(micMixer)
      
        engine.connect(player, to: eq, format: format)
        engine.connect(eq, to: engine.mainMixerNode, format: format)
//        engine.connect(micInput, to: micMixer, format: micFormat)
//        engine.connect(micMixer, to: engine.mainMixerNode, format: format)
        engine.prepare()
      
      do {
        try engine.start()
        
        scheduleAudioFile()
//        isPlayerReady = true
      } catch {
        print("Error starting the player: \(error.localizedDescription)")
      }
    }
    
    // MARK: scheduleAudioFile
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
    
    @objc func tempUpdateNumber(timer: Timer) {
        let timerInfo: TimerInfo = timer.userInfo as! TimerInfo
        var dataDictionary: [String: TimeInterval] = [:]
        
        if(player.currentElapsedTime > elapsedTime) {
            elapsedTime = player.currentElapsedTime
            dataDictionary["seconds"] = elapsedTime
            timerInfo.mixer!.notifyListeners(timerInfo.eventName!, data: dataDictionary)
        }
    }
    
    public func setElapsedTimeEvent(eventName: String, mixer: Mixer) {
        let timerInfo: TimerInfo = TimerInfo()
        timerInfo.eventName = eventName
        timerInfo.mixer = mixer
        
        elapsedTimeEventName = eventName
        
        DispatchQueue.main.async {
            self.tempTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.tempUpdateNumber), userInfo: timerInfo, repeats: true)
        }
    }
    
    @objc func elapsedTimeEvent(timer: Timer) {
        let timerInfo: TimerInfo = timer.userInfo as! TimerInfo
        var dataDictionary: [String: Double] = [:]
        if let nodeTime: AVAudioTime = player.lastRenderTime, let playerTime: AVAudioTime = player.playerTime(forNodeTime: nodeTime) {
               dataDictionary["value"] = Double(Double(playerTime.sampleTime) / playerTime.sampleRate)
            }
        else {
            dataDictionary["value"] = 0
        }
//        dataDictionary["value"] = seconds
        timerInfo.mixer!.notifyListeners(timerInfo.eventName!, data: dataDictionary)
    }
    

    // MARK: Player Controls
    
    
    
    // MARK: playOrPause
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
    // MARK: stop
    public func stop() -> String {
        elapsedTime = 0
        player.stop()
        return "stop"
//        needsFileScheduled = true
    }
    
    // MARK: isPlaying
    public func isPlaying() -> Bool {
        return player.isPlaying
    }
    
    // MARK: adjustVolume
    public func adjustVolume(volume: Float) {
        player.volume = volume
    }
    
    // MARK: getCurrentVolume
    public func getCurrentVolume() -> Float {
        return player.volume
    }
    
    // MARK: adjustEQ
    public func adjustEQ(type: String, gain: Float, freq: Float) {
        if(eq.bands.count < 1) {
            return
        }
        switch type {
        case "bass":
            let bassEQ = eq.bands[0]
            bassEQ.gain = gain
            bassEQ.frequency = freq
            
        case "mid":
            let midEQ = eq.bands[1]
            midEQ.gain = gain
            midEQ.frequency = freq
            
        case "treble":
            let trebleEQ = eq.bands[2]
            trebleEQ.gain = gain
            trebleEQ.frequency = freq
            
        default:
            print("adjustEQ: invalid eq type")
        }
    }
    
    // MARK: getCurrentEQ
    public func getCurrentEQ() -> [String: Float] {
        if(eq.bands.count < 1) {
            return [:]
        }
        let bassEQ = eq.bands[0]
        let midEQ = eq.bands[1]
        let trebleEQ = eq.bands[2]
        
        return ["bassGain": bassEQ.gain,
                "bassFreq": bassEQ.frequency,
                "midGain": midEQ.gain,
                "midFreq": midEQ.frequency,
                "trebleGain": trebleEQ.gain,
                "trebleFreq": trebleEQ.frequency]
    }
    
    public func getElapsedTime() -> [String: Int] {
        if(player.elapsedTimeSeconds > elapsedTime) {
            elapsedTime = player.elapsedTimeSeconds
        }
        return elapsedTime.stringFromTimeInterval()
    }
}

extension TimeInterval{

    func stringFromTimeInterval() -> [String : Int] {

        let time = NSInteger(self)

        let miliSeconds = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)

        return [
            "miliSeconds": miliSeconds,
            "seconds": seconds,
            "minutes": minutes,
            "hours": hours
        ]

    }
}

extension AVAudioFile {

    var totalDurationSeconds: TimeInterval {
        let sampleRateSong = Double(processingFormat.sampleRate)
        let lengthSongSeconds = Double(length) / sampleRateSong
        return lengthSongSeconds
    }
}

extension AVAudioPlayerNode {
    
    private struct currentelapsed {
        static var time: TimeInterval = 0
    }
    
    var currentElapsedTime: TimeInterval {
        get {
            guard let time = objc_getAssociatedObject(self, &currentelapsed.time) as? TimeInterval else {
                return 0
            }
            return time
        }
        set {
            objc_setAssociatedObject(self, &currentelapsed.time, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    var elapsedTimeSeconds: TimeInterval {
        if let nodeTime = lastRenderTime, let playerTime = playerTime(forNodeTime: nodeTime) {
            return Double(playerTime.sampleTime) / playerTime.sampleRate
        }
        return 0
    }
    
}
