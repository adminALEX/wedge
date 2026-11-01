import SwiftUI

/// The 40-character cap on item text, counted in `Character`s (grapheme clusters).
enum InputLimit {
    static let max = WedgeStore.maxTextLength, counterThreshold = 30

    /// "34/40" from 30 characters on; nil below that.
    static func counter(for text: String) -> String? {
        text.count >= counterThreshold ? "\(text.count)/\(Self.max)" : nil
    }

    /// Refuses a change that would go over the cap, keeping `previous`.
    static func filter(proposed: String, previous: String) -> (text: String, refused: Bool) {
        proposed.count > Self.max ? (previous, true) : (proposed, false)
    }
}

extension View {
    /// Holds `text` to `InputLimit.max`: an over-long change (typing or paste) is put back to the
    /// previous value and `refused` becomes true until the next accepted change.
    func inputLimit(_ text: Binding<String>, refused: Binding<Bool>) -> some View {
        onChange(of: text.wrappedValue) { old, new in
            // Accepted values never exceed the cap, so an over-long `old` is the refused
            // proposal this handler just put back; leave `refused` as it is.
            guard old.count <= InputLimit.max else { return }
            let result = InputLimit.filter(proposed: new, previous: old)
            refused.wrappedValue = result.refused
            if result.refused { text.wrappedValue = result.text }
        }
    }
}
