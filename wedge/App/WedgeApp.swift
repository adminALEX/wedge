import AppIntents
import AppKit
import os
import SwiftUI

@main
struct WedgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Native Settings scene: the system installs Settings… with ⌘, in the app menu.
        Settings {
            SettingsView(environment: appDelegate.environment)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let mode = LaunchMode.current()
    /// Built on first use, so a duplicate launch (which exits before touching it) never loads the
    /// list or builds the panel. Construction starts nothing: `start()` creates the status item,
    /// hotkeys and sound.
    lazy var environment = AppEnvironment(mode: mode)

    override init() {
        super.init()
        registerIntentDependencies()
    }

    /// Registered as early as possible so an intent that launches Wedge in the background can
    /// resolve them, but as lazy factories: the environment is still built on first use only.
    /// The system may call a factory from any queue, so each is an async main-actor closure and
    /// the runtime hops to the main actor. The unit tests call the intents' static `run`
    /// functions directly.
    private func registerIntentDependencies() {
        guard mode != .unitTest else { return }
        let store: @Sendable () async -> WedgeStore = { @MainActor in
            Log.done.debug("Resolving intent dependency: store")
            return self.environment.store
        }
        let doneAction: @Sendable () async -> DoneAction = { @MainActor in
            Log.done.debug("Resolving intent dependency: doneAction")
            return self.environment.doneAction
        }
        AppDependencyManager.shared.add(key: nil, dependency: store)
        AppDependencyManager.shared.add(key: nil, dependency: doneAction)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        switch mode {
        case .unitTest:
            return  // hosted unit tests must not start the app or defer to a real running copy
        case .normal where handOffToRunningInstance():
            return
        case .normal, .uiTest:
            break
        }
        environment.start()
        if mode == .normal { LaunchAtLoginService.enableOnLaunch() }
    }

    /// Relaunching while running (Finder, Dock) opens the panel: the way back when the item is hidden.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        environment.panel.show()
        return false
    }

    /// If another copy of this app is running, asks Launch Services to reopen it (which shows its
    /// panel via `applicationShouldHandleReopen`), quits this copy, and returns true.
    private func handOffToRunningInstance() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        let me = ProcessInfo.processInfo.processIdentifier
        guard let other = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .first(where: { $0.processIdentifier != me })
        else { return false }
        guard let url = other.bundleURL else {
            other.activate()
            NSApp.terminate(nil)
            return true
        }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration()) { _, _ in
            Task { @MainActor in NSApp.terminate(nil) }
        }
        return true
    }
}
