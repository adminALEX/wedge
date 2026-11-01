import Foundation
import Observation

/// Keeps the Done sound player loaded with the chosen sound: once at start, and again whenever
/// the custom file changes (each install has a new name, so every choice reloads).
final class DoneSoundLoader {
    private let settings: WedgeSettings
    private let soundStore: CustomSoundStore
    private let sound: any DoneSoundPlaying

    init(settings: WedgeSettings, soundStore: CustomSoundStore, sound: any DoneSoundPlaying) {
        self.settings = settings
        self.soundStore = soundStore
        self.sound = sound
    }

    /// Loads the chosen sound now and observes the setting; re-armed after each change.
    func start() {
        let fileName = withObservationTracking {
            settings.customSoundFileName
        } onChange: { [weak self] in
            // onChange runs before the new value lands; hop a turn so the reload sees it.
            Task { @MainActor [weak self] in self?.start() }
        }
        sound.load(customURL: soundStore.url(for: fileName))
    }
}
