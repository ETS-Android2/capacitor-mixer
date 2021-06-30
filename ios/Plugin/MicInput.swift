//
//  MicInput.swift
//  Plugin
//
//  Created by Austen Mack on 6/11/21.
//  Copyright © 2021 Max Lynch. All rights reserved.
//


import Foundation
import AVFoundation

public class MicInput {
    public let engine: AVAudioEngine = AVAudioEngine()
    public let eq: AVAudioUnitEQ = AVAudioUnitEQ(numberOfBands: 3)

    public let micMixer: AVAudioMixerNode = AVAudioMixerNode()
    public var _parent: Mixer
    public var listenerName: String = ""
    
    public var ioPlayer: AVAudioPlayerNode = AVAudioPlayerNode();
    public var ioBuffer: [AVAudioPCMBuffer] = [];
    public var micInputQueue: DispatchQueue = DispatchQueue(label: "mixerPlugin.micInput.queue");
    
    public var inputChannelCount: AVAudioChannelCount = 0;
    

    init(parent: Mixer){
//        micMixer.volume = 1.0
        _parent = parent
//        print("Available inputs: ", _parent.audioSession.availableInputs)
//        print("Preferred input: ", _parent.audioSession.preferredInput)
//        print("Data sources: ", _parent.audioSession.inputDataSources)
//        print("Data source: ", _parent.audioSession.inputDataSource)
//        print("Current Route: ", _parent.audioSession.currentRoute)
        var unitBusses = engine.inputNode.auAudioUnit.inputBusses
//        print("Unit Busses: ", unitBusses.count)
//        print("Channel Map", engine.inputNode.auAudioUnit.channelMap)
    }
    
    // MARK: setupAudio
    
    public func setupAudio(audioFilePath: NSURL, channelSettings: ChannelSettings) {
        setupEq(with: AVAudioFormat(), channelSettings: channelSettings)
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
        
        let micInput = engine.inputNode
        
        let micFormat = micInput.outputFormat(forBus: 0)
        inputChannelCount = micFormat.channelCount
        let toFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100.0, channels: 1, interleaved: false)
        

        
        micMixer.outputVolume = channelSettings.volume!
        
        engine.attach(eq)
        engine.attach(ioPlayer)
        engine.attach(micMixer)
        
        if (channelSettings.channelListenerName != "") {
            listenerName = channelSettings.channelListenerName!
            micMixer.removeTap(onBus: 0)
            micMixer.installTap(onBus: 0, bufferSize: 1024, format: micMixer.outputFormat(forBus: 0), block: handleMetering)
        }
        
        engine.connect(ioPlayer, to: eq, format: toFormat)
        engine.connect(eq, to: micMixer, format: toFormat)
        engine.connect(micMixer, to: engine.mainMixerNode, format: micMixer.outputFormat(forBus: 0))

        engine.prepare();
        
      do {
        try engine.start()
//        self.ioPlayer.prepare(withFrameCount: 8)
        self.ioPlayer.play();
        micInput.installTap(onBus: 0, bufferSize: 2048, format: micFormat, block: handleInputBuffer)
      } catch {
        print("Error starting the player: \(error.localizedDescription)")
      }
    }
    
    // MARK: handleMetering
    // TODO: move method into dispatchqueue
    public func handleMetering(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        // https://www.raywenderlich.com/21672160-avaudioengine-tutorial-for-ios-getting-started

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

//        _parent.notifyListeners(listenerName, data: ["meterLevel": response])
    }
    
    // TODO: remove this if not needed and uncomment tap for volume metering
    public func handleInputBuffer(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
//        let newBuffer = writeChannelDataForChannels(buffer: buffer)
        micInputQueue.async {
            // Gets all channels from AVAudioPCMBuffer in an array
            let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: Int(self.inputChannelCount))
            // Gets data from the channel based on array index
            let ch0Data = NSData(bytes: channels[0], length:Int(buffer.frameCapacity * buffer.format.streamDescription.pointee.mBytesPerFrame))
            let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100.0, channels: 1, interleaved: false)
            let newBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat!, frameCapacity: UInt32(ch0Data.length) / audioFormat!.streamDescription.pointee.mBytesPerFrame)
            newBuffer?.frameLength = newBuffer!.frameCapacity
            let newChannels = UnsafeBufferPointer(start: newBuffer?.floatChannelData, count: Int((newBuffer?.format.channelCount)!))
            ch0Data.getBytes(UnsafeMutableRawPointer(newChannels[0]), length: ch0Data.length)
//            print("buffer bytes per frame: ", newBuffer!.format.streamDescription.pointee.mBytesPerFrame)
//            print("buffer frame capacity: ", newBuffer!.frameCapacity)

            self.ioPlayer.scheduleBuffer(newBuffer!, completionHandler: nil)
        }
    }
    
//    private func writeChannelDataForChannels(buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer {
//        // Gets all channels from AVAudioPCMBuffer in an array
//        let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: Int(inputChannelCount))
//        // Gets data from the channel based on array index
//        let ch0Data = NSData(bytes: channels[0], length:Int(buffer.frameCapacity * buffer.format.streamDescription.pointee.mBytesPerFrame))
//        let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100.0, channels: 1, interleaved: false)
//        let newBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat!, frameCapacity: UInt32(ch0Data.length) / audioFormat!.streamDescription.pointee.mBytesPerFrame)
//        newBuffer?.frameLength = newBuffer!.frameCapacity
//        let newChannels = UnsafeBufferPointer(start: newBuffer?.floatChannelData, count: Int((newBuffer?.format.channelCount)!))
//        ch0Data.getBytes(UnsafeMutableRawPointer(newChannels[0]), length: ch0Data.length)
//
//        return newBuffer!
//    }

    // MARK: Player Controls
    
    
    
    // MARK: playOrPause
    public func playOrPause() -> String {
        return "Not implemented."
    }
    // MARK: stop
    public func stop() -> String {
        return "Not implemented."
//        needsFileScheduled = true
    }
    
    // MARK: isPlaying
    public func isPlaying() -> Bool {
        return true
    }
    
    // MARK: adjustVolume
    public func adjustVolume(volume: Float) {
        micMixer.outputVolume = volume
//        micInput.volume = volume
    }
    
    // MARK: getCurrentVolume
    public func getCurrentVolume() -> Float {
        return micMixer.outputVolume
//        return micInput.volume
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
        return ["statusCode": 1]
    }
    
    public func getTotalTime() -> [String: Int] {
        return ["statusCode": 1]
    }
  
    public func scaledPower(power: Float) -> Float {
        guard power.isFinite else {
          return 0.0
        }

        let minDb: Float = -80

        // 2
        if power < minDb {
          return 0.0
        } else if power >= 1.0 {
          return 1.0
        } else {
          // 3
          return (abs(minDb) - abs(power)) / abs(minDb)
        }
    }
}
