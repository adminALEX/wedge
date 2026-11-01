import AppIntents
import AppKit
import SwiftUI
import os

@main
struct WedgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Native Settings scene: the system installs Settings… with ⌘, in the app menu. The root
        // reads the environment in its body, so declaring the scene doesn't build the environment.
        Settings {
            SettingsRoot(delegate: appDelegate)
        }
    }
}

/// Reads `AppDelegate.environment` in its body, so declaring the Settings scene does not build it.
private struct SettingsRoot: View {
    let delegate: AppDelegate

    var body: some View {
        SettingsView(environment: delegate.environment)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let mode = LaunchMode.current()
    /// Built on first use, so a duplicate launch (which exits before touching it) never loads the
    /// list or builds the panel; the Settings scene's root reads it in its body, not when the scene is built.
    /// Construction starts nothing: `start()` creates the status item, hotkeys and sound.
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

    /// If an older copy of this app is running (`SingleInstance`), asks Launch Services to reopen
    /// it (which shows its panel via `applicationShouldHandleReopen`), quits this copy, and
    /// returns true. The oldest copy returns false and keeps running.
    private func handOffToRunningInstance() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
        guard
            let target = SingleInstance.handOffTarget(
                current: Self.copy(of: NSRunningApplication.current), running: running.map(Self.copy(of:))),
            let other = running.first(where: { $0.processIdentifier == target.processID })
        else { return false }
        guard let url = other.bundleURL else {
            other.activate()
            NSApp.terminate(nil)
            return true
        }
        Task { @MainActor in
            do {
                let configuration = NSWorkspace.OpenConfiguration()
                _ = try await NSWorkspace.shared.openApplication(at: url, configuration: configuration)
            } catch {
                Log.panel.error("Couldn't reopen the running copy: \(error.localizedDescription, privacy: .public)")
            }
            NSApp.terminate(nil)
        }
        return true
    }

    private static func copy(of app: NSRunningApplication) -> SingleInstance.Copy {
        SingleInstance.Copy(
            processID: app.processIdentifier, launchDate: app.launchDate, isTerminated: app.isTerminated)
    }
}
