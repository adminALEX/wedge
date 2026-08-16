import AppKit
import SwiftUI

extension Notification.Name {
    static let wedgeDidPop = Notification.Name("wedgeDidPop")
}

@MainActor
final class StatusItemController: NSObject {
    private let store: WedgeStore
    private let persistence: any WedgePersisting
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let popSound = PopSoundPlayer()
    private var pressureMonitor: Any?

    init(store: WedgeStore, persistence: any WedgePersisting) {
        self.store = store
        self.persistence = persistence
    }

    deinit {
        if let pressureMonitor {
            NSEvent.removeMonitor(pressureMonitor)
        }
    }

    func start() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "Wedge")
            image?.isTemplate = true
            button.image = image
            button.imagePosition = .imageLeft
            button.target = self
            button.action = #selector(statusItemPrimaryAction(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item
        refreshTitle()

        // Force click (trackpad, stage 2) → Done. Best-effort: falls through to
        // the normal click path on mouse-only hardware or when stage/pressure
        // thresholds aren't met, so ⌥-click and menu Done remain the required paths.
        pressureMonitor = NSEvent.addLocalMonitorForEvents(matching: [.pressure]) { [weak self] event in
            guard let self,
                  let button = self.statusItem?.button,
                  event.window == button.window,
                  event.stage == 2,
                  event.pressure > 0.5 else { return event }
            self.performDone()
            return nil
        }
    }

    func refreshTitle() {
        guard let button = statusItem?.button else { return }
        if let text = store.oneThing?.text {
            button.title = text
        } else {
            button.title = ""
        }
    }

    func persistAndRefresh() {
        try? persistence.save(store.items)
        refreshTitle()
    }

    @objc private func statusItemPrimaryAction(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
            return
        }
        if event.modifierFlags.contains(.option) {
            performDone()
            return
        }
        togglePopover()
    }

    private func showContextMenu() {
        let menu = NSMenu()
        let doneItem = NSMenuItem(title: "Done", action: #selector(menuDone(_:)), keyEquivalent: "")
        doneItem.target = self
        doneItem.isEnabled = store.oneThing != nil
        menu.addItem(doneItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Wedge", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func menuDone(_ sender: Any?) {
        performDone()
    }

    func performDone() {
        guard store.completeOneThing() != nil else { return }
        popSound.play()
        persistAndRefresh()
        NotificationCenter.default.post(name: .wedgeDidPop, object: nil)
    }

    private func togglePopover() {
        if popover == nil {
            let pop = NSPopover()
            pop.behavior = .transient
            pop.contentSize = NSSize(width: 280, height: 320)
            pop.contentViewController = NSHostingController(
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
            self.popover = pop
        }
        guard let button = statusItem?.button, let popover else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            refreshTitle()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
