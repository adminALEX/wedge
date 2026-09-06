import AppKit
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    // ponytail: product-required defaults (library prefers empty initials for public apps)
    static let togglePanel = Self(
        "togglePanel",
        initial: .init(.w, modifiers: [.control, .option])
    )
    static let markDone = Self(
        "markDone",
        initial: .init(.d, modifiers: [.control, .option])
    )
}
