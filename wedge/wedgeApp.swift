//
//  wedgeApp.swift
//  wedge
//
//  Created by Alex Savarimuthu on 16/08/26.
//

import SwiftUI
import AppKit
import Observation

@main
struct wedgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Native Settings scene — system installs Settings… with ⌘, in the app menu.
        Settings {
            WedgeSettingsView(
                settings: appDelegate.settings,
                soundStore: appDelegate.soundStore,
                sound: appDelegate.sound
            )
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private let store = WedgeStore(
        persister: FileWedgePersistence(directory: FileWedgePersistence.defaultDirectory())
    )
    let settings = WedgeSettings(defaults: .standard)
    let soundStore = CustomSoundStore(directory: FileWedgePersistence.defaultDirectory())
    let sound: any DoneSoundPlaying = DoneSoundPlayer()
    private lazy var doneAction = DoneAction(
        store: store,
        settings: settings,
        sound: sound,
        announce: { AccessibilityNotification.Announcement($0).post() }
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        LaunchAtLoginService.enableOnLaunch()
        reloadSoundAndObserve()
        let controller = StatusItemController(store: store, settings: settings, doneAction: doneAction)
        controller.start()
        statusItemController = controller
    }

    /// Loads the chosen sound now and again whenever the custom file changes; re-armed after each change.
    private func reloadSoundAndObserve() {
        sound.load(customURL: soundStore.url(for: settings.customSoundFileName))
        withObservationTracking {
            _ = settings.customSoundFileName
        } onChange: { [weak self] in
            // onChange runs before the new value lands; hop a turn so the reload sees it.
            Task { @MainActor [weak self] in
                self?.reloadSoundAndObserve()
            }
        }
    }
}
