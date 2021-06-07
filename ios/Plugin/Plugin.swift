import Foundation
import Capacitor
import AVFoundation

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(Mixer)
public class Mixer: CAPPlugin {
    
    public let audioFile: MyAudioFile = MyAudioFile()
    public var audioFileList: [String : MyAudioFile] = [:]
    
    public override func load() {
        super.load()
    }
    
    @objc func echo(_ call: CAPPluginCall) {
        let value = call.getString("value") ?? ""
        call.success([
            "value": value
        ])
    }
    
    // MARK: isPlaying
    @objc func isPlaying(_ call: CAPPluginCall) {
        let audioId = call.getString("audioId") ?? ""
        if (audioId.isEmpty) {
            call.error("from isPlaying - audioId not found")
        }
        if (audioFileList[audioId] == nil) {
            call.error("from isPlaying - File not yet added to queue")
        }
        let result = audioFileList[audioId]!.isPlaying()
        call.success([ "value": result ])
    }
    
    // This plays AND pauses stuff, ya daangus!
    // TODO: Return error to user when play is hit before choosing file
    
    // MARK: play
    @objc func play(_ call: CAPPluginCall) {
        let audioId = call.getString("audioId") ?? ""
        if (audioId.isEmpty) {
            call.error("from play - audioId not found")
        }
        if (audioFileList[audioId] == nil) {
            call.error("from play - File not yet added to queue")
        }
        let result = audioFileList[audioId]!.playOrPause()
        call.success(["state": result])
    }
    
    // MARK: stop
    @objc func stop(_ call: CAPPluginCall) {
        let audioId = call.getString("audioId") ?? ""
        if (audioId.isEmpty) {
            call.error("from stop - audioId not found")
        }
        if (audioFileList[audioId] == nil) {
            call.error("from stop - File not yet added to queue")
        }
        let result = audioFileList[audioId]!.stop()
        call.success(["state": result])
    }
    
    // MARK: adjustVolume
    @objc func adjustVolume(_ call: CAPPluginCall) {
        let volume = call.getFloat("volume") ?? -1.0
        let audioId = call.getString("audioId") ?? ""
        if (volume.isLess(than: 0)) {
            call.error("Give me a real volume, dog")
        }
        if (audioId.isEmpty) {
            call.error("from adjustVolume - audioID not found")
        }
        if (audioFileList[audioId] == nil) {
            call.error("from adjustVolume - File not yet added to queue")
        }
        audioFileList[audioId]!.adjustVolume(volume: volume)
    }
    
    // MARK: getCurrentVolume
    @objc func getCurrentVolume(_ call: CAPPluginCall) {
        let audioId = call.getString("audioId") ?? ""
        if (audioId.isEmpty) {
            call.error("from getCurrentVolume - audioId not found")
        }
        if (audioFileList[audioId] == nil) {
            call.error("from getCurrentVolume - File not yet added to queue")
        }
        let result = audioFileList[audioId]!.getCurrentVolume()
        call.success(["volume": result])
    }
    
    // MARK: adjustEQ
    @objc func adjustEQ(_ call: CAPPluginCall) {
        let audioId = call.getString("audioId") ?? ""
        let filterType = call.getString("eqType") ?? ""
        let gain = call.getFloat("gain") ?? -100.0
        let freq = call.getFloat("frequency") ?? -1.0
        
        if (audioId.isEmpty) {
            call.error("from adjustEQ - audioID not found")
        }
        if (audioFileList[audioId] == nil) {
            call.error("from adjustEQ - File not yet added to queue")
        }
        if (filterType.isEmpty) {
            call.error("from adjustEQ - filter type not specified")
        }
        if (gain.isLess(than: -100.0)) {
            call.error("from adjustEQ - gain too low")
        }
        if (freq.isLess(than: -1.0)) {
            call.error("from adjustEQ - frequency not specified")
        }
        audioFileList[audioId]?.adjustEQ(type: filterType, gain: gain, freq: freq)
    }
    
