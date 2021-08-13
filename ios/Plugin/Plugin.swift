import Foundation
import Capacitor
import AVFoundation

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */

@objc(Mixer)
public class Mixer: CAPPlugin {
    
    private var audioFileList: [String : AudioFile] = [:]
    private var micInputList: [String : MicInput] = [:]
    public var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    public var engine: AVAudioEngine = AVAudioEngine()
    public var isAudioSessionActive: Bool = false
    public var audioFileInterruptionList: [String] = []
    public var audioSessionListenerName: String = ""
    public let nc: NotificationCenter = NotificationCenter.default
    
    public override func load() {
        super.load()
        registerForSessionInterrupts()
        registerForSessionRouteChange()
        // registerForMediaServicesWereReset()
        // registerForMediaServicesWereLost()
        do {
            try audioSession.setCategory(.multiRoute , mode: .default, options: [.defaultToSpeaker])
            try audioSession.setPreferredIOBufferDuration(0.005)
            try audioSession.setActive(true)
            try audioSession.setActive(false)
        } catch {
            print("Problem initializing audio session")
        }
    }

    /**
     * Requests permissions required by the mixer plugin
     * See README for additional information on permissions
     * @param call
     */
    @objc func requestMixerPermissions(_ call: CAPPluginCall) {
        requestPermissions(call);
        call.resolve(buildBaseResponse(wasSuccessful: false, message: "not implemented yet"))
    }

    /**
     * Initializes audio session with selected port type
     *
     * Returns a value describing the initialized port type for the audio session (usb, built-in, etc.)
     * @param call { inputPortType: String; ioBufferDuration: double; audioSessionListenerName: String; }
     */
    // MARK: initAudioSession
    @objc func initAudioSession(_ call: CAPPluginCall) {
        if (isAudioSessionActive == true) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Audio Session is already active, please call 'deinitAudioSession' prior to initializing a new audio session."))
            return
        }

        audioSessionListenerName = call.getString("audioSessionListenerName") ?? ""
        let inputPortType = call.getString("inputPortType") ?? ""
        let ioBufferDuration = call.getDouble("ioBufferDuration") ?? -1

