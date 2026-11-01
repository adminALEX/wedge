import AppKit
import Observation

/// Plays the Done confirmation sound (bundled default or custom).
@MainActor
final class PopSoundPlayer {
    private let settings: WedgeSettings
    private let soundStore: CustomSoundStore
    private var sound: NSSound?

    init(settings: WedgeSettings, soundStore: CustomSoundStore) {
        self.settings = settings
        self.soundStore = soundStore
        reload()
        observeCustomSound()
    }

    func play() {
        guard settings.playsSound else { return }
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
        if let custom = soundStore.url(for: settings.customSoundFileName) {
            sound = NSSound(contentsOf: custom, byReference: false)
        } else {
            sound = Self.loadBundledSound()
        }
    }

    /// Reloads whenever the chosen custom file changes; re-armed after each change.
    private func observeCustomSound() {
        withObservationTracking {
            _ = settings.customSoundFileName
        } onChange: { [weak self] in
            // onChange runs before the new value lands; hop a turn so reload sees it.
            Task { @MainActor [weak self] in
                self?.reload()
                self?.observeCustomSound()
            }
        }
    }

    private static func loadBundledSound() -> NSSound? {
        guard let url = Bundle.main.url(forResource: "pop-sound", withExtension: "mp3") else {
            return nil
        }
        return NSSound(contentsOf: url, byReference: false)
    }
}
