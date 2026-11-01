import AppKit

enum StatusItemContent: Equatable {
    case glyph
    case title(String)
}

/// What the status item shows for the current state; pure so it can be tested without a menu bar.
enum StatusItemTitle {
    static func content(now: WedgeItem?) -> StatusItemContent {
        now.map { .title($0.text) } ?? .glyph
    }

    static func accessibilityLabel(now: WedgeItem?) -> String {
        now.map { WedgeCopy.statusItemNow($0.text) } ?? WedgeCopy.statusItemNothingNow
    }

    static func attributes(isBold: Bool, colorHex: String?) -> [NSAttributedString.Key: Any] {
        [
            .font: isBold ? NSFont.boldSystemFont(ofSize: NSFont.systemFontSize) : NSFont.menuBarFont(ofSize: 0),
            .foregroundColor: colorHex.flatMap { NSColor(hex: $0) } ?? NSColor.labelColor,
        ]
    }
}
