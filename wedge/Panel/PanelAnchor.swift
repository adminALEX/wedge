import CoreGraphics

/// Where the panel goes: centered under the status item, kept inside the visible screen area.
/// All frames are in AppKit screen coordinates (origin bottom-left).
enum PanelAnchor {
    static let width: CGFloat = 320
    static let gap: CGFloat = 6
    static let margin: CGFloat = 8

    /// - Parameters:
    ///   - itemFrame: the status item's frame, or nil when it is unavailable.
    ///   - visibleFrame: the screen's visible frame (below the menu bar, above the Dock).
    /// When `itemFrame` is nil or lies outside `visibleFrame`'s horizontal span, the panel
    /// sits at the top-right corner of `visibleFrame`.
    static func frame(panelSize: CGSize, itemFrame: CGRect?, visibleFrame: CGRect) -> CGRect {
        let minX = visibleFrame.minX + margin
        let maxX = visibleFrame.maxX - margin - panelSize.width

        let x: CGFloat
        let top: CGFloat
        if let itemFrame, itemFrame.maxX > visibleFrame.minX, itemFrame.minX < visibleFrame.maxX {
            x = itemFrame.midX - panelSize.width / 2
            top = itemFrame.minY - gap
        } else {
            x = maxX
            top = visibleFrame.maxY - gap
        }

        return CGRect(
            x: min(max(x, minX), maxX),
            y: max(top - panelSize.height, visibleFrame.minY + margin),
            width: panelSize.width,
            height: panelSize.height
        )
    }
}
