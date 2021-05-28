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
    
    @objc func isPlaying(_ call: CAPPluginCall) {
        // get object out of list using audioID
        // use ID to get playing status and return in call.success
        // let result = audioFileList[audioID].isPlaying()
        // call.success({ value: result })
        let audioID = call.getString("audioID") ?? ""
        if (audioID.isEmpty) {
            call.error("from isPlaying - audioID not found")
        }
        if (audioFileList[audioID] == nil) {
            call.error("from isPlaying - File not yet added to queue")
        }
        let result = audioFileList[audioID]!.isPlaying()
        call.success([ "value": result ])
    }
    
    // This plays AND pauses stuff, ya daangus!
    // TODO: Return error to user when play is hit before choosing file
    @objc func play(_ call: CAPPluginCall) {
        let audioID = call.getString("audioID") ?? ""
        if (audioID.isEmpty) {
            call.error("from play - audioID not found")
        }
        if (audioFileList[audioID] == nil) {
            call.error("from play - File not yet added to queue")
        }
        let result = audioFileList[audioID]!.playOrPause()
        call.success(["state": result])
    }
    
    @objc func stop(_ call: CAPPluginCall) {
        let audioID = call.getString("audioID") ?? ""
        if (audioID.isEmpty) {
            call.error("from stop - audioID not found")
        }
        if (audioFileList[audioID] == nil) {
            call.error("from stop - File not yet added to queue")
        }
        let result = audioFileList[audioID]!.stop()
        call.success(["state": result])
    }
    
    @objc func adjustVolume(_ call: CAPPluginCall) {
        let volume = call.getFloat("volume") ?? -1.0
        let audioID = call.getString("audioID") ?? ""
        if (volume.isLess(than: 0)) {
            call.error("Give me a real volume, dog")
        }
        if (audioID.isEmpty) {
            call.error("from adjustVolume - audioID not found")
        }
        if (audioFileList[audioID] == nil) {
            call.error("from adjustVolume - File not yet added to queue")
        }
        audioFileList[audioID]!.adjustVolume(volume: volume)
    }
    
    @objc func getCurrentVolume(_ call: CAPPluginCall) {
        let audioID = call.getString("audioID") ?? ""
        if (audioID.isEmpty) {
            call.error("from getCurrentVolume - audioID not found")
        }
        if (audioFileList[audioID] == nil) {
            call.error("from getCurrentVolume - File not yet added to queue")
        }
        let result = audioFileList[audioID]!.getCurrentVolume()
        call.success(["volume": result])
    }
    
    @objc func adjustEQ(_ call: CAPPluginCall) {
        let audioID = call.getString("audioID") ?? ""
        let filterType = call.getString("eqType") ?? ""
        let gain = call.getFloat("gain") ?? -100.0
        let freq = call.getFloat("frequency") ?? -1.0
        
        if (audioID.isEmpty) {
            call.error("from adjustEQ - audioID not found")
        }
        if (audioFileList[audioID] == nil) {
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
        audioFileList[audioID]?.adjustEQ(type: filterType, gain: gain, freq: freq)
    }
    
    @objc func initAudioFile(_ call: CAPPluginCall) {
        let filePath = call.getString("filePath") ?? ""
        let audioID = call.getString("audioID") ?? ""
        if (filePath.isEmpty) {
            call.error("from initAudioFile - filePath not found")
        }
        if (audioID.isEmpty) {
            call.error("from initAudioFile - audioID not found")
        }
        // TODO: implement check for overwriting existing audioID
        audioFileList[audioID] = MyAudioFile()
        if (filePath != "") {
            let urlString = NSURL(string: filePath)
            if (urlString != nil) {
                audioFileList[audioID]!.setupAudio(audioFilePath: urlString!)
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
    
    
    // Play local file from a URL
    // Deprecated, dessicated, decapitated
    private func playLocal(_ call: CAPPluginCall) {
        let audioFilePath = call.getString("filePath") ?? ""
        
        if (audioFilePath != "") {
            let urlString = NSURL(string: "http://192.168.0.147:8100/" + audioFilePath)
            if (urlString != nil) {
                downloadFileFromURL(url: urlString!)
            }
        }
        else {
            call.error("Oopsie daisy darling, we didn't get a file path from you!")
        }
    }
    
    private func playFromDevice(_ call: CAPPluginCall) {
        let audioFilePath = call.getString("filePath") ?? ""
        
        if (audioFilePath != "") {
            let urlString = NSURL(string: audioFilePath)
            if (urlString != nil) {
                audioFile.setupAudio(audioFilePath: urlString!)
            }
        }
        else {
            call.error("Oopsie daisy darling, we didn't get a file path from you!")
        }
    }
    
    private func downloadFileFromURL(url:NSURL){
        
        var downloadTask:URLSessionDownloadTask
        downloadTask = URLSession.shared.downloadTask(with: url as URL, completionHandler: { [weak self](URL, URLResponse, Error) -> Void in
            self?.audioFile.setupAudio(audioFilePath: URL! as NSURL)
        })
            
        downloadTask.resume()
        
    }
}
