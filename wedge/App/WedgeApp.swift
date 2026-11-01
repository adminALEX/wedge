import AppKit
import SwiftUI

@main
struct WedgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Native Settings scene: the system installs Settings… with ⌘, in the app menu.
        Settings {
            WedgeSettingsView(
                settings: appDelegate.environment.settings,
                soundStore: appDelegate.environment.soundStore,
                sound: appDelegate.environment.sound
            )
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let mode: LaunchMode
    /// Built here, not at launch, so the Settings scene can read it before `applicationDidFinishLaunching`.
    /// Construction is inert (no status item, hotkeys or sound); `start()` does that.
    let environment: AppEnvironment

    override init() {
        let mode = LaunchMode.current()
        self.mode = mode
        environment = AppEnvironment(mode: mode)
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if mode == .normal, activateRunningInstance() {
            NSApp.terminate(nil)
            return
        }
        environment.start()
        if mode == .normal { LaunchAtLoginService.enableOnLaunch() }
    }

    /// Relaunching while running (Finder, Dock) opens the panel: the way back when the item is hidden.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        environment.panel.show()
        return false
    }

    /// Activates another running copy of this app, if any; returns whether there was one.
    private func activateRunningInstance() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        let me = ProcessInfo.processInfo.processIdentifier
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != me }
        others.first?.activate()
        return !others.isEmpty
    }
}
