import AppKit
import KeyboardShortcuts
import SwiftUI

/// One-page Settings: menu-bar style with live preview, Done sound, shortcuts, login item, about.
struct SettingsView: View {
    let environment: AppEnvironment
    /// The last custom color, so flipping Automatic then Custom again brings it back.
    @State private var lastCustomHex: String?

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    var body: some View {
        @Bindable var settings = environment.settings
        Form {
            Section(WedgeCopy.menuBarSection) {
                MenuBarPreview(
                    now: environment.store.now, isBold: settings.isBold, colorHex: settings.customColorHex
                )
                Toggle(WedgeCopy.bold, isOn: $settings.isBold)
                Picker(WedgeCopy.color, selection: usesCustomColor) {
                    Text(WedgeCopy.automatic).tag(false)
                    Text(WedgeCopy.custom).tag(true)
                }
                .pickerStyle(.segmented)
                if settings.customColorHex != nil {
                    ColorPicker(WedgeCopy.custom, selection: customColor, supportsOpacity: false)
                }
            }

            Section(WedgeCopy.done) {
                Toggle(WedgeCopy.playSound, isOn: $settings.playsSound)
                SoundRow(
                    settings: settings, soundStore: environment.soundStore,
                    sound: environment.sound, announce: environment.announce
                )
            }

            Section(WedgeCopy.keyboardSection) {
                KeyboardShortcuts.Recorder(WedgeCopy.showWedgeShortcut, name: .showWedge)
                KeyboardShortcuts.Recorder(WedgeCopy.done, name: .markDone)
                Button(WedgeCopy.reset) { KeyboardShortcuts.reset(.showWedge, .markDone) }
            }

            Section { LoginItemRow(announce: environment.announce) }

            Section { aboutRow }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var aboutRow: some View {
        HStack {
            Text(version.map(WedgeCopy.aboutVersion) ?? WedgeCopy.appName)
                .foregroundStyle(.secondary)
            Spacer()
            if let url = URL(string: WedgeCopy.gitHubAddress) {
                Link(WedgeCopy.gitHub, destination: url)
            }
        }
    }

    private var version: String? {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    private var usesCustomColor: Binding<Bool> {
        Binding(
            get: { environment.settings.customColorHex != nil },
            set: { custom in
                let settings = environment.settings
                if custom {
                    settings.customColorHex = lastCustomHex ?? NSColor.controlAccentColor.hexString
                } else {
                    lastCustomHex = settings.customColorHex
                    settings.customColorHex = nil
                }
            }
        )
    }

    private var customColor: Binding<Color> {
        Binding(
            get: {
                Color(nsColor: environment.settings.customColorHex.flatMap { NSColor(hex: $0) } ?? .labelColor)
            },
            set: { environment.settings.customColorHex = NSColor($0).hexString }
        )
    }
}
