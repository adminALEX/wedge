import AVFoundation
import Foundation
import os

/// Plays the Done confirmation sound. Never beeps: a missing or unplayable sound is silent.
protocol DoneSoundPlaying: AnyObject {
    func play()
    /// Loads `customURL`, or the bundled sound when it is nil or cannot be played.
    func load(customURL: URL?)
}

/// Keeps a prepared `AVAudioPlayer` so `play()` starts without load latency.
final class DoneSoundPlayer: DoneSoundPlaying {
    private var player: AVAudioPlayer?

    init() {
        load(customURL: nil)
    }

    func play() {
        guard let player else { return }
        player.currentTime = 0
        player.play()
    }

    func load(customURL: URL?) {
        player?.stop()
        if let customURL, let custom = Self.makePlayer(url: customURL) {
            player = custom
            return
        }
        if customURL != nil {
            Log.done.error("Custom Done sound could not be loaded; using the bundled sound")
        }
        player = Self.bundledURL.flatMap { Self.makePlayer(url: $0) }
        if player == nil {
            Log.done.error("Bundled Done sound could not be loaded; Done will be silent")
        }
    }

    private static var bundledURL: URL? {
        Bundle.main.url(forResource: "pop-sound", withExtension: "mp3")
    }

    private static func makePlayer(url: URL) -> AVAudioPlayer? {
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        return player
    }
}

/// Plays nothing; used by UI tests so they stay quiet.
final class SilentSoundPlayer: DoneSoundPlaying {
    func play() {}
    func load(customURL: URL?) {}
}
