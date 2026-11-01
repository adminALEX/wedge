import SwiftUI

extension View {
    /// A 1.5 pt accent outline while focused: the `.plain` fields draw no focus ring of their own,
    /// and Full Keyboard Access needs a visible one (spec §10.7).
    func focusIndicator(_ isFocused: Bool, cornerRadius: CGFloat) -> some View {
        overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(Color.accentColor, lineWidth: 1.5)
                .opacity(isFocused ? 1 : 0)
        }
    }
}
