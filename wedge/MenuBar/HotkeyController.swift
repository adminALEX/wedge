import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    // Product-required defaults (the library prefers empty initials for public apps).
    static let showWedge = Self("showWedge", initial: .init(.w, modifiers: [.control, .option]))
    static let markDone = Self("markDone", initial: .init(.d, modifiers: [.control, .option]))
}

/// Registers the global shortcuts. `suspend`/`resume` bracket an open menu so keys pressed
/// while it is showing are not buffered and fired when it closes.
final class HotkeyController {
    private let panel: PanelController
    private let doneAction: DoneAction

    init(panel: PanelController, doneAction: DoneAction) {
        self.panel = panel
        self.doneAction = doneAction
    }

    func start() {
        // Key-down matches AppKit menu shortcut timing; Carbon hotkeys are press-oriented.
        KeyboardShortcuts.onKeyDown(for: .showWedge) { [panel] in
            Task { @MainActor in panel.toggle() }
        }
        KeyboardShortcuts.onKeyDown(for: .markDone) { [doneAction] in
            Task { @MainActor in doneAction.perform() }
        }
    }

    func suspend() {
        KeyboardShortcuts.disable(.showWedge, .markDone)
    }

    func resume() {
        KeyboardShortcuts.enable(.showWedge, .markDone)
    }
}
