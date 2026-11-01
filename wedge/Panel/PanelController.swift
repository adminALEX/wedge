import AppKit
import Observation
import SwiftUI
import os

/// Owns the panel and its hosting view (both created once) and positions it under the status item,
/// sized to the content's height (and resized while open as the content grows or shrinks).
@Observable
final class PanelController {
    private(set) var isVisible = false

    /// Set by the status item owner: its button window's frame and screen, or nil when unavailable.
    @ObservationIgnored var itemFrameProvider: () -> (frame: CGRect, screen: NSScreen)? = { nil }

    /// Activates Wedge and opens Settings. Live once the hosted `SettingsOpener` has appeared.
    @ObservationIgnored private(set) var openSettings: () -> Void = {
        Log.panel.error("Settings opener not ready")
    }

    /// Set by the list while a row is being edited: cancels the edit and returns true
    /// (false when there is none). Esc on the panel tries this before closing.
    @ObservationIgnored var cancelEdit: (() -> Bool)?

    @ObservationIgnored private let panel = WedgePanel()
    @ObservationIgnored private let hostingView = NSHostingView(rootView: AnyView(EmptyView()))
    /// Present only while the panel is visible: a click in another app or menu-bar extra hides it.
    @ObservationIgnored private var outsideClickMonitor: Any?
    @ObservationIgnored private var lastHiddenAt: TimeInterval = -.infinity

    init<Content: View>(content: Content) {
        panel.contentView = hostingView
        panel.onDismiss = { [weak self] in self?.hide() }
        panel.onCancel = { [weak self] in self?.cancelEdit?() ?? false }
        hostingView.rootView = AnyView(
            content
                .background {
                    SettingsOpener { [weak self] action in
                        self?.openSettings = {
                            NSApp.activate()
                            action()
                        }
                    }
                }
                .onGeometryChange(for: CGFloat.self) {
                    $0.size.height
                } action: { [weak self] height in
                    self?.contentHeightChanged(to: height)
                }
                .environment(self)
        )
        // Lay out now so the hosted `SettingsOpener` has appeared before the first show.
        hostingView.layoutSubtreeIfNeeded()
    }

    func toggle() {
        if isVisible { hide() } else { show() }
    }

    func show() {
        guard !isVisible else { return }
        let interval = Log.signposter.beginInterval("PanelOpen")
        defer { Log.signposter.endInterval("PanelOpen", interval) }

        hostingView.layoutSubtreeIfNeeded()
        guard place(height: hostingView.fittingSize.height, fallbackScreen: Self.screenUnderMouse()) else {
            return
        }
        isVisible = true
        panel.makeKeyAndOrderFront(nil)
        installOutsideClickMonitor()
    }

    func hide() {
        guard isVisible else { return }
        isVisible = false
        lastHiddenAt = ProcessInfo.processInfo.systemUptime
        removeOutsideClickMonitor()
        panel.orderOut(nil)
    }

    /// Content grew or shrank while open (rows added or removed): keep the panel under the item.
    private func contentHeightChanged(to height: CGFloat) {
        guard isVisible else { return }
        place(height: height, fallbackScreen: panel.screen)
    }

    /// Sizes and anchors the panel under the status item. False when there is no screen.
    @discardableResult
    private func place(height: CGFloat, fallbackScreen: NSScreen?) -> Bool {
        let item = itemFrameProvider()
        guard let visibleFrame = (item?.screen ?? fallbackScreen)?.visibleFrame else {
            Log.panel.error("No screen available to show the panel")
            return false
        }
        let size = CGSize(width: PanelAnchor.width, height: height)
        let frame = PanelAnchor.frame(panelSize: size, itemFrame: item?.frame, visibleFrame: visibleFrame)
        if panel.frame != frame { panel.setFrame(frame, display: true) }
        return true
    }

    /// Clicks on other apps' windows or menu-bar extras don't always take key from the panel,
    /// so resignKey alone can leave it open. Global monitors never see events delivered to
    /// Wedge itself (the panel, the status item), and a hide caused by one of these clicks is
    /// at or after the event's timestamp, so `wasVisible(atEventTimestamp:)` still holds.
    private func installOutsideClickMonitor() {
        removeOutsideClickMonitor()
        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.hide() }
        }
    }

    private func removeOutsideClickMonitor() {
        if let outsideClickMonitor { NSEvent.removeMonitor(outsideClickMonitor) }
        outsideClickMonitor = nil
    }

    /// Whether the panel was showing when the event with this timestamp (`NSEvent.timestamp`) happened.
    /// A click on the status item makes the panel resign key and hide before or after the click
    /// handler runs, so the handler cannot trust `isVisible` alone: a hide at or after the event
    /// was caused by it.
    func wasVisible(atEventTimestamp timestamp: TimeInterval) -> Bool {
        isVisible || lastHiddenAt >= timestamp
    }

    private static func screenUnderMouse() -> NSScreen? {
        NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main
    }
}
