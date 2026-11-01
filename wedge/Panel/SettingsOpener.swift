import SwiftUI

/// Zero-size view that hands the SwiftUI `openSettings` action to AppKit callers.
struct SettingsOpener: View {
    @Environment(\.openSettings) private var openSettings
    let onCapture: (OpenSettingsAction) -> Void

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear { onCapture(openSettings) }
    }
}
