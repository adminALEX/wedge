import CoreGraphics
import Testing

@testable import wedge

@Suite("PanelAnchor")
@MainActor
struct PanelAnchorTests {
    private let visible = CGRect(x: 0, y: 0, width: 1512, height: 944)
    private let size = CGSize(width: 320, height: 300)

    @Test func centersUnderItem() {
        let f = PanelAnchor.frame(
            panelSize: size,
            itemFrame: CGRect(x: 1000, y: 944, width: 120, height: 24),
            visibleFrame: visible
        )
        #expect(f == CGRect(x: 900, y: 638, width: 320, height: 300))
    }

    @Test func clampsAtRightEdge() {
        let f = PanelAnchor.frame(
            panelSize: size,
            itemFrame: CGRect(x: 1450, y: 944, width: 50, height: 24),
            visibleFrame: visible
        )
        #expect(f.maxX == 1504)
        #expect(f.minY == 638)
    }

    @Test func clampsAtLeftEdge() {
        let f = PanelAnchor.frame(
            panelSize: size,
            itemFrame: CGRect(x: 0, y: 944, width: 50, height: 24),
            visibleFrame: visible
        )
        #expect(f.minX == 8)
    }

    @Test func fallsBackWhenItemOffscreen() {
        let f = PanelAnchor.frame(
            panelSize: size,
            itemFrame: CGRect(x: 4000, y: 944, width: 120, height: 24),
            visibleFrame: visible
        )
        #expect(f == CGRect(x: 1184, y: 638, width: 320, height: 300))
    }

    @Test func fallsBackWhenNoItemFrame() {
        let f = PanelAnchor.frame(panelSize: size, itemFrame: nil, visibleFrame: visible)
        #expect(f == CGRect(x: 1184, y: 638, width: 320, height: 300))
    }

    @Test func clampsTallPanelToBottomMargin() {
        let f = PanelAnchor.frame(
            panelSize: CGSize(width: 320, height: 1200),
            itemFrame: CGRect(x: 1000, y: 944, width: 120, height: 24),
            visibleFrame: visible
        )
        #expect(f.minY == 8)
        #expect(f.height == 1200)
    }

    @Test func secondDisplayOffsets() {
        let second = CGRect(x: 1512, y: 0, width: 1920, height: 1055)
        let f = PanelAnchor.frame(
            panelSize: size,
            itemFrame: CGRect(x: 1520, y: 1055, width: 60, height: 24),
            visibleFrame: second
        )
        #expect(f.minX == 1520)
        #expect(f.maxY == 1049)
    }
}
