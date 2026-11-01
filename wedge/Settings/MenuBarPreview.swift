import AppKit
import SwiftUI

/// A menu-bar-like strip showing the Now title (or the glyph when empty) with the chosen style.
struct MenuBarPreview: View {
    let now: WedgeItem?
    let isBold: Bool
    let colorHex: String?

    var body: some View {
        let attributes = StatusItemTitle.attributes(isBold: isBold, colorHex: colorHex)
        let color = Color(nsColor: attributes[.foregroundColor] as? NSColor ?? .labelColor)
        HStack {
            Spacer(minLength: 0)
            switch StatusItemTitle.content(now: now) {
            case .title(let text):
                Text(text)
                    .font(Font(attributes[.font] as? NSFont ?? .menuBarFont(ofSize: 0)))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .truncationMode(.tail)
            case .glyph:
                if let glyph = StatusItemController.glyph {
                    Image(nsImage: glyph)
                        .renderingMode(.template)
                        .foregroundStyle(color)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(.bar, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(StatusItemTitle.accessibilityLabel(now: now))
    }
}
