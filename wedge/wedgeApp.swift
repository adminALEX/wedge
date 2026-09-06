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
            WedgeSettingsView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private let store = WedgeStore()
    private let persistence = UserDefaultsWedgePersistence()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        LaunchAtLoginService.enableOnLaunch()
        if let items = try? persistence.load() {
            store.replaceAll(items)
        }
        let controller = StatusItemController(store: store, persistence: persistence)
        controller.start()
        statusItemController = controller
    }
}
