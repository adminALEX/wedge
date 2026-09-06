import SwiftUI
import AppKit

/// Very small settings surface — menu-bar title color + bold.
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
        }
        .formStyle(.grouped)
        .frame(width: 320, height: usesAutomaticColor ? 160 : 200)
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
