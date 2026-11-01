import SwiftUI

/// "Undo Done ⌘Z": a small capsule shown for a few seconds after each Done (spec §3.2).
/// `PanelView` decides when; this only draws it.
struct UndoHint: View {
    var body: some View {
        Text(WedgeCopy.undoHint)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.fill.tertiary, in: .capsule)
    }
}
