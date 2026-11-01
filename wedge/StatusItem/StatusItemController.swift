import AppKit
import KeyboardShortcuts
import Observation
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let store: WedgeStore
    private let settings: WedgeSettings
    private let doneAction: DoneAction
    private var statusItem: NSStatusItem?
    /// Created in `start()`; its content calls back into this controller.
    private var panel: PanelController?
    /// After ⌥-click Done on mouseDown, ignore the matching mouseUp so the panel doesn't open.
    private var suppressNextLeftMouseUp = false
    /// Whether the panel was showing when the current click began; decides what its mouseUp does.
    private var panelWasVisibleAtMouseDown = false

    init(store: WedgeStore, settings: WedgeSettings, doneAction: DoneAction) {
        self.store = store
        self.settings = settings
        self.doneAction = doneAction
    }

    func start() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            // Prefer mouseDown so ⌥ is accurate for menu-bar items.
            button.target = self
            button.action = #selector(statusItemPrimaryAction(_:))
            button.sendAction(on: [.leftMouseDown, .leftMouseUp, .rightMouseDown])
        }
        statusItem = item
        let panel = PanelController(
            content: PopoverContentView(
                store: store,
                doneAction: doneAction,
                onChange: { [weak self] in self?.refreshTitle() },
                onDone: { [weak self] in self?.markDone() }
            )
        )
        panel.itemFrameProvider = { [weak self] in
            guard let window = self?.statusItem?.button?.window, let screen = window.screen else { return nil }
            return (window.frame, screen)
        }
        self.panel = panel
        refreshTitle()
        observeAppearance()
        observePanelVisibility()

        // Key-down matches AppKit menu shortcut timing; Carbon hotkeys are press-oriented.
        KeyboardShortcuts.onKeyDown(for: .togglePanel) { [weak self] in
            Task { @MainActor in
                self?.panel?.toggle()
            }
        }
        KeyboardShortcuts.onKeyDown(for: .markDone) { [weak self] in
            Task { @MainActor in
                self?.markDone()
            }
        }
    }

    private var optionKeyDown: Bool {
        NSEvent.modifierFlags
            .intersection(.deviceIndependentFlagsMask)
            .contains(.option)
    }

    /// Refreshes the title when bold or color change; re-armed after each change.
    private func observeAppearance() {
        withObservationTracking {
            _ = settings.isBold
            _ = settings.customColorHex
        } onChange: { [weak self] in
            // onChange runs before the new value lands; hop a turn so refresh sees it.
            Task { @MainActor [weak self] in
                self?.refreshTitle()
                self?.observeAppearance()
            }
        }
    }

    /// Keeps the button highlighted while the panel is open; re-armed after each change.
    private func observePanelVisibility() {
        guard let panel else { return }
        withObservationTracking {
            _ = panel.isVisible
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.syncButtonHighlight()
                self?.observePanelVisibility()
            }
        }
    }

    private func syncButtonHighlight() {
        statusItem?.button?.highlight(panel?.isVisible ?? false)
    }

    private var titleColor: NSColor {
        settings.customColorHex.flatMap { NSColor(hex: $0) } ?? .labelColor
    }

    private var titleFont: NSFont {
        settings.isBold
            ? NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
            : NSFont.menuBarFont(ofSize: 0)
    }

    func refreshTitle() {
        guard let button = statusItem?.button else { return }
        if let text = store.now?.text {
            button.image = nil
            button.title = ""
            button.attributedTitle = NSAttributedString(
                string: text,
                attributes: [
                    .foregroundColor: titleColor,
                    .font: titleFont
                ]
            )
        } else {
            button.attributedTitle = NSAttributedString(string: "")
            button.title = ""
            let image = NSImage(
                systemSymbolName: "leaf",
                accessibilityDescription: WedgeCopy.statusItemAccessibility
            )
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageOnly
        }
    }

    @objc private func statusItemPrimaryAction(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        switch event.type {
        case .rightMouseDown:
            showContextMenu()

        case .leftMouseDown:
            // ⌥ + click → Done (power-user fast clear).
            if optionKeyDown {
                suppressNextLeftMouseUp = true
                markDone()
            } else {
                // Clicking away from the panel hides it (resign key) around this very event.
                panelWasVisibleAtMouseDown = panel?.wasVisible(atEventTimestamp: event.timestamp) ?? false
            }

        case .leftMouseUp:
            if suppressNextLeftMouseUp {
                suppressNextLeftMouseUp = false
                return
            }
            if panelWasVisibleAtMouseDown {
                panel?.hide()
            } else {
                panel?.show()
            }
            // The button resets its own highlight when the click ends; reassert ours afterwards.
            Task { @MainActor [weak self] in self?.syncButtonHighlight() }

        default:
            break
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        let doneItem = NSMenuItem(
            title: WedgeCopy.done,
            action: #selector(menuDone(_:)),
            keyEquivalent: ""
        )
        doneItem.target = self
        doneItem.isEnabled = store.now != nil
        // Show the remappable global Done chord beside the menu title.
        doneItem.setShortcut(for: .markDone)
        menu.addItem(doneItem)
        menu.addItem(.separator())
        let settingsItem = NSMenuItem(
            title: WedgeCopy.settingsMenu,
            action: #selector(menuOpenSettings(_:)),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: WedgeCopy.quitMenu,
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func menuDone(_ sender: Any?) {
        markDone()
    }

    @objc private func menuOpenSettings(_ sender: Any?) {
        panel?.openSettings()
    }

    /// Every Done entry point lands here: `DoneAction` does the work, then the title catches up.
    private func markDone() {
        guard doneAction.perform() != nil else { return }
        refreshTitle()
    }
}

extension StatusItemController: NSMenuDelegate {
    // KeyboardShortcuts: while NSMenu is open, disable globals so key events
    // aren't buffered and fired when the menu closes.
    func menuWillOpen(_ menu: NSMenu) {
        KeyboardShortcuts.disable(.togglePanel, .markDone)
    }

    func menuDidClose(_ menu: NSMenu) {
        KeyboardShortcuts.enable(.togglePanel, .markDone)
    }
}
