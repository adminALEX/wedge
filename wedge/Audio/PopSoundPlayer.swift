import AppKit

/// Plays the Done confirmation sound (bundled default or custom).
@MainActor
final class PopSoundPlayer {
    private var sound: NSSound?
    private var observer: NSObjectProtocol?

    init() {
        reload()
        observer = NotificationCenter.default.addObserver(
            forName: .wedgePopSoundPreferencesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.reload()
            }
        }
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    func play() {
        guard PopSoundPreferences.isEnabled() else { return }
        guard let sound else {
            NSSound.beep()
            return
        }
        sound.stop()
        if !sound.play() {
            NSSound.beep()
        }
    }

    func reload() {
        sound?.stop()
        if let custom = PopSoundPreferences.customSoundURL() {
            sound = NSSound(contentsOf: custom, byReference: false)
        } else {
            sound = Self.loadBundledSound()
        }
    }

    private static func loadBundledSound() -> NSSound? {
        guard let url = Bundle.main.url(forResource: "pop-sound", withExtension: "mp3") else {
            return nil
        }
        return NSSound(contentsOf: url, byReference: false)
    }
}