    // MARK: getCurrentEQ
    @objc func getCurrentEQ(_ call: CAPPluginCall) {
        let audioId = call.getString("audioId") ?? ""
        if (audioId.isEmpty) {
            call.error("from adjustEQ - audioId not found")
        }
        if (audioFileList[audioId] == nil) {
            call.error("from adjustEQ - File not yet added to queue")
        }
        let result = audioFileList[audioId]!.getCurrentEQ()
        call.success(result)
    }
    
    // MARK: initAudioFile
    @objc func initAudioFile(_ call: CAPPluginCall) {
        let filePath = call.getString("filePath") ?? ""
        let audioId = call.getString("audioId") ?? ""
        let eqSettings: EqSettings = EqSettings()
        
        eqSettings.bassGain = call.getFloat("bassGain") ?? 0.0
        eqSettings.bassFrequency = call.getFloat("bassFrequency") ?? 115.0
        eqSettings.midGain = call.getFloat("midGain") ?? 0.0
        eqSettings.midFrequency = call.getFloat("midFrequency") ?? 500.0
        eqSettings.trebleGain = call.getFloat("trebleGain") ?? 0.0
        eqSettings.trebleFrequency = call.getFloat("trebleFrequency") ?? 1500.0
        
        if (filePath.isEmpty) {
            call.error("from initAudioFile - filePath not found")
        }
        if (audioId.isEmpty) {
            call.error("from initAudioFile - audioId not found")
        }
        // TODO: implement check for overwriting existing audioID
        audioFileList[audioId] = MyAudioFile()
        if (filePath != "") {
            let scrubbedString = filePath.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed) ?? ""
            let urlString = NSURL(string: scrubbedString)
            if (urlString != nil) {
                audioFileList[audioId]!.setupAudio(audioFilePath: urlString!, eqSettings: eqSettings)
                call.success()
            }
            else {
                call.error("in initAudioFile, urlString invalid")
            }
        }
        else {
            call.error("in initAudioFile, filePath invalid")
        }
    }
    
    @objc func setElapsedTimeEvent(_ call: CAPPluginCall) {
        let audioId = call.getString("audioId") ?? ""
        let eventName = call.getString("eventName") ?? ""
        if (audioId.isEmpty) {
            call.error("from setElapsedTimeEvent - audioId not found")
        }
        if (audioFileList[audioId] == nil) {
            call.error("from setElapsedTimeEvent - File not yet added to queue")
        }
        if (eventName.isEmpty) {
            call.error("from setElapsedTimeEvent - eventName not found")
        }
        audioFileList[audioId]?.setElapsedTimeEvent(eventName: eventName, mixer: self)
        call.success()
    }
    
    @objc func getElapsedTime(_ call: CAPPluginCall) {
        let audioId = call.getString("audioId") ?? ""
        if (audioId.isEmpty) {
            call.error("from setElapsedTimeEvent - audioId not found")
        }
        if (audioFileList[audioId] == nil) {
            call.error("from setElapsedTimeEvent - File not yet added to queue")
        }
        let result = (audioFileList[audioId]?.getElapsedTime())!
        call.success(result)
    }
    
    
    // Play local file from a URL
    // Deprecated, dessicated, decapitated
//    private func playLocal(_ call: CAPPluginCall) {
//        let audioFilePath = call.getString("filePath") ?? ""
//
//        if (audioFilePath != "") {
//            let urlString = NSURL(string: "http://192.168.0.147:8100/" + audioFilePath)
//            if (urlString != nil) {
//                downloadFileFromURL(url: urlString!)
//            }
//        }
//        else {
//            call.error("Oopsie daisy darling, we didn't get a file path from you!")
//        }
//    }
    
//    private func playFromDevice(_ call: CAPPluginCall) {
//        let audioFilePath = call.getString("filePath") ?? ""
//
//        if (audioFilePath != "") {
//            let urlString = NSURL(string: audioFilePath)
//            if (urlString != nil) {
//                audioFile.setupAudio(audioFilePath: urlString!)
//            }
//        }
//        else {
//            call.error("Oopsie daisy darling, we didn't get a file path from you!")
//        }
//    }
//
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
