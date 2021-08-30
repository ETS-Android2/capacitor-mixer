//
//  MicInput.swift
//  Plugin
//
//  Created by Skylabs Technology on 6/11/21.
//  Copyright © 2021 Max Lynch. All rights reserved.
//


import Foundation
import AVFoundation

public class MicInput {

    public let engine: AVAudioEngine = AVAudioEngine()
    public let eq: AVAudioUnitEQ = AVAudioUnitEQ(numberOfBands: 3)

    public var micInput: AVAudioInputNode?
    public let micMixer: AVAudioMixerNode = AVAudioMixerNode()
    public var _parent: Mixer
    public var listenerName: String = ""
    
    public var ioPlayer: AVAudioPlayerNode = AVAudioPlayerNode();
    public var ioBuffer: [AVAudioPCMBuffer] = [];
    public var micInputQueue: DispatchQueue
    public var meterQueue: DispatchQueue
    
    public var inputChannelCount: AVAudioChannelCount = 0;
    public var selectedInputChannel: Int = -1;
    public var toFormat: AVAudioFormat;
    


    // TODO 7/5 : Handle audio session interrupts
    init(parent: Mixer, audioId: String){
        _parent = parent
        //        engine = _parent.engine
        micInputQueue = DispatchQueue(label: "mixerPlugin.micInput.queue.\(audioId)", qos: .userInitiated);
        meterQueue = DispatchQueue(label: "mixerPlugin.micMeter.queue.\(audioId)", qos: .userInitiated);
        toFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100.0, channels: 1, interleaved: true)!
    }
    
    deinit {
        print("We are being disposed")
    }
    
    /**
     * Starts initialization of an Mic input. Configures then starts mic and its listeners
     *
     * @param channelSettings
     */
    // MARK: setupAudio
    public func setupAudio(audioFilePath: NSURL, channelSettings: ChannelSettings) {
        setupEq(with: AVAudioFormat(), channelSettings: channelSettings)
    }
    
    /**
     * Sets up EQ for input
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
     * Completes remaining setup for objects and enables EQ
     *
     * @param channelSettings
     */
    // MARK: configureEngine
    public func configureEngine(with format: AVAudioFormat, channelSettings: ChannelSettings) {
        if (engine.isRunning) {
            engine.stop()
        }
        
        micInput = engine.inputNode
        let micFormat = micInput!.outputFormat(forBus: 0)
        inputChannelCount = micFormat.channelCount
//        toFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100.0, channels: 1, interleaved: true)
        selectedInputChannel = channelSettings.channelNumber!
        
        ioPlayer.volume = 0.8
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
        micInput!.installTap(onBus: 0, bufferSize: 512, format: micFormat, block: handleInputBuffer)
      } catch {
        print("Error starting the player: \(error.localizedDescription)")
      }
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
        meterQueue.async{
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
            let response = avgPower < -80 ? -80 : avgPower

            self._parent.notifyListeners(self.listenerName, data: [ResponseParameters.meterLevel : response])
            
        }
    }

    /**
     * Handles looping over and creating a buffer for mic input
     * 
     * @param buffer
     * @param time
     */
    // MARK: handleInputBuffer
    public func handleInputBuffer(buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        micInputQueue.async {
            // Gets all channels from AVAudioPCMBuffer in an array
            let channels = UnsafeBufferPointer(start: buffer.floatChannelData, count: Int(self.inputChannelCount))
            // Gets data from the channel based on array index
            let ch0Data = NSData(bytes: channels[self.selectedInputChannel], length:Int(buffer.frameCapacity * buffer.format.streamDescription.pointee.mBytesPerFrame))
            let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100.0, channels: 1, interleaved: true)
            let newBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat!, frameCapacity: UInt32(ch0Data.length) / audioFormat!.streamDescription.pointee.mBytesPerFrame)
            newBuffer?.frameLength = newBuffer!.frameCapacity
            let newChannels = UnsafeBufferPointer(start: newBuffer?.floatChannelData, count: Int((newBuffer?.format.channelCount)!))
            ch0Data.getBytes(UnsafeMutableRawPointer(newChannels[0]), length: ch0Data.length)

            self.ioPlayer.scheduleBuffer(newBuffer!, completionHandler: nil)
        }
    }

    // MARK: Player Controls

    /**
     * Not Implemented for MicInput
     *
     * @return
     */
    // MARK: playOrPause
    public func playOrPause() -> String {
        return "not implemented"
    }

    /**
     * Not Implemented for MicInput
     *
     * @return
     */
    // MARK: stop
    public func stop() -> String {
        return "not implemented"
    }
    
    /**
     * Always returns true for MicInput
     *
     * @return
     */
    // MARK: isPlaying
    public func isPlaying() -> Bool {
        return true
    }
    
    /**
     * Changes volume for the mic player
     *
     * @param volume
     */
    // MARK: adjustVolume
    public func adjustVolume(volume: Float) {
        micMixer.outputVolume = volume
//        micInput.volume = volume
    }
    
    /**
     * Returns current volume for mic player
     *
     * @return
     */
    // MARK: getCurrentVolume
    public func getCurrentVolume() -> Float {
        return micMixer.outputVolume
//        return micInput.volume
    }
    
    /**
     * Changes EQ output associated with the mic player
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
            bassEq.frequency = freq == -1 ? bassEq.frequency : freq;
            break;
        case "mid":
            let midEq = eq.bands[1]
            midEq.gain = gain
            midEq.frequency = freq == -1 ? midEq.frequency : freq;
            break;
        case "treble":
            let trebleEq = eq.bands[2]
            trebleEq.gain = gain
            trebleEq.frequency = freq == -1 ? trebleEq.frequency : freq;
            break;
        default:
            print("adjustEq: invalid eq type")
        }
    }
    
    /**
     * Returns current tracked EQ
     *
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
     * Not implemented for MicInput
     */
    // MARK: getElapsedTime
    public func getElapsedTime() -> [String: Int] {
        return ["statusCode": 1]
    }
    
    /** 
     * Not implemented for MicInput
     */
    // MARK: getTotalTime
    public func getTotalTime() -> [String: Int] {
        return ["statusCode": 1]
    }
    
    /**
     * Stops mic input temporarily and removes meter notifications and alerts listener.
     *
     * Note: processes will continue running for AudioRecord and AudioTrack in thread.
     * This should only be used temporarily
     */
    // MARK: interrupt
    public func interrupt() {
        micMixer.removeTap(onBus: 0)
        micInput!.removeTap(onBus: 0)
        ioPlayer.stop()
        engine.stop()
    }
    
    /**
     * Resumes mic input and starts meter notifications and alerts listener.
     */
    // MARK: resumeFromInterrupt
    public func resumeFromInterrupt() {
        micInput = engine.inputNode
        if (listenerName != "") {
            micMixer.installTap(onBus: 0, bufferSize: 1024, format: micMixer.outputFormat(forBus: 0), block: handleMetering)
        }
        ioPlayer.play()
        do {
            try engine.start()
            micInput!.installTap(onBus: 0, bufferSize: 512, format: micInput!.outputFormat(forBus: 0), block: handleInputBuffer)
            ioPlayer.play()
        } catch let error {
            print("Error resuming from interrupt with error: \(error)")
        }
    }
    
    /**
     * Destroys object and resets state
     *
     * @return
     */
    // MARK: Destroy
    public func destroy() -> [String : String] {
        micMixer.removeTap(onBus: 0)
        micInput?.removeTap(onBus: 0)
        engine.stop()
        return [ResponseParameters.listenerName: self.listenerName,
                ResponseParameters.elapsedTimeEventName: ""]
    }
}
