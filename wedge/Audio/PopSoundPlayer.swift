import AppKit

/// Plays a short confirmation sound on Done. Uses system sounds to keep
/// v1 asset-free; swap for a bundled `pop.aiff` later if desired.
struct PopSoundPlayer {
    func play() {
        if NSSound(named: "Pop")?.play() == true { return }
        if NSSound(named: "Tink")?.play() == true { return }
        NSSound.beep()
    }
}
