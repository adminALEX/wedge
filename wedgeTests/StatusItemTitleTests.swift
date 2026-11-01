import AppKit
import Testing

@testable import wedge

@Suite("StatusItemTitle")
@MainActor
struct StatusItemTitleTests {
    @Test func emptyListShowsGlyph() {
        #expect(StatusItemTitle.content(now: nil) == .glyph)
    }

    @Test func nowItemShowsItsText() {
        #expect(StatusItemTitle.content(now: WedgeItem(text: "A")) == .title("A"))
    }

    @Test func accessibilityLabelNamesTheNowItem() {
        #expect(StatusItemTitle.accessibilityLabel(now: WedgeItem(text: "Ship it")) == "Wedge, Now: Ship it")
    }

    @Test func accessibilityLabelWhenNothingNow() {
        #expect(StatusItemTitle.accessibilityLabel(now: nil) == "Wedge, nothing now")
    }

    @Test func boldUsesBoldSystemFont() {
        let attributes = StatusItemTitle.attributes(isBold: true, colorHex: nil)
        #expect(attributes[.font] as? NSFont == NSFont.boldSystemFont(ofSize: NSFont.systemFontSize))
    }

    @Test func regularUsesMenuBarFont() {
        let attributes = StatusItemTitle.attributes(isBold: false, colorHex: nil)
        #expect(attributes[.font] as? NSFont == NSFont.menuBarFont(ofSize: 0))
    }

    @Test func automaticColorIsLabelColor() {
        let attributes = StatusItemTitle.attributes(isBold: false, colorHex: nil)
        #expect(attributes[.foregroundColor] as? NSColor == NSColor.labelColor)
    }

    @Test func customColorIsApplied() {
        let attributes = StatusItemTitle.attributes(isBold: false, colorHex: "#3366CC")
        #expect((attributes[.foregroundColor] as? NSColor)?.hexString == "#3366CC")
    }

    @Test func invalidColorFallsBackToLabelColor() {
        let attributes = StatusItemTitle.attributes(isBold: false, colorHex: "blue")
        #expect(attributes[.foregroundColor] as? NSColor == NSColor.labelColor)
    }
}
