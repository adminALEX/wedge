import AppKit
import KeyboardShortcuts
import SwiftUI

extension Notification.Name {
    static let wedgeDidPop = Notification.Name("wedgeDidPop")
    static let wedgePanelDidOpen = Notification.Name("wedgePanelDidOpen")
}

@MainActor
final class StatusItemController: NSObject {
    private let store: WedgeStore
    private let persistence: any WedgePersisting
    private var statusItem: NSStatusItem?
    /// Floating panel (not a transient popover) so text editing stays usable.
    private var panel: NSPanel?
    private let popSound = PopSoundPlayer()
    /// After ⌥-click Done on mouseDown, ignore the matching mouseUp so the panel doesn't open.
    private var suppressNextLeftMouseUp = false

    private static let panelSize = NSSize(width: 300, height: 340)

    init(store: WedgeStore, persistence: any WedgePersisting) {
        self.store = store
        self.persistence = persistence
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
        refreshTitle()
        NotificationCenter.default.addObserver(
            forName: .wedgeMenuBarAppearanceDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshTitle()
            }
        }
        // After Settings (or panel) closes, return to menu-bar-only if nothing is open.
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.restoreAccessoryPolicyIfIdle()
            }
        }

        // Key-down matches AppKit menu shortcut timing; Carbon hotkeys are press-oriented.
        KeyboardShortcuts.onKeyDown(for: .togglePanel) { [weak self] in
            Task { @MainActor in
                self?.togglePanel()
            }
        }
        KeyboardShortcuts.onKeyDown(for: .markDone) { [weak self] in
            Task { @MainActor in
                self?.performDone()
            }
        }
    }

    /// Accessory apps don't own the menu bar, so native ⌘, never fires.
    /// While a Wedge window is open, briefly behave like a normal app so the
    /// system Settings… item (⌘,) works — no custom Settings opener.
    private func presentAsNormalAppWhileWindowsOpen() {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func restoreAccessoryPolicyIfIdle() {
        let hasVisibleAppWindow = NSApp.windows.contains { window in
            guard window.isVisible else { return false }
            if window === statusItem?.button?.window { return false }
            // Status-item / menu chrome.
            if String(describing: type(of: window)).contains("NSStatusBar") { return false }
            return true
        }
        if !hasVisibleAppWindow, NSApp.activationPolicy() != .accessory {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private var optionKeyDown: Bool {
        NSEvent.modifierFlags
            .intersection(.deviceIndependentFlagsMask)
            .contains(.option)
    }

    func refreshTitle() {
        guard let button = statusItem?.button else { return }
        if let text = store.oneThing?.text {
            button.image = nil
            button.title = ""
            button.attributedTitle = NSAttributedString(
                string: text,
                attributes: [
                    .foregroundColor: MenuBarAppearance.titleColor,
                    .font: MenuBarAppearance.titleFont
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

    func persistAndRefresh() {
        try? persistence.save(store.items)
        refreshTitle()
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
                performDone()
            }

        case .leftMouseUp:
            if suppressNextLeftMouseUp {
                suppressNextLeftMouseUp = false
                return
            }
            togglePanel()

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
        doneItem.isEnabled = store.oneThing != nil
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
        performDone()
    }

    @objc private func menuOpenSettings(_ sender: Any?) {
        // Own the menu bar so the Settings scene can present, then invoke the
        // same action the system Settings… menu item uses.
        presentAsNormalAppWhileWindowsOpen()
        DispatchQueue.main.async {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
    }

    func performDone() {
        guard store.completeOneThing() != nil else { return }
        popSound.play()
        persistAndRefresh()
        NotificationCenter.default.post(name: .wedgeDidPop, object: nil)
    }

    private func togglePanel() {
        if panel == nil {
            panel = makePanel()
        }
        guard let panel else { return }
        if panel.isVisible {
            panel.orderOut(nil)
            restoreAccessoryPolicyIfIdle()
        } else {
            refreshTitle()
            centerPanelOnScreen(panel)
            // Own the menu bar so system Settings… (⌘,) is live — not a custom opener.
            presentAsNormalAppWhileWindowsOpen()
            // orderFrontRegardless: accessory apps can otherwise fail to raise
            // the panel on the active Space / secondary display.
            panel.orderFrontRegardless()
            panel.makeKeyAndOrderFront(nil)
            NotificationCenter.default.post(name: .wedgePanelDidOpen, object: nil)
        }
    }

    private func makePanel() -> NSPanel {
        let hosting = NSHostingController(
            rootView: PopoverContentView(
                store: store,
                onChange: { [weak self] in
                    self?.persistAndRefresh()
                },
                onDone: { [weak self] in
                    self?.performDone()
                }
            )
        )
        hosting.view.frame.size = Self.panelSize

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.panelSize),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = WedgeCopy.appName
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentViewController = hosting
        return panel
    }

    private func centerPanelOnScreen(_ panel: NSPanel) {
        let screen = statusItem?.button?.window?.screen
            ?? NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) })
            ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }
        let size = panel.frame.size
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2
        )
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
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
