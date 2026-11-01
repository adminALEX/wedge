import AppKit

/// Borderless, non-activating panel: takes typing without making Wedge the active app.
final class WedgePanel: NSPanel {
    /// Called when the user dismisses the panel (Esc) or it loses key status.
    var onDismiss: () -> Void = {}

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        onDismiss()
    }

    override func resignKey() {
        super.resignKey()
        onDismiss()
    }
}
