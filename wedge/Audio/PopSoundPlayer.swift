import AppKit

/// Plays the bundled Done confirmation sound (`Sounds/pop-sound.mp3`).
///
/// The `NSSound` is retained for the lifetime of the player: a sound released
/// while still playing is deallocated mid-playback and goes silent.
@MainActor
final class PopSoundPlayer {
    private lazy var sound: NSSound? = Self.loadBundledSound()

    func play() {
        guard let sound else {
            NSSound.beep()
            return
        }
        // Rapid Done presses would otherwise be swallowed: play() on an
        // already-playing NSSound is a no-op.
        sound.stop()
        if !sound.play() {
            NSSound.beep()
        }
    }

    private static func loadBundledSound() -> NSSound? {
        guard let url = Bundle.main.url(forResource: "pop-sound", withExtension: "mp3") else {
            return nil
        }
        return NSSound(contentsOf: url, byReference: false)
    }
}
