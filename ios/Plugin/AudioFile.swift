//
//  AudioFile.swift
//  Plugin
//
//  Created by Austen Mack on 5/20/21.
//  Copyright © 2021 Max Lynch. All rights reserved.
//

import Foundation
import AVFoundation

public class AudioFile {
    public let engine: AVAudioEngine
    public let player: AVAudioPlayerNode = AVAudioPlayerNode()
    public let eq: AVAudioUnitEQ = AVAudioUnitEQ(numberOfBands: 3)
    public var _parent: Mixer
    public let playerMixer: AVAudioMixerNode = AVAudioMixerNode()
    public var playerQueue: DispatchQueue
    public var meterQueue: DispatchQueue
    
    public var audioFile: AVAudioFile?
    public var audioSampleRate: Double = 0
    public var audioLengthSeconds: Double = 0
    public var audioLengthSamples: AVAudioFramePosition = 0
    public var needsFileScheduled = true
    public var seekFrame: AVAudioFramePosition = 0
    public var listenerName: String = ""
    
    public var elapsedTime: TimeInterval = 0
    public var elapsedTimeEventName: String = ""
    
    init(parent: Mixer, audioId: String){
        _parent = parent
        engine = _parent.engine
        playerQueue = DispatchQueue(label: "mixerPlugin.audioFile.queue.\(audioId)", qos: .userInitiated)
        meterQueue = DispatchQueue(label: "mixerPlugin.audioMeter.queue.\(audioId)", qos: .userInitiated)
    }
    
    // MARK: setupAudio
    
    public func setupAudio(audioFilePath: NSURL, channelSettings: ChannelSettings) {
      do {
        let file = try AVAudioFile(forReading: audioFilePath as URL)
        let format = file.processingFormat
//        let newEqSettings = channelSettings.eqSettings
        
        audioLengthSamples = file.length
        audioSampleRate = format.sampleRate
        audioLengthSeconds = Double(audioLengthSamples) / audioSampleRate
        audioFile = file
        
        setupEq(with: format, channelSettings: channelSettings)
      } catch {
        print("Error reading the audio file: \(error.localizedDescription)")
      }
    }
    
    // MARK: setupEq
    public func setupEq(with format: AVAudioFormat, channelSettings: ChannelSettings) {
        let bassEq = eq.bands[0]
        bassEq.filterType = .lowShelf
        bassEq.frequency = channelSettings.eqSettings!.bassFrequency!
        bassEq.gain = channelSettings.eqSettings!.bassGain!
        bassEq.bypass = false
        
        let midEq = eq.bands[1]
        midEq.filterType = .parametric
        midEq.frequency = channelSettings.eqSettings!.midFrequency!
        midEq.bandwidth = 1
        midEq.gain = channelSettings.eqSettings!.midGain!
        midEq.bypass = false
        
        let trebleEq = eq.bands[2]
        trebleEq.filterType = .highShelf
        trebleEq.frequency = channelSettings.eqSettings!.trebleFrequency!
        trebleEq.gain = channelSettings.eqSettings!.trebleGain!
        trebleEq.bypass = false
        
        configureEngine(with: format, channelSettings: channelSettings)
    }
    
    // MARK: configureEngine
    public func configureEngine(with format: AVAudioFormat, channelSettings: ChannelSettings) {
        if (engine.isRunning) {
            engine.stop()
        }
        player.volume = 0.8
        playerMixer.outputVolume = channelSettings.volume!
        
        engine.attach(player)
        engine.attach(eq)
        engine.attach(playerMixer)
        
        if (channelSettings.channelListenerName != "") {
            listenerName = channelSettings.channelListenerName!
            player.removeTap(onBus: 0)
            player.installTap(onBus: 0, bufferSize: 1024, format: player.outputFormat(forBus: 0), block: handleMetering)
        }
        
        // TODO 7/2 : want to uninitialize a node (Deinit and deinit and deinit well)
        engine.connect(player, to: eq, format: format)
        engine.connect(eq, to: playerMixer, format: format)
        engine.connect(playerMixer, to: engine.mainMixerNode, format: playerMixer.outputFormat(forBus: 0))
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
        player.volume = 0.8
        player.scheduleFile(file, at: nil) {
            self.needsFileScheduled = true
            DispatchQueue.main.asyncAfter(deadline: .now()+1.0) {
                self.player.stop()
            }
        }
        // playOrPause()
    }
    
