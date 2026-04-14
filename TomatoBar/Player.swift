import AVFoundation
import SwiftUI

class TBPlayer: ObservableObject {
    private var windupSound: AVAudioPlayer?
    private var dingSound: AVAudioPlayer?

    @AppStorage("windupVolume") var windupVolume: Double = 1.0
    @AppStorage("dingVolume") var dingVolume: Double = 1.0

    init() {
        windupSound = Self.loadSystemSound("Purr")
        dingSound = Self.loadSystemSound("Glass")
    }

    func playWindup() {
        windupSound?.volume = Float(windupVolume)
        windupSound?.currentTime = 0
        windupSound?.play()
    }

    func playDing() {
        dingSound?.volume = Float(dingVolume)
        dingSound?.currentTime = 0
        dingSound?.play()
    }

    /// Loads a system sound from /System/Library/Sounds/ by name.
    /// This path is readable in the app sandbox without entitlements.
    private static func loadSystemSound(_ name: String) -> AVAudioPlayer? {
        let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff")
        return try? AVAudioPlayer(contentsOf: url)
    }
}
