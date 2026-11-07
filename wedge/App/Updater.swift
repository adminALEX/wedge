import Foundation
import Observation
import Sparkle

/// Check for Updates, through Sparkle. Automatic checks are off in Info.plist, so Wedge only goes
/// online when the user clicks the button; Sparkle then shows its own update window.
@Observable
final class Updater {
    /// False until `start()`, and while Sparkle is already checking or installing.
    private(set) var canCheckForUpdates = false
    @ObservationIgnored private var controller: SPUStandardUpdaterController?
    @ObservationIgnored private var observation: NSKeyValueObservation?

    /// Starting Sparkle makes no network call; it only reads its settings.
    func start() {
        guard controller == nil else { return }
        let controller = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil
        )
        self.controller = controller
        observation = controller.updater.observe(\.canCheckForUpdates, options: [.initial, .new]) {
            [weak self] updater, _ in
            let canCheck = updater.canCheckForUpdates
            MainActor.assumeIsolated { self?.canCheckForUpdates = canCheck }
        }
    }

    func checkForUpdates() {
        controller?.checkForUpdates(nil)
    }
}
