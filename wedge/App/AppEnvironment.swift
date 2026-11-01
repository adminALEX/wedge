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
    /// Posts a VoiceOver announcement; shared by Done and the panel's move announcements.
    let announce: (String) -> Void
    let soundStore: CustomSoundStore
    let panel: PanelController
    let statusItem: StatusItemController
    let hotkeys: HotkeyController
    private let soundLoader: DoneSoundLoader
    private let showsPanelAtStart: Bool

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
        let announce: (String) -> Void = { AccessibilityNotification.Announcement($0).post() }
        let doneAction = DoneAction(store: store, settings: settings, sound: sound, announce: announce)
        let panel = PanelController(
            content: PanelView(store: store, doneAction: doneAction, announce: announce)
        )
        let hotkeys = HotkeyController(panel: panel, doneAction: doneAction)
        let soundStore = CustomSoundStore(directory: directory)

        self.store = store
        self.settings = settings
        self.sound = sound
        self.doneAction = doneAction
        self.announce = announce
        self.soundStore = soundStore
        self.soundLoader = DoneSoundLoader(settings: settings, soundStore: soundStore, sound: sound)
        self.panel = panel
        self.hotkeys = hotkeys
        self.showsPanelAtStart = LaunchMode.showsPanelAtStart(mode)
        self.statusItem = StatusItemController(
            store: store, settings: settings, doneAction: doneAction, panel: panel, hotkeys: hotkeys
        )
    }

    /// The status item comes first, so Wedge is visible as early as possible; the sound loads once, here.
    func start() {
        statusItem.start()
        soundLoader.start()
        hotkeys.start()
        if showsPanelAtStart { panel.show() }
    }
}
