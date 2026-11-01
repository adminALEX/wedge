import AppKit
import KeyboardShortcuts
import Observation

/// Owns the `NSStatusItem`: renders the Now item (observed, never pushed), routes clicks, builds the menu.
@MainActor
final class StatusItemController: NSObject {
    private let store: WedgeStore
    private let settings: WedgeSettings
    private let doneAction: DoneAction
    private let panel: PanelController
    private let hotkeys: HotkeyController
    private var statusItem: NSStatusItem?
    /// After ⌥-click Done on mouseDown, ignore the matching mouseUp so the panel doesn't toggle.
    private var suppressNextLeftMouseUp = false
    /// Whether the panel was showing when the current click began; decides what its mouseUp does.
    private var panelWasVisibleAtMouseDown = false
    /// The last Done the button has bumped for.
    private var bumpedEventID: UUID?

    init(
        store: WedgeStore, settings: WedgeSettings, doneAction: DoneAction,
        panel: PanelController, hotkeys: HotkeyController
    ) {
        self.store = store
        self.settings = settings
        self.doneAction = doneAction
        self.panel = panel
        self.hotkeys = hotkeys
    }

    func start() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "WedgeStatusItem"
        if let button = item.button {
            // Prefer mouseDown so ⌥ is accurate for menu-bar items.
            button.target = self
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseDown, .leftMouseUp, .rightMouseDown])
        }
        statusItem = item
        panel.itemFrameProvider = { [weak self] in
            guard let window = self?.statusItem?.button?.window, let screen = window.screen else { return nil }
            return (window.frame, screen)
        }
        track { [weak self] in self?.render() }
        track { [weak self] in self?.syncHighlight() }
        // Tracked after `render`, so the title has swapped by the time the bump plays.
        track { [weak self] in self?.bumpOnDone() }
    }

    /// Runs `body` now and again after every change to anything it read.
    private func track(_ body: @escaping @MainActor () -> Void) {
        withObservationTracking {
            body()
        } onChange: { [weak self] in
            // onChange runs before the new value lands; hop a turn so `body` sees it.
            Task { @MainActor [weak self] in self?.track(body) }
        }
    }

    private func render() {
        let now = store.now
        let attributes = StatusItemTitle.attributes(isBold: settings.isBold, colorHex: settings.customColorHex)
        guard let button = statusItem?.button else { return }
        switch StatusItemTitle.content(now: now) {
        case .title(let text):
            button.image = nil
            button.imagePosition = .noImage
            button.attributedTitle = NSAttributedString(string: text, attributes: attributes)
        case .glyph:
            button.attributedTitle = NSAttributedString(string: "")
            button.image = Self.glyph
            button.imagePosition = .imageOnly
        }
        button.setAccessibilityLabel(StatusItemTitle.accessibilityLabel(now: now))
    }

    /// Bumps the button once per Done, whether or not the panel is visible (spec §3.2).
    private func bumpOnDone() {
        let id = doneAction.lastEvent?.id
        guard id != bumpedEventID else { return }
        bumpedEventID = id
        guard id != nil, let button = statusItem?.button else { return }
        StatusItemBump.play(on: button)
    }

    /// The G1 template glyph from the `MenuBarGlyph` asset (also drawn by Settings' preview).
    static var glyph: NSImage? {
        let image = NSImage(named: "MenuBarGlyph")
        image?.isTemplate = true
        return image
    }

    /// Keeps the button highlighted while the panel is open.
    private func syncHighlight() {
        statusItem?.button?.highlight(panel.isVisible)
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        switch event.type {
        case .rightMouseDown:
            showMenu()
        case .leftMouseDown:
            if event.modifierFlags.contains(.option) {
                // ⌥-click is Done; with nothing to complete it opens the panel instead.
                suppressNextLeftMouseUp = true
                if doneAction.perform() == nil { panel.show() }
            } else {
                // Clicking away from the panel hides it (resign key) around this very event.
                panelWasVisibleAtMouseDown = panel.wasVisible(atEventTimestamp: event.timestamp)
            }
        case .leftMouseUp:
            if suppressNextLeftMouseUp {
                suppressNextLeftMouseUp = false
            } else if panelWasVisibleAtMouseDown {
                panel.hide()
            } else {
                panel.show()
            }
            // The button resets its own highlight when the click ends; reassert ours afterwards.
            Task { @MainActor [weak self] in self?.syncHighlight() }
        default:
            break
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        let done = menuItem(WedgeCopy.done, #selector(menuDone))
        done.isEnabled = store.now != nil
        done.setShortcut(for: .markDone)  // shows the remappable global chord
        menu.addItem(done)
        if store.canUndoDone { menu.addItem(menuItem(WedgeCopy.undoDoneMenu, #selector(menuUndoDone))) }
        menu.addItem(.separator())
        menu.addItem(menuItem(WedgeCopy.settingsMenu, #selector(menuSettings), key: ","))
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(title: WedgeCopy.quitMenu, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    private func menuItem(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    @objc private func menuDone() { doneAction.perform() }
    @objc private func menuUndoDone() { doneAction.undo() }
    @objc private func menuSettings() { panel.openSettings() }
}

extension StatusItemController: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) { hotkeys.suspend() }
    func menuDidClose(_ menu: NSMenu) { hotkeys.resume() }
}
