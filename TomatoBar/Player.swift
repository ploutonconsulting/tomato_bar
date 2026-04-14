import AudioToolbox
import SwiftUI

class TBPlayer: ObservableObject {
    private var windupSoundID: SystemSoundID = 0
    private var dingSoundID: SystemSoundID = 0

    @AppStorage("windupVolume") var windupVolume: Double = 1.0
    @AppStorage("dingVolume") var dingVolume: Double = 1.0

    init() {
        windupSoundID = Self.loadSystemSound("Purr")
        dingSoundID = Self.loadSystemSound("Glass")
    }

    deinit {
        if windupSoundID != 0 { AudioServicesDisposeSystemSoundID(windupSoundID) }
        if dingSoundID != 0 { AudioServicesDisposeSystemSoundID(dingSoundID) }
    }

    func playWindup() {
        guard windupVolume > 0 else { return }
        AudioServicesPlaySystemSound(windupSoundID)
    }

    func playDing() {
        guard dingVolume > 0 else { return }
        AudioServicesPlaySystemSound(dingSoundID)
    }

    /// Loads a system sound file into an AudioToolbox SystemSoundID.
    /// AudioToolbox is sandbox-safe and does not require entitlements.
    private static func loadSystemSound(_ name: String) -> SystemSoundID {
        let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff") as CFURL
        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(url, &soundID)
        return soundID
    }
}
