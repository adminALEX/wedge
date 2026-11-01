import AppKit

extension NSColor {
    /// Parses `#RRGGBB` (case-insensitive). Anything else returns nil.
    convenience init?(hex: String) {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("#") else { return nil }
        let digits = trimmed.dropFirst()
        guard digits.count == 6, digits.allSatisfy(\.isHexDigit),
            let value = UInt32(digits, radix: 16)
        else { return nil }
        self.init(
            srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }

    /// `#RRGGBB` in sRGB (uppercase); alpha is ignored.
    var hexString: String {
        guard let rgb = usingColorSpace(.sRGB) else { return "#000000" }
        func byte(_ component: CGFloat) -> Int { Int((component * 255).rounded()) }
        return String(
            format: "#%02X%02X%02X",
            byte(rgb.redComponent), byte(rgb.greenComponent), byte(rgb.blueComponent)
        )
    }
}
