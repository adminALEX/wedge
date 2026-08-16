import AppKit

/// Plays a short confirmation sound on Done. Uses system sounds to keep
/// v1 asset-free; swap for a bundled `pop.aiff` later if desired.
///
/// The `NSSound` is retained for the lifetime of the player: a sound released
/// while still playing is deallocated mid-playback and goes silent.
@MainActor
final class PopSoundPlayer {
    private lazy var sound: NSSound? = NSSound(named: "Pop") ?? NSSound(named: "Tink")

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
}
