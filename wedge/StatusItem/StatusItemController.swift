import AppKit
import SwiftUI

@MainActor
final class StatusItemController: NSObject {
    private let store: WedgeStore
    private let persistence: any WedgePersisting
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    init(store: WedgeStore, persistence: any WedgePersisting) {
        self.store = store
        self.persistence = persistence
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
        // Sound + animation wired in Task 6
        persistAndRefresh()
    }

    private func togglePopover() {
        if popover == nil {
            let pop = NSPopover()
            pop.behavior = .transient
            pop.contentSize = NSSize(width: 280, height: 320)
            pop.contentViewController = NSHostingController(
                rootView: PopoverContentView(store: store, onChange: { [weak self] in
                    self?.persistAndRefresh()
                })
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
