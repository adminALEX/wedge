import AppKit
import Observation
import os
import SwiftUI

/// Owns the panel and its hosting view (both created once) and positions it under the status item.
@Observable
final class PanelController {
    private(set) var isVisible = false

    /// Set by the status item owner: its button window's frame and screen, or nil when unavailable.
    @ObservationIgnored var itemFrameProvider: () -> (frame: CGRect, screen: NSScreen)? = { nil }

    /// Activates Wedge and opens Settings. Live once the hosted `SettingsOpener` has appeared.
    @ObservationIgnored private(set) var openSettings: () -> Void = {}

    @ObservationIgnored private let panel = WedgePanel()
    @ObservationIgnored private let hostingView = NSHostingView(rootView: AnyView(EmptyView()))
    @ObservationIgnored private var lastHiddenAt: TimeInterval = -.infinity

    init<Content: View>(content: Content) {
        panel.contentView = hostingView
        panel.onDismiss = { [weak self] in self?.hide() }
        hostingView.rootView = AnyView(
            PanelRoot(content: content) { [weak self] action in
                self?.openSettings = {
                    NSApp.activate()
                    action()
                }
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

        let item = itemFrameProvider()
        guard let visibleFrame = (item?.screen ?? Self.screenUnderMouse())?.visibleFrame else {
            Log.panel.error("No screen available to show the panel")
            return
        }
        hostingView.layoutSubtreeIfNeeded()
        let size = CGSize(width: PanelAnchor.width, height: hostingView.fittingSize.height)
        panel.setFrame(
            PanelAnchor.frame(panelSize: size, itemFrame: item?.frame, visibleFrame: visibleFrame),
            display: true
        )
        isVisible = true
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        guard isVisible else { return }
        isVisible = false
        lastHiddenAt = ProcessInfo.processInfo.systemUptime
        panel.orderOut(nil)
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

/// Interim panel chrome around the hosted content (replaced when the panel view is rebuilt).
private struct PanelRoot<Content: View>: View {
    let content: Content
    let onOpenSettings: (OpenSettingsAction) -> Void

    private let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)

    var body: some View {
        content
            .frame(width: PanelAnchor.width, height: 340)
            .background(.regularMaterial, in: shape)
            .clipShape(shape)
            .background { SettingsOpener(onCapture: onOpenSettings) }
    }
}

/// Zero-size view that hands the SwiftUI `openSettings` action to AppKit callers.
private struct SettingsOpener: View {
    @Environment(\.openSettings) private var openSettings
    let onCapture: (OpenSettingsAction) -> Void

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear { onCapture(openSettings) }
    }
}
