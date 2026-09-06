import AppKit
import SwiftUI

extension Notification.Name {
    static let wedgeMenuBarAppearanceDidChange = Notification.Name("wedgeMenuBarAppearanceDidChange")
}

/// Minimal persisted look for the menu-bar one-thing title.
enum MenuBarAppearance {
    static let boldKey = "wedge.menuBarBold"
    /// Empty string → system label color.
    static let colorHexKey = "wedge.menuBarColorHex"

    static var isBold: Bool {
        get { UserDefaults.standard.bool(forKey: boldKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: boldKey)
            notify()
        }
    }

    /// `#RRGGBB` or `#RRGGBBAA`. Empty means system label color.
    static var colorHex: String {
        get { UserDefaults.standard.string(forKey: colorHexKey) ?? "" }
        set {
            UserDefaults.standard.set(newValue, forKey: colorHexKey)
            notify()
        }
    }

    static var usesAutomaticColor: Bool {
        colorHex.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Custom color when automatic is off; `nil` when using system label color.
    static var customTitleColor: NSColor? {
        NSColor(wedgeHex: colorHex)
    }

    static var titleColor: NSColor {
        customTitleColor ?? .labelColor
    }

    static var titleFont: NSFont {
        let size = NSFont.systemFontSize
        return isBold
            ? NSFont.boldSystemFont(ofSize: size)
            : NSFont.menuBarFont(ofSize: 0)
    }

    static func notify() {
        NotificationCenter.default.post(name: .wedgeMenuBarAppearanceDidChange, object: nil)
    }
}

extension NSColor {
    convenience init?(wedgeHex: String) {
        var hex = wedgeHex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard hex.hasPrefix("#") else { return nil }
        hex.removeFirst()
        guard hex.count == 6 || hex.count == 8 else { return nil }
        var value: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&value) else { return nil }
        let hasAlpha = hex.count == 8
        let a = hasAlpha ? CGFloat((value & 0xFF)) / 255 : 1
        let rgb = hasAlpha ? value >> 8 : value
        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8) & 0xFF) / 255
        let b = CGFloat(rgb & 0xFF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: a)
    }

    var wedgeHex: String {
        guard let rgb = usingColorSpace(.sRGB) else { return "" }
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        rgb.getRed(&r, green: &g, blue: &b, alpha: &a)
        if a < 1 {
            return String(format: "#%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
        }
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
