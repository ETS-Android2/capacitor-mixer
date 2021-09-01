//
//  AudioFile.swift
//  Plugin
//
//  Created by Skylabs Technology on 5/20/21.
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
    
    /**
     * Starts initialization of a player. Configures player then starts its listeners
     *
     * @param audioFilePath
     * @param channelSettings
     */
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
        // print("Error reading the audio file: \(error.localizedDescription)")
      }
    }
    
    /**
     * Sets up EQ and attaches it to player
     *
     * @param channelSettings
     */
    // MARK: setupEq
    private func setupEq(with format: AVAudioFormat, channelSettings: ChannelSettings) {
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
    
    /**
     * Completes remaing setup for player and enables EQ
     *
     * @param format
     * @param channelSettings
     */
    // MARK: configureEngine
    private func configureEngine(with format: AVAudioFormat, channelSettings: ChannelSettings) {
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
            playerMixer.removeTap(onBus: 0)
            playerMixer.installTap(onBus: 0, bufferSize: 1024, format: playerMixer.outputFormat(forBus: 0), block: handleMetering)
        }

        if (channelSettings.elapsedTimeEventName != "") {
            setElapsedTimeEvent(eventName: channelSettings.elapsedTimeEventName!)
        }
        
        engine.connect(player, to: eq, format: format)
        engine.connect(eq, to: playerMixer, format: format)
        engine.connect(playerMixer, to: engine.mainMixerNode, format: playerMixer.outputFormat(forBus: 0))
        engine.prepare()
        
      
      do {
        try engine.start()
        
        scheduleAudioFile()
//        isPlayerReady = true
      } catch {
        // print("Error starting the player: \(error.localizedDescription)")
      }
    }
    
    /**
     * Sets up an audio file when initilized or needs to be reset
     */
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
    
    /**
     * Local listener that handles metering 
     * 
     * @param buffer
     * @param time
     */
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

                self._parent.notifyListeners(self.listenerName, data: [ResponseParameters.meterLevel: response])
            
                if (self.elapsedTimeEventName != "") {
                    self._parent.notifyListeners(self.elapsedTimeEventName, data: self.player.elapsedTimeSeconds.toDictionary())
                }
            }
        }
    }
    
    /**
     * Adds the elapsedTimeEventName and enables playback notifications for player elapsed time
     *
     * @param eventName
     */
    public func setElapsedTimeEvent(eventName: String) {
        elapsedTimeEventName = eventName
    }
    

    // MARK: Player Controls
    
    /**
     * Handles play or pause for player
     *
     * @return
     */
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
    
    /**
     * Handles "stop" for player
     *
     * @return
     */
    // MARK: stop
    public func stop() -> String {
        elapsedTime = 0
        player.stop()
        return "stop"
//        needsFileScheduled = true
    }
    
    /**
     * Returns player if it is playing
     *
     * @return
     */
    // MARK: isPlaying
    public func isPlaying() -> Bool {
        return player.isPlaying
    }
    
    /**
     * Changes volume for the player
     *
     * @param volume
     */
    // MARK: adjustVolume
    public func adjustVolume(volume: Float) {
        playerMixer.outputVolume = volume
    }
    
    /**
     * Returns current volume for player
     *
     * @return
     */
    // MARK: getCurrentVolume
    public func getCurrentVolume() -> Float {
        return playerMixer.outputVolume
    }
    
    /**
     * Changes EQ output associated with the player
     *
     * @param type
     * @param gain
     * @param freq
     */
    // MARK: adjustEq
    public func adjustEq(type: String, gain: Float, freq: Float) {
        if(eq.bands.count < 1) {
            return
        }
        switch type.lowercased() {
        case "bass":
            let bassEq = eq.bands[0]
            bassEq.gain = gain
            bassEq.frequency = freq.isEqual(to: -1) ? bassEq.frequency : freq
            break;
        case "mid":
            let midEq = eq.bands[1]
            midEq.gain = gain
            midEq.frequency = freq.isEqual(to: -1) ? midEq.frequency : freq
            break;
        case "treble":
            let trebleEq = eq.bands[2]
            trebleEq.gain = gain
            trebleEq.frequency = freq.isEqual(to: -1) ? trebleEq.frequency : freq
            break;
        default: break
            // print("adjustEq: invalid eq type")
        }
    }
    
    /**
     * Returns current tracked EQ
     * @return
     */
    // MARK: getCurrentEq
    public func getCurrentEq() -> [String: Float] {
        if(eq.bands.count < 1) {
            return [:]
        }
        let bassEq = eq.bands[0]
        let midEq = eq.bands[1]
        let trebleEq = eq.bands[2]
        
        return [ResponseParameters.bassGain: bassEq.gain,
                ResponseParameters.bassFrequency: bassEq.frequency,
                ResponseParameters.midGain: midEq.gain,
                ResponseParameters.midFrequency: midEq.frequency,
                ResponseParameters.trebleGain: trebleEq.gain,
                ResponseParameters.trebleFrequency: trebleEq.frequency]
    }
    
    /**
     * Returns current elapsed time on player
     *
     * Note: This can be done automatically using setElapsedTimeEvent
     *
     * @return
     */
    // MARK: getElapsedTime
    public func getElapsedTime() -> [String: Int] {
        if(player.elapsedTimeSeconds > elapsedTime) {
            elapsedTime = player.elapsedTimeSeconds
        }
        return elapsedTime.toDictionary()
    }
    
    /**
     * Returns total time for the loaded track
     * @return
     */
    // MARK: getTotalTime
    public func getTotalTime() -> [String: Int] {
        return (audioFile?.totalDurationSeconds.toDictionary())!
    }
    
    /**
     * Destroys object and resets state.
     *
     * @return
     */
    // MARK: Destroy
    public func destroy() -> [String : String] {
        if(player.isPlaying){
            player.stop()
        }
        playerMixer.removeTap(onBus: 0)
        
        engine.detach(player)
        engine.detach(eq)
        engine.detach(playerMixer)
        return [ResponseParameters.listenerName: self.listenerName,
                ResponseParameters.elapsedTimeEventName: self.elapsedTimeEventName]
    }
}

extension TimeInterval{

    /**
     * Converts TimeInterval to a dictionary that has seperated to milliSeconds, seconds, minutes and hours
     */
    func toDictionary() -> [String : Int] {
        let time = NSInteger(self)
        let milliSeconds = Int((self.truncatingRemainder(dividingBy: 1)) * 1000)
        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)

        return [
            ResponseParameters.milliSeconds: milliSeconds,
            ResponseParameters.seconds: seconds,
            ResponseParameters.minutes: minutes,
            ResponseParameters.hours: hours
        ]
    }
}

extension AVAudioFile {

    /**
     * Returns the total duration of the AudioFile
     */
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
    
    /**
     * Returns the current elapsed time of the AudioFile
     */
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

    /**
     * Returns the current elapsed time in seconds of the AudioFile
     */
    var elapsedTimeSeconds: TimeInterval {
        if let nodeTime = lastRenderTime, let playerTime = playerTime(forNodeTime: nodeTime) {
            return Double(playerTime.sampleTime) / playerTime.sampleRate
        }
        return 0
    }
    
}
