import SwiftUI
import AppKit
import KeyboardShortcuts

/// Menu-bar appearance + remappable global keyboard shortcuts.
struct WedgeSettingsView: View {
    @State private var isBold = MenuBarAppearance.isBold
    @State private var usesAutomaticColor = MenuBarAppearance.usesAutomaticColor
    @State private var customColor = Color(
        nsColor: MenuBarAppearance.customTitleColor ?? .labelColor
    )

    var body: some View {
        Form {
            Section {
                Toggle("Bold", isOn: $isBold)
                Toggle("Automatic color", isOn: $usesAutomaticColor)
                if !usesAutomaticColor {
                    ColorPicker("Color", selection: $customColor, supportsOpacity: false)
                }
            } footer: {
                Text("Applies to the one thing in the menu bar. Automatic follows the system label color.")
                    .foregroundStyle(.secondary)
            }

            Section {
                KeyboardShortcuts.Recorder("Toggle panel", name: .togglePanel)
                KeyboardShortcuts.Recorder("Done", name: .markDone)
                Button("Reset to defaults") {
                    KeyboardShortcuts.reset(.togglePanel, .markDone)
                }
            } header: {
                Text("Keyboard shortcuts")
            } footer: {
                Text("Defaults are ⌃⌥W (toggle panel) and ⌃⌥D (Done). Prefer chords that include Control or Command — Option/Shift-only remaps can fail on some macOS 15 versions. Remapping saves automatically.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 360, height: usesAutomaticColor ? 280 : 320)
        .onChange(of: isBold) { _, newValue in
            MenuBarAppearance.isBold = newValue
        }
        .onChange(of: usesAutomaticColor) { _, automatic in
            if automatic {
                MenuBarAppearance.colorHex = ""
            } else {
                MenuBarAppearance.colorHex = NSColor(customColor).wedgeHex
            }
        }
        .onChange(of: customColor) { _, newValue in
            guard !usesAutomaticColor else { return }
            MenuBarAppearance.colorHex = NSColor(newValue).wedgeHex
        }
    }
}

#Preview {
    WedgeSettingsView()
}
