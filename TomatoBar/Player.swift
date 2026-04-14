import AudioToolbox
import SwiftUI

/// Names of system sounds available in /System/Library/Sounds/.
let systemSoundNames = [
    "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero",
    "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"
]

class TBPlayer: ObservableObject {
    private var startSoundID: SystemSoundID = 0
    private var endSoundID: SystemSoundID = 0

    @AppStorage("startSoundEnabled") var startSoundEnabled = true
    @AppStorage("endSoundEnabled") var endSoundEnabled = true
    @AppStorage("startSoundName") var startSoundName = "Purr" {
        didSet { reloadStartSound() }
    }
    @AppStorage("endSoundName") var endSoundName = "Glass" {
        didSet { reloadEndSound() }
    }

    init() {
        startSoundID = Self.loadSystemSound(startSoundName)
        endSoundID = Self.loadSystemSound(endSoundName)
    }

    deinit {
        if startSoundID != 0 { AudioServicesDisposeSystemSoundID(startSoundID) }
        if endSoundID != 0 { AudioServicesDisposeSystemSoundID(endSoundID) }
    }

    func playStart() {
        guard startSoundEnabled else { return }
        AudioServicesPlaySystemSound(startSoundID)
    }

    func playEnd() {
        guard endSoundEnabled else { return }
        AudioServicesPlaySystemSound(endSoundID)
    }

    private func reloadStartSound() {
        if startSoundID != 0 { AudioServicesDisposeSystemSoundID(startSoundID) }
        startSoundID = Self.loadSystemSound(startSoundName)
        AudioServicesPlaySystemSound(startSoundID)
    }

    private func reloadEndSound() {
        if endSoundID != 0 { AudioServicesDisposeSystemSoundID(endSoundID) }
        endSoundID = Self.loadSystemSound(endSoundName)
        AudioServicesPlaySystemSound(endSoundID)
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
