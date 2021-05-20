import Foundation
import Capacitor
import AVFoundation

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(Mixer)
public class Mixer: CAPPlugin {
    
    public let engine: AVAudioEngine = AVAudioEngine()
    public let player: AVAudioPlayerNode = AVAudioPlayerNode()
    public var audioFile: AVAudioFile?
    public var audioSampleRate: Double = 0
    public var audioLengthSeconds: Double = 0
    public var audioLengthSamples: AVAudioFramePosition = 0
    public var needsFileScheduled = true
    public var seekFrame: AVAudioFramePosition = 0
    
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
        let queue = DispatchQueue(label: "com.getcapacitor.community.audio.complex.queue",
                                  qos: .userInitiated)
        queue.async {
            self.setupAudio()
        }
    }
    
    private func setupAudio() {
      // 1
      guard let fileURL = Bundle.main.url(
              forResource: "KnewSomething",
              withExtension: "mp3")
      else {
        return
      }
      
      // 2
      do {
        let file = try AVAudioFile(forReading: fileURL)
        let format = file.processingFormat
        
        audioLengthSamples = file.length
        audioSampleRate = format.sampleRate
        audioLengthSeconds = Double(audioLengthSamples) / audioSampleRate
        
        audioFile = file
        
        // 3
        configureEngine(with: format)
      } catch {
        print("Error reading the audio file: \(error.localizedDescription)")
      }
    }
    
    private func configureEngine(with format: AVAudioFormat) {
      // 1
      engine.attach(player)
      
      // 2
      engine.connect(player, to: engine.mainMixerNode, format: format)
      engine.prepare()
      
      do {
        // 3
        try engine.start()
        
        scheduleAudioFile()
//        isPlayerReady = true
      } catch {
        print("Error starting the player: \(error.localizedDescription)")
      }
    }
    
    private func scheduleAudioFile() {
      guard let file = audioFile, needsFileScheduled else {
        return
      }
      
      needsFileScheduled = false
      seekFrame = 0
      
      player.scheduleFile(file, at: nil) {
        self.needsFileScheduled = true
      }
    }
    
    private func playOrPause() {
        if player.isPlaying {
          // 2
          player.pause()
        } else {
          // 3
          if needsFileScheduled {
            scheduleAudioFile()
          }
          player.play()
        }
    }
}
