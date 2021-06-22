import Foundation
import Capacitor
import AVFoundation

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */

@objc(Mixer)
public class Mixer: CAPPlugin {
    
    public var audioFileList: [String : AudioFile] = [:]
    public var micInputList: [String : MicInput] = [:]
    public let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    
    public override func load() {
        super.load()
        
        do {
            try audioSession.setCategory(.multiRoute, mode: .gameChat, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        }
        catch {
            print("Problem initializing audio session")
        }
        if let desc = audioSession.availableInputs?.first(where: {(desc) -> Bool in
            return desc.portType == .usbAudio
        }) {
            do {
                try audioSession.setPreferredInput(desc)
            } catch let error {
                print(error)
            }
        }
    }
    
    @objc func echo(_ call: CAPPluginCall) {
        let value = call.getString("value") ?? ""
        call.success([
            "value": value
        ])
    }
    
    // MARK: initMicInput
    @objc func initMicInput(_ call: CAPPluginCall) {
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
        
        micInputList[audioId] = MicInput(parent: self)
        micInputList[audioId]?.setupAudio(audioFilePath: NSURL(), channelSettings: channelSettings)
        call.success(buildBaseResponse(wasSuccessful: true, message: "mic was successfully initialized"))
    }
    
    // MARK: initAudioFile
    @objc func initAudioFile(_ call: CAPPluginCall) {
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
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from initAudioFile - filePath not found"))
        }
        if (audioId.isEmpty) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from initAudioFile - audioId not found"))
        }
        // TODO: implement check for overwriting existing audioID
        // CHECK: AudioFile parent param - it's not yelling, but is it right?
        audioFileList[audioId] = AudioFile(parent: self)
        if (filePath != "") {
            let scrubbedString = filePath.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? ""
            let urlString = NSURL(string: scrubbedString)
            if (urlString != nil) {
                audioFileList[audioId]!.setupAudio(audioFilePath: urlString!, channelSettings: channelSettings)
                call.success(buildBaseResponse(wasSuccessful: true, message: "file is initialized", data: ["value": audioId]))
            }
            else {
                call.resolve(buildBaseResponse(wasSuccessful: false, message: "in initAudioFile, urlString invalid"))
            }
        }
        else {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "in initAudioFile, filePath invalid"))
        }
    }
    
    // MARK: isPlaying
    @objc func isPlaying(_ call: CAPPluginCall) {
        guard let audioId = getAudioId(call: call, functionName: "isPlaying") else {return}
        let result = audioFileList[audioId]!.isPlaying()
        call.success(buildBaseResponse(wasSuccessful: true, message: "audio file is playing", data: ["value": result]))
    }
    

    
    
    // This plays AND pauses stuff, ya daangus!
    // TODO: Return error to user when play is hit before choosing file
    
    // MARK: play RENAME ME TO PLAYORPAUSE
    @objc func play(_ call: CAPPluginCall) {
        guard let audioId = getAudioId(call: call, functionName: "play") else {return}
        let result = audioFileList[audioId]!.playOrPause()
        call.success(buildBaseResponse(wasSuccessful: true, message: "playing or pausing playback", data: ["state": result]))
    }
    
    // MARK: stop
    @objc func stop(_ call: CAPPluginCall) {
        guard let audioId = getAudioId(call: call, functionName: "stop") else {return}
        let result = audioFileList[audioId]!.stop()
        call.success(buildBaseResponse(wasSuccessful: true, message: "stopping playback", data: ["state": result]))
    }
    
    // MARK: adjustVolume
    @objc func adjustVolume(_ call: CAPPluginCall) {
        guard let audioId = getAudioId(call: call, functionName: "adjustVolume") else {return}
        let volume = call.getFloat("volume") ?? -1.0
        let inputType = call.getString("inputType")
        
        
        if (volume.isLess(than: 0)) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Give me a real volume, dog"))
        }
        if (inputType == "file") {
            audioFileList[audioId]?.adjustVolume(volume: volume)
        }
        else if (inputType == "mic") {
            micInputList[audioId]?.adjustVolume(volume: volume)
        }
        else {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Could not find object at [audioId]"))
        }
        call.success(buildBaseResponse(wasSuccessful: true, message: "you are adjusting the volume"))
    }
    
    // MARK: getCurrentVolume
    @objc func getCurrentVolume(_ call: CAPPluginCall) {
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
        }
        call.success(buildBaseResponse(wasSuccessful: true, message: "here is the current volume", data: ["volume": result ?? -1]))
    }
    
    // MARK: adjustEq
    @objc func adjustEq(_ call: CAPPluginCall) {
        guard let audioId = getAudioId(call: call, functionName: "adjustEq") else {return}
        let filterType = call.getString("eqType") ?? ""
        let gain = call.getFloat("gain") ?? -100.0
        let freq = call.getFloat("frequency") ?? -1.0
        let inputType = call.getString("inputType")
        
        
        if (filterType.isEmpty) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from adjustEq - filter type not specified"))
        }
        if (gain.isLess(than: -100.0)) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from adjustEq - gain too low"))
        }
        if (freq.isLess(than: -1.0)) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from adjustEq - frequency not specified"))
        }
        if (inputType == "file") {
            audioFileList[audioId]?.adjustEq(type: filterType, gain: gain, freq: freq)
        }
        else if (inputType == "mic") {
            micInputList[audioId]?.adjustEq(type: filterType, gain: gain, freq: freq)
        }
        else {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "Could not find object at [audioId]"))
        }
        call.success(buildBaseResponse(wasSuccessful: true, message: "you are adjusting EQ"))
    }
    
    // MARK: getCurrentEq
    @objc func getCurrentEq(_ call: CAPPluginCall) {
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
        }
        call.success(buildBaseResponse(wasSuccessful: true, message: "here is the current EQ", data: result))
    }
    

    
    // MARK: setElapsedTimeEvent
    @objc func setElapsedTimeEvent(_ call: CAPPluginCall) {
        guard let audioId = getAudioId(call: call, functionName: "setElapsedTimeEvent") else {return}
        let eventName = call.getString("eventName") ?? ""
        if (eventName.isEmpty) {
            call.resolve(buildBaseResponse(wasSuccessful: false, message: "from setElapsedTimeEvent - eventName not found"))
        }
        audioFileList[audioId]?.setElapsedTimeEvent(eventName: eventName, mixer: self)
        call.success(buildBaseResponse(wasSuccessful: true, message: "set elapsed time event"))
    }
    
    // MARK: getElapsedTime
    @objc func getElapsedTime(_ call: CAPPluginCall) {
        guard let audioId = getAudioId(call: call, functionName: "getElapsedTime") else {return}
        let result = (audioFileList[audioId]?.getElapsedTime())!
        call.success(buildBaseResponse(wasSuccessful: true, message: "got Elapsed Time", data: result))
    }
    
    // MARK: getTotalTime
    @objc func getTotalTime(_ call: CAPPluginCall) {
        guard let audioId = getAudioId(call: call, functionName: "getTotalTime") else {return}
        let result = (audioFileList[audioId]?.getTotalTime())!
        call.success(buildBaseResponse(wasSuccessful: true, message: "got total time", data: result))
    }
    
    //6.14 CHANGED ERROR CHECKING TO INCLUDE MICINPUTLIST
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
    
    private func buildBaseResponse(wasSuccessful: Bool, message: String, data: [String: Any] = [:]) -> [String: Any] {
        if (wasSuccessful) {
            return ["status": "success", "message": message, "data": data]
        }
        else {
            return ["status": "error", "message": message, "data": data]
        }
    }

//    MARK: downloadFileFromURL
//    private func downloadFileFromURL(url:NSURL){
//
//        var downloadTask:URLSessionDownloadTask
//        downloadTask = URLSession.shared.downloadTask(with: url as URL, completionHandler: { [weak self](URL, URLResponse, Error) -> Void in
//            self?.audioFile.setupAudio(audioFilePath: URL! as NSURL)
//        })
//
//        downloadTask.resume()
//
//    }
}
