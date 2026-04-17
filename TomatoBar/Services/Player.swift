import AppKit
import SwiftUI

/// Names of system sounds available in /System/Library/Sounds/.
let systemSoundNames = [
    "Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero",
    "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"
]

class TBPlayer: ObservableObject {
    private var startSound: NSSound?
    private var endSound: NSSound?

    @AppStorage("startSoundEnabled") var startSoundEnabled = true
    @AppStorage("endSoundEnabled") var endSoundEnabled = true
    @AppStorage("startSoundName") var startSoundName = "Purr" {
        didSet { reloadStartSound() }
    }
    @AppStorage("endSoundName") var endSoundName = "Glass" {
        didSet { reloadEndSound() }
    }
    @AppStorage("useCustomVolume") var useCustomVolume = false
    @AppStorage("customVolumeLevel") var customVolumeLevel = 0.7

    init() {
        startSound = Self.loadSound(startSoundName)
        endSound = Self.loadSound(endSoundName)
    }

    func playStart() {
        guard startSoundEnabled else { return }
        play(startSound)
    }

    func playEnd() {
        guard endSoundEnabled else { return }
        play(endSound)
    }

    /// Plays a copy of the sound, applying custom volume if enabled.
    /// Copying allows concurrent playback (e.g. preview + timer).
    private func play(_ sound: NSSound?) {
        guard let sound = sound?.copy() as? NSSound else { return }
        if useCustomVolume {
            sound.volume = Float(customVolumeLevel)
        }
        sound.play()
    }

    private func reloadStartSound() {
        startSound = Self.loadSound(startSoundName)
        play(startSound)
    }

    private func reloadEndSound() {
        endSound = Self.loadSound(endSoundName)
        play(endSound)
    }

    /// Loads a system sound by name. Sandbox-safe (reads from
    /// /System/Library/Sounds/). Uses byReference to avoid
    /// copying the file into memory.
    private static func loadSound(_ name: String) -> NSSound? {
        let url = URL(fileURLWithPath: "/System/Library/Sounds/\(name).aiff")
        return NSSound(contentsOf: url, byReference: true)
    }
}