        do {
            try audioSession.setCategory(.multiRoute , mode: .default, options: [.defaultToSpeaker])
            if (ioBufferDuration > 0) {
                try audioSession.setPreferredIOBufferDuration(ioBufferDuration)
            }
        }
        catch let error {
            isAudioSessionActive = false
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "There was a problem initializing your audio session with exception: \(error)"))
            return
        }
        if let inputDesc = audioSession.availableInputs?.first(where: {(desc) -> Bool in
            print("Available Input: ", desc)
            return determineAudioSessionPortDescription(desc: desc, type: inputPortType)
        }) {
            do {
                try audioSession.setPreferredInput(inputDesc)
            } catch let error {
                isAudioSessionActive = false
                call.resolve(buildBaseResponse(wasSuccessful: false, message: "There was a problem initializing your audio session with exception: \(error)"))
                print(error)
                return
            }
        }
        do {
            try audioSession.setActive(true)
            print("Current route is: \(audioSession.currentRoute)")
        } catch let error {
            isAudioSessionActive = false
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "There was a problem initializing your audio session with exception: \(error)"))
            print(error)
            return
        }

        let response = ["preferredInputPortType": audioSession.preferredInput?.portType as Any,
                        "preferredInputPortName": audioSession.preferredInput?.portName as Any,
                        "preferredIOBufferDuration": Float(audioSession.preferredIOBufferDuration)] as [String : Any]
        print("preferredIOBufferDuration: ", audioSession.preferredIOBufferDuration)
        isAudioSessionActive = true

        call.resolve(buildBaseResponse(wasSuccessful: true, message: "successfully initialized audio session", data: response))
    }
    
    /**
     * Cancels audio session and resets selected port. Use prior to changing port type
     * @param call
     */
    // MARK: deinitAudioSession
    @objc func deinitAudioSession(_ call: CAPPluginCall) {
        do {
            try audioSession.setActive(false)
            isAudioSessionActive = false
            call.resolve(buildBaseResponse(wasSuccessful: true, message: "Successfully deinitialized audio session"))
        } catch let error {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "ERROR deinitializing audio session with exception: \(error)"))
            return
        }
    }
    
    /**
     * Resets plugin state back to its initial state
     *
     * CAUTION: This will completely wipe everything you have initialized from the plugin!
     * @param call
     */
    // MARK: resetPlugin
    @objc func resetPlugin(_ call: CAPPluginCall) {
        do {
            try audioSession.setActive(false)
            isAudioSessionActive = false
        } catch let error {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "ERROR deinitializing audio session with exception: \(error)"))
            return
        }
        audioFileList.forEach { (key: String, value: AudioFile) in
            _ = value.destroy()
        }
        micInputList.forEach { (key: String, value: MicInput) in
            _ = value.destroy()
        }
        audioFileList = [:]
        micInputList = [:]
        engine = AVAudioEngine()
        audioSession = AVAudioSession.sharedInstance()
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "Successfully restarted plugin to original state."))
    }
    
    /**
     * Returns a value describing the initialized port type for the audio session (usb, built-in, etc.)
     * @param call
     */
    // MARK: getAudioSessionPreferredInputPortType
    @objc func getAudioSessionPreferredInputPortType(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "got preferred input", data: ["value": audioSession.preferredInput!.portType]))
    }

    /**
     * Initializes microphone channel on mixer
     *
     * Returns AudioId string of initialized microphone input
     * @param call { 
     *             audioId: String;
     *             channelNumber: Float;
     *             bassGain: Float;
     *             bassFrequency: Float;
     *             midGain: Float;
     *             midFrequency: Float;
     *             trebleGain: Float;
     *             trebleFrequency: Float;
     *             volume: Float;
     *             channelListenerName: String;
     *            }
     */
    // MARK: initMicInput
    @objc func initMicInput(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        let audioId = call.getString("audioId") ?? ""
        let channelNumber = call.getInt("channelNumber") ?? -1
        if (channelNumber == -1) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "no channel number"))
            return
        }
        if (micInputList[audioId] != nil) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "audioId already in use"))
            return
        }
        let eqSettings: EqSettings = EqSettings()
        let channelSettings: ChannelSettings = ChannelSettings()
        
        eqSettings.bassGain = call.getFloat("bassGain") ?? 0.0
        eqSettings.bassFrequency = call.getFloat("bassFrequency") ?? 115.0
        eqSettings.midGain = call.getFloat("midGain") ?? 0.0
        eqSettings.midFrequency = call.getFloat("midFrequency") ?? 500.0
        eqSettings.trebleGain = call.getFloat("trebleGain") ?? 0.0
        eqSettings.trebleFrequency = call.getFloat("trebleFrequency") ?? 1500.0
        
        channelSettings.volume = call.getFloat("volume") ?? 1.0
        channelSettings.channelListenerName = call.getString("channelListenerName") ?? ""
        channelSettings.eqSettings = eqSettings
        channelSettings.channelNumber = channelNumber
        
        micInputList[audioId] = MicInput(parent: self, audioId: audioId)
        
        micInputList[audioId]?.setupAudio(audioFilePath: NSURL(fileURLWithPath: ""), channelSettings: channelSettings)
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "mic was successfully initialized", data: ["value": audioId]))
    }
    
    /**
     * De-initializes a mic input channel based on audioId
     *
     * Note: Once destroyed, the channel cannot be recovered
     * @param call { audioId: String; }
     */
    // MARK: destroyMicInput
    @objc func destroyMicInput(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "isPlaying") else {return}
        let response = micInputList[audioId]!.destroy()
        micInputList[audioId] = nil
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "Mic input \(audioId) destroyed", data: response))
    }
    
    /**
     * Returns AudioId string of initialized audio file
     * @param call { audioId: String;
     *             channelNumber: Float;
     *             bassGain: Float;
     *             bassFrequency: Float;
     *             midGain: Float;
     *             midFrequency: Float;
     *             trebleGain: Float;
     *             trebleFrequency: Float;
     *             volume: Float;
     *             channelListenerName: String;
     *            }
     */
    // MARK: initAudioFile
    @objc func initAudioFile(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        let filePath = call.getString("filePath") ?? ""
        let audioId = call.getString("audioId") ?? ""
        let eqSettings: EqSettings = EqSettings()
        let channelSettings: ChannelSettings = ChannelSettings()
        
        eqSettings.bassGain = call.getFloat("bassGain") ?? 0.0
        eqSettings.bassFrequency = call.getFloat("bassFrequency") ?? 115.0
        eqSettings.midGain = call.getFloat("midGain") ?? 0.0
        eqSettings.midFrequency = call.getFloat("midFrequency") ?? 500.0
        eqSettings.trebleGain = call.getFloat("trebleGain") ?? 0.0
        eqSettings.trebleFrequency = call.getFloat("trebleFrequency") ?? 1500.0
        
        channelSettings.volume = call.getFloat("volume") ?? 1.0
        channelSettings.channelListenerName = call.getString("channelListenerName") ?? ""
        channelSettings.eqSettings = eqSettings
        
        if (filePath.isEmpty) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "filePath not found"))
            return
        }
        if (audioId.isEmpty) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "audioId not found"))
            return
        }
        if (audioFileList[audioId] != nil) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "audioId already in use"))
            return
        }
        audioFileList[audioId] = AudioFile(parent: self, audioId: audioId)
        if (filePath != "") {
            let scrubbedString = filePath.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? ""
            let urlString = NSURL(string: scrubbedString)
            if (urlString != nil) {
                audioFileList[audioId]!.setupAudio(audioFilePath: urlString!, channelSettings: channelSettings)
                call.resolve(buildBaseResponse(wasSuccessful: true, message: "file is initialized", data: ["value": audioId]))
            }
            else {
                call.resolve(buildBaseResponse(wasSuccessful: false, message: "in initAudioFile, urlString invalid"))
            }
        }
        else {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "in initAudioFile, filePath invalid"))
        }
    }
    
    /**
     * De-initializes an audio file channel based on audioId
     *
     * Note: Once destroyed, the channel cannot be recovered
     * @param call { audioId: String; }
     */
    // MARK: destroyAudioFile
    @objc func destroyAudioFile(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "isPlaying") else {return}
        let response = audioFileList[audioId]!.destroy()
        audioFileList[audioId] = nil
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "Audio file \(audioId) destroyed", data: response))
    }
    
    /**
     * A boolean that returns the playback state of initialized audio file
     * @param call { audioId: String; }
     */
    // MARK: isPlaying
    @objc func isPlaying(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "isPlaying") else {return}
        let result = audioFileList[audioId]!.isPlaying()
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "audio file is playing", data: ["value": result]))
    }
    
    /**
     * Toggles playback and pause on an initialized audio file
     * @param call { audioId: String; }
     */
    @objc func play(_ call: CAPPluginCall) {
        // TODO: Return error to user when play is hit before choosing file
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "play") else {return}
        let result = audioFileList[audioId]!.playOrPause()
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "playing or pausing playback", data: ["state": result]))
    }
    
    /**
     * Stops playback on a playing audio file
     * @param call { audioId: String; }
     */
    // MARK: stop
    @objc func stop(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "stop") else {return}
        let result = audioFileList[audioId]!.stop()
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "stopping playback", data: ["state": result]))
    }
    
    /**
     * Adjusts volume for a channel
     * @param call { audioId: String; volume: Float; inputType: String; }
     */
    // MARK: adjustVolume
    @objc func adjustVolume(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "adjustVolume") else {return}
        let volume = call.getFloat("volume") ?? -1.0
        let inputType = call.getString("inputType") ?? ""
        
        if (volume.isLess(than: 0)) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "in adjustVolume - volume cannot be less than zero percent"))
            return
        }
        if (inputType == "file") {
            audioFileList[audioId]?.adjustVolume(volume: volume)
        }
        else if (inputType == "mic") {
            micInputList[audioId]?.adjustVolume(volume: volume)
        }
        else {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Could not find object at [audioId]"))
            return
        }
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "you are adjusting the volume"))
    }
    
    /**
     * Returns current volume of a channel as a number between 0 and 1
     * @param call { audioId: String; inputType: String; }
     */
    // MARK: getCurrentVolume
    @objc func getCurrentVolume(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "getCurrentVolume") else {return}
        let inputType = call.getString("inputType")
        var result: Float?
        if (inputType == "file") {
            result = audioFileList[audioId]?.getCurrentVolume()
        }
        else if (inputType == "mic") {
            result = micInputList[audioId]?.getCurrentVolume()
        }
        else {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Could not find object at [audioId]"))
            return
        }
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "here is the current volume", data: ["volume": result ?? -1]))
    }
    
    /**
     * Adjusts gain and frequency in bass, mid, and treble ranges for a channel
     * @param call { audioId: String;
     *              eqType: String;
     *             gain: Float;
     *             frequency: Float;
     *             inputType: String;
     *             }
     */
    // MARK: adjustEq
    @objc func adjustEq(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "adjustEq") else {return}
        let filterType = call.getString("eqType") ?? ""
        let gain = call.getFloat("gain") ?? -100.0
        let freq = call.getFloat("frequency") ?? -1.0
        let inputType = call.getString("inputType")
        
        if (filterType.isEmpty) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from adjustEq - filter type not specified"))
            return
        }
        if (gain.isLess(than: -100.0)) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from adjustEq - gain too low"))
            return
        }
        if (freq.isLess(than: -1.0)) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from adjustEq - frequency not specified"))
            return
        }
        if (inputType == "file") {
            audioFileList[audioId]?.adjustEq(type: filterType, gain: gain, freq: freq)
        }
        else if (inputType == "mic") {
            micInputList[audioId]?.adjustEq(type: filterType, gain: gain, freq: freq)
        }
        else {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Could not find object at [audioId]"))
            return
        }
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "you are adjusting EQ"))
    }
    
    /**
     * Returns an object with numeric values for gain and frequency in bass, mid, and treble ranges
     * @param call { audioId: String; inputType: String; }
     */
    // MARK: getCurrentEq
    @objc func getCurrentEq(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "getCurrentEq") else {return}
        let inputType = call.getString("inputType")
        
        var result: [String: Float] = [:]
        if (inputType == "file") {
            result = (audioFileList[audioId]?.getCurrentEq())!
        }
        else if (inputType == "mic") {
            result = (micInputList[audioId]?.getCurrentEq())!
        }
        else {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Could not find object at [audioId]"))
            return
        }
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "here is the current EQ", data: result))
    }
    
    /**
     * Sets an elapsed time event name for a given audioId. Only applicable for audio files
     * @param call { audioId: String; eventName: String; }
     */
    // MARK: setElapsedTimeEvent
    @objc func setElapsedTimeEvent(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "setElapsedTimeEvent") else {return}
        let eventName = call.getString("eventName") ?? ""
        if (eventName.isEmpty) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from setElapsedTimeEvent - eventName not found"))
            return
        }
        audioFileList[audioId]?.setElapsedTimeEvent(eventName: eventName)
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "set elapsed time event"))
    }
    
    /**
     * Returns an object representing hours, minutes, seconds, and milliseconds elapsed
     * @param call { audioId: String; }
     */
    // MARK: getElapsedTime
    @objc func getElapsedTime(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "getElapsedTime") else {return}
        let result = (audioFileList[audioId]?.getElapsedTime())!
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "got Elapsed Time", data: result))
    }
    
    /**
     * Returns total time in an object of hours, minutes, seconds, and millisecond totals
     * @param call { audioId: String; }
     */
    // MARK: getTotalTime
    @objc func getTotalTime(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        guard let audioId = getAudioId(call: call, functionName: "getTotalTime") else {return}
        let result = (audioFileList[audioId]?.getTotalTime())!
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "got total time", data: result))
    }
    
    /**
     * Returns the channel count and name of the initialized audio device
     * @param call
     */
    // MARK: getInputChannelCount
    @objc func getInputChannelCount(_ call: CAPPluginCall) {
        guard let _ = checkAudioSessionInit(call: call) else {return}
        let channelCount = engine.inputNode.inputFormat(forBus: 0).channelCount;
        let deviceName = audioSession.preferredInput?.portName
        call.resolve(buildBaseResponse(wasSuccessful: true, message: "got input channel count and device name", data: ["channelCount": channelCount, "deviceName": deviceName ?? ""]))
    }
    
    /**
     * Utility method to get audioId from CAPPlugin object
     *
     * Handles resolving method if no audioId found
     * @param call
     * @param functionName
     * @return
     */
    // MARK: getAudioId
    private func getAudioId(call: CAPPluginCall, functionName: String) -> String? {
        let audioId = call.getString("audioId") ?? ""
        if (audioId.isEmpty) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from \(functionName) - audioId not found"))
            return nil
        }
        if (audioFileList[audioId] == nil && micInputList[audioId] == nil) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from \(functionName) - File not yet added to queue"))
            return nil
        }
        return audioId
    }
    
    /**
     * Generic response builder
     * @param wasSuccessful
     * @param message
     * @param data
     * @return
     */
    // MARK: buildBaseResponse
    private func buildBaseResponse(wasSuccessful: Bool, message: String, data: [String: Any] = [:]) -> [String: Any] {
        if (wasSuccessful) {
            return ["status": "success", "message": message, "data": data]
        }
        else {
            return ["status": "error", "message": message, "data": data]
        }
    }
    
    /**
     * Utility method to determine if an audio session is active
     *
     * Handles resolve if audio session is not active
     * @param call
     * @return
     */
    // MARK: checkAudioSessionInit
    private func checkAudioSessionInit(call: CAPPluginCall) -> Bool? {
        if (isAudioSessionActive == false) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Must call initAudioSession prior to any other usage"))
            return nil
        }
        return true
    }
    
    /**
     * Finds audio device enum value based on passed-in port type
     * @param inputPortType
     * @return
     */
    // MARK: determineAudioSessionPortDescription
    private func determineAudioSessionPortDescription(desc: AVAudioSessionPortDescription, type: String) -> Bool {
        switch type {
            // case "avb":
            //     if #available(iOS 14.0, *) {
            //         return desc.portType == .AVB
            //     } else {
            //         return false
            //     }
                
            case "hdmi":
                return desc.portType == .HDMI
                
            // case "pci":
            //     if #available(iOS 14.0, *) {
            //         return desc.portType == .PCI
            //     } else {
            //         return false
            //     }
                
            case "airplay":
                return desc.portType == .airPlay
                
            case "bluetoothA2DP":
                return desc.portType == .bluetoothA2DP
                
            case "bluetoothHFP":
                return desc.portType == .bluetoothHFP
                
            case "bluetoothLE":
                return desc.portType == .bluetoothLE
                
            case "builtInMic":
                return desc.portType == .builtInMic

            case "headsetMicWired":
                return desc.portType == .headsetMic
                
            case "headsetMicUsb":
                return desc.portType == .headsetMic
                
            case "lineIn":
                return desc.portType == .lineIn
            
            case "thunderbolt":
                if #available(iOS 14.0, *) {
                    return desc.portType == .thunderbolt
                } else {
                    return false
                }
                
            case "usbAudio":
                return desc.portType == .usbAudio
                
            case "virtual":
                if #available(iOS 14.0, *) {
                    return desc.portType == .virtual
                } else {
                    return false
                }
                
            default:
                return false
        }
    }
    
    /**
     * Creates observer for interruption notifications
     *
     * Registers handleInterruption() as callback
     */
    // TODO: Think about removing this observer when audioSession.isActive is set to false
    // MARK: registerForSessionInterrupts
    private func registerForSessionInterrupts() {
        nc.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: audioSession)
    }
    
    /**
     * Creates observer for route change notifications
     *
     * Registers handleRouteChange() as callback
     */
    // TODO: Think about removing this observer when audioSession.isActive is set to false
    // MARK: registerForSessionRouteChange
    private func registerForSessionRouteChange() {
        DispatchQueue.main.async {
            self.nc.addObserver(self, selector: #selector(self.handleRouteChange), name: AVAudioSession.routeChangeNotification, object: self.audioSession)
        }
    }
    
    /**
     * Creates observer for when media services are reset
     *
     * Registers handleServiceReset() as callback
     */
    // MARK: registerForMediaServicesWereReset
    private func registerForMediaServicesWereReset() {
        nc.addObserver(self, selector: #selector(handleServiceReset), name: AVAudioSession.mediaServicesWereResetNotification, object: audioSession)
    }
    
    /**
     * Creates observer for when media services are lost
     *
     * Registers handleServiceLost() as callback
     */
    // MARK: registerForMediaServicesWereLost
    private func registerForMediaServicesWereLost() {
        nc.addObserver(self, selector: #selector(handleServiceLost), name: AVAudioSession.mediaServicesWereLostNotification, object: audioSession)
    }
    
    /**
     * Callback for media route change
     *
     * Stops or resumes mic playback for micInputList
     *
     * Notifies JavaScript listener for audioSessionListenerName
     */
    // MARK: handleRouteChange
    @objc func handleRouteChange(notification: Notification) {
        DispatchQueue.main.async {
        print("handleRouteChange occurred with notification: \(notification)")
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue)
        else {return}
        switch reason {
            case .oldDeviceUnavailable:
                print("Old device unavailable")
                self.notifyListeners(self.audioSessionListenerName, data: ["handlerType": "ROUTE_DEVICE_DISCONNECTED"])
                self.micInputList.forEach { (key: String, value: MicInput) in
                    value.interrupt()
                }
            case .newDeviceAvailable:
                print("New device is available!")
                self.notifyListeners(self.audioSessionListenerName, data: ["handlerType": "ROUTE_DEVICE_RECONNECTED"])
                self.micInputList.forEach { (key: String, value: MicInput) in
                    value.resumeFromInterrupt()
                }
            case .routeConfigurationChange:
                print("Route has changed")
                self.notifyListeners(self.audioSessionListenerName, data: ["handlerType": ""])
            case .noSuitableRouteForCategory:
                print("No suitable route for category.")
            case .override:
                print("Route overridden")
            case .categoryChange:
                print("Category has changed.")
            case .unknown:
                print("route changed, unknown reason")
            case .wakeFromSleep:
                print("route changed, wake from sleep")
            default:
                ()
            }
        }
    }
    
    /**
     * Callback for media interruption
     *
     * Stops or resumes audioPlayer playback for audioFileList
     *
     * Notifies JavaScript listener for audioSessionListenerName
     */
    // MARK: handleInterruption
    @objc func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {return}
        
        switch type {
        case .began:
            print("AudioSession interrupted!")
            audioFileList.forEach{ (key: String, value: AudioFile) in
                if (value.isPlaying()) {
                    value.player.pause()
                    self.audioFileInterruptionList.append(key)
                }
            }
            notifyListeners(audioSessionListenerName, data: ["handlerType": "INTERRUPT_BEGAN"])
        case .ended:
            print("AudioSession resuming...")
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {return}
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if (options.contains(.shouldResume)) {
                self.audioFileInterruptionList.forEach{ (key: String) in
                    self.audioFileList[key]!.player.play()
                }
                audioFileInterruptionList = []
            } else {
                //An interruption ended. Don't resume playback.
            }
            notifyListeners(audioSessionListenerName, data: ["handlerType": "INTERRUPT_ENDED"])
        default:
            ()
        }
    }
    
     /**
     * Internal log for service resets
     */
    // MARK: handleServiceReset
    @objc func handleServiceReset(notification: Notification) {
//        guard let userInfo = notification.userInfo,
//              let typeValue = userInfo[AVAudioSession] as? UInt,
//              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
//        else {return}
        print("From handleServiceReset - Notification is: \(notification)")
    }
    
    /**
     * Internal log for losing service
     */
    // MARK: handleServiceLost
    @objc func handleServiceLost(notification: Notification) {
        print("From handleServiceLost - Notification is: \(notification)")
    }
    
}