    // MARK: handleMetering
    public func handleMetering(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        // https://www.raywenderlich.com/21672160-avaudioengine-tutorial-for-ios-getting-started
        if (player.isPlaying) {
            meterQueue.async {
                guard let channelData = buffer.floatChannelData else { return }
                  
                let channelDataValue = channelData.pointee

                let channelDataValueArray = stride(
                  from: 0,
                  to: Int(buffer.frameLength),
                  by: buffer.stride)
                  .map { channelDataValue[$0] }
                  
                let rms = sqrt(channelDataValueArray.map {
                    return $0 * $0
                }
                .reduce(0, +) / Float(buffer.frameLength))
                  
                let avgPower = 20 * log10(rms)
        //          let meterLevel = self.scaledPower(power: avgPower)
                let response = avgPower < -80 ? -80 : avgPower

                self._parent.notifyListeners(self.listenerName, data: ["meterLevel": response])
            
                if (self.elapsedTimeEventName != "") {
                    self._parent.notifyListeners(self.elapsedTimeEventName, data: self.player.elapsedTimeSeconds.toDictionary())
                }
            }
        }
    }
    
    public func setElapsedTimeEvent(eventName: String) {
        elapsedTimeEventName = eventName
    }
    

    // MARK: Player Controls
    
    
    
    // MARK: playOrPause
    public func playOrPause() -> String {
        if (self.player.isPlaying) {
            self.player.pause()
            return "pause"
        } else {
            if (self.needsFileScheduled) {
                self.scheduleAudioFile()
            }
            playerQueue.async {
                self.player.play()
            }
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
        playerMixer.outputVolume = volume
    }
    
    // MARK: getCurrentVolume
    public func getCurrentVolume() -> Float {
        return playerMixer.outputVolume
    }
    
    // MARK: adjustEq
    public func adjustEq(type: String, gain: Float, freq: Float) {
        if(eq.bands.count < 1) {
            return
        }
        switch type {
        case "bass":
            let bassEq = eq.bands[0]
            bassEq.gain = gain
            bassEq.frequency = freq
            
        case "mid":
            let midEq = eq.bands[1]
            midEq.gain = gain
            midEq.frequency = freq
            
        case "treble":
            let trebleEq = eq.bands[2]
            trebleEq.gain = gain
            trebleEq.frequency = freq
            
        default:
            print("adjustEq: invalid eq type")
        }
    }
    
    // MARK: getCurrentEq
    public func getCurrentEq() -> [String: Float] {
        if(eq.bands.count < 1) {
            return [:]
        }
        let bassEq = eq.bands[0]
        let midEq = eq.bands[1]
        let trebleEq = eq.bands[2]
        
        return ["bassGain": bassEq.gain,
                "bassFreq": bassEq.frequency,
                "midGain": midEq.gain,
                "midFreq": midEq.frequency,
                "trebleGain": trebleEq.gain,
                "trebleFreq": trebleEq.frequency]
    }
    
    public func getElapsedTime() -> [String: Int] {
        if(player.elapsedTimeSeconds > elapsedTime) {
            elapsedTime = player.elapsedTimeSeconds
        }
        return elapsedTime.toDictionary()
    }
    
    public func getTotalTime() -> [String: Int] {
        return (audioFile?.totalDurationSeconds.toDictionary())!
    }
}

extension TimeInterval{

    func toDictionary() -> [String : Int] {

        let time = NSInteger(self)

        let milliSeconds = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)

        return [
            "milliSeconds": milliSeconds,
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
