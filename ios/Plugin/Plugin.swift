import Foundation
import Capacitor
import AVFoundation

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(Mixer)
public class Mixer: CAPPlugin {
    
    public override func load() {
        super.load()
//        do {
//            let session = AVAudioSession.sharedInstance()
//            try session.setCategory(AVAudioSession.Category.playAndRecord, options: [.mixWithOthers, .defaultToSpeaker])
//
//            try session.setActive(true)
//        }
//        catch {
//            // TODO: handle this error
//        }
    }
    
    @objc func echo(_ call: CAPPluginCall) {
        let value = call.getString("value") ?? ""
        call.success([
            "value": value
        ])
    }
    
    @objc func play(_ call: CAPPluginCall) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(AVAudioSession.Category.playAndRecord, options: [.mixWithOthers, .defaultToSpeaker])
            
            try session.setActive(true)
        }
        catch {
            // TODO: handle this error
        }
        let filePath = call.getString("filePath") ?? ""
        NSLog("initialized filepath to " + filePath)
        if (filePath == "") {
            call.error("You need a filepath, bub.")
        }
        let fileURL = NSURL.fileURL(withPath: filePath)
        NSLog("initialized file URL to " + fileURL.absoluteString)
        let audioEngine = AVAudioEngine.init()
        let audioMixer = AVAudioMixerNode()
        let audioPlayerNode: AVAudioPlayerNode! = AVAudioPlayerNode.init()
        NSLog("right before audio format")
//        let audioFormat = audioPlayerNode.inputFormat(forBus: 0)
        NSLog("right after audio format")
        var audioPlayerFile = AVAudioFile()
        NSLog("initialized engine, mixer, player node")
        
        audioEngine.attach(audioPlayerNode)
        audioEngine.attach(audioMixer)
        NSLog("attached the stuff")
        
        do {
            audioPlayerFile = try AVAudioFile.init(forReading: fileURL)
            
        }
        catch {
            call.error("Could not initialize audio file")
        }
        let audioFormat = audioPlayerFile.processingFormat
        let audioFrameCount = UInt32(audioPlayerFile.length)
        let audioFileBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)
        do {
            try audioPlayerFile.read(into: audioFileBuffer!)
        }
        catch {
            call.error("Could not read into FileBuffer")
        }
        
        audioEngine.connect(audioMixer, to: audioEngine.mainMixerNode, format: nil)
        audioEngine.connect(audioPlayerNode, to: audioMixer, format: audioFileBuffer!.format)
        NSLog("connected the stuff")
        
        audioPlayerNode.scheduleBuffer(audioFileBuffer!, at: nil, completionHandler: nil)
        NSLog("Just scheduled your file")
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            audioPlayerNode.volume = 1
            audioPlayerNode.play()
        }
        catch {
            call.error("Could not start audio engine")
        }
        

        
// This is an example of how to record to a file:
// Possibly could be used to write out to a stream??????
//        if let audioURL = audioURL {
//            do {
//                self.recordedOutputFile = try AVAudioFile(forWriting: audioURL, settings: audioMixer.outputFormat(forBus: 0).settings)
//            }
//            catch {
//                // TODO: handle the error
//            }
//        }
        
    }
}
