//
//  wedgeApp.swift
//  wedge
//
//  Created by Alex Savarimuthu on 16/08/26.
//

import SwiftUI
import AppKit

@main
struct wedgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Native Settings scene — system installs Settings… with ⌘, in the app menu.
        Settings {
            WedgeSettingsView(settings: appDelegate.settings, soundStore: appDelegate.soundStore)
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        LaunchAtLoginService.enableOnLaunch()
        let controller = StatusItemController(store: store, settings: settings, soundStore: soundStore)
        controller.start()
        statusItemController = controller
    }
}
