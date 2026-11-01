import AppKit
import Observation
import SwiftUI

/// Builds and owns every long-lived object; the one place where concrete types are chosen.
@Observable
final class AppEnvironment {
    let store: WedgeStore
    let settings: WedgeSettings
    let sound: any DoneSoundPlaying
    let doneAction: DoneAction
    let soundStore: CustomSoundStore
    let panel: PanelController
    let statusItem: StatusItemController
    let hotkeys: HotkeyController

    init(mode: LaunchMode) {
        let persister: any WedgePersisting
        let defaults: UserDefaults
        let directory: URL
        let sound: any DoneSoundPlaying
        switch mode {
        case .normal:
            directory = FileWedgePersistence.defaultDirectory()
            persister = FileWedgePersistence(directory: directory)
            defaults = .standard
            sound = DoneSoundPlayer()
        case .uiTest, .unitTest:
            let name = mode == .uiTest ? "wedge.uitest" : "wedge.unittest"
            directory = FileManager.default.temporaryDirectory.appending(path: name)
            let seed = mode == .uiTest ? ["Draft Q4 launch email", "Review onboarding PR", "Book dentist"] : []
            persister = InMemoryWedgePersistence(items: seed.map { WedgeItem(text: $0) })
            guard let suite = UserDefaults(suiteName: name) else {
                fatalError("UserDefaults suite \(name) is unavailable")
            }
            suite.removePersistentDomain(forName: name)
            defaults = suite
            sound = SilentSoundPlayer()
        }
        let store = WedgeStore(persister: persister)
        let settings = WedgeSettings(defaults: defaults)
        let doneAction = DoneAction(
            store: store,
            settings: settings,
            sound: sound,
            announce: { AccessibilityNotification.Announcement($0).post() }
        )
        let panel = PanelController(content: PanelView(store: store, doneAction: doneAction))
        let hotkeys = HotkeyController(panel: panel, doneAction: doneAction)

        self.store = store
        self.settings = settings
        self.sound = sound
        self.doneAction = doneAction
        self.soundStore = CustomSoundStore(directory: directory)
        self.panel = panel
        self.hotkeys = hotkeys
        self.statusItem = StatusItemController(
            store: store, settings: settings, doneAction: doneAction, panel: panel, hotkeys: hotkeys
        )
    }

    func start() {
        loadSoundAndObserve()
        hotkeys.start()
        statusItem.start()
    }

    /// Loads the chosen sound now and again whenever the custom file changes; re-armed after each change.
    private func loadSoundAndObserve() {
        let fileName = withObservationTracking {
            settings.customSoundFileName
        } onChange: { [weak self] in
            // onChange runs before the new value lands; hop a turn so the reload sees it.
            Task { @MainActor [weak self] in self?.loadSoundAndObserve() }
        }
        sound.load(customURL: soundStore.url(for: fileName))
    }
}
