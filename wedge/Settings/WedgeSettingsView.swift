import SwiftUI
import AppKit
import KeyboardShortcuts
import UniformTypeIdentifiers

/// Menu-bar appearance + remappable global keyboard shortcuts.
struct WedgeSettingsView: View {
    @State private var isBold = MenuBarAppearance.isBold
    @State private var usesAutomaticColor = MenuBarAppearance.usesAutomaticColor
    @State private var customColor = Color(
        nsColor: MenuBarAppearance.customTitleColor ?? .labelColor
    )
    @State private var soundEnabled = PopSoundPreferences.isEnabled()
    @State private var customName = PopSoundPreferences.customFileName()
    @State private var launchAtLogin = LaunchAtLoginService.isEnabled
    @State private var previewPlayer = PopSoundPlayer()

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
                Toggle("Play sound", isOn: $soundEnabled)
                HStack {
                    Text(customName.map { "Custom: \($0)" } ?? "Default pop sound")
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Button("Preview") { previewPlayer.play() }
                        .disabled(!soundEnabled)
                    Button("Choose…") { chooseCustomSound() }
                    if customName != nil {
                        Button("Use default") {
                            PopSoundPreferences.clearCustomSound()
                            customName = nil
                        }
                    }
                }
            } header: {
                Text("Sound")
            } footer: {
                Text("Played when you mark Done. Custom files must be 3 seconds or shorter (AIFF, WAV, MP3, M4A, or CAF).")
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
            } header: {
                Text("General")
            } footer: {
                Text("Starts Wedge automatically when you log in to your Mac.")
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
        .frame(width: 360, height: usesAutomaticColor ? 420 : 460)
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
        .onChange(of: soundEnabled) { _, on in
            PopSoundPreferences.setEnabled(on)
        }
        .onChange(of: launchAtLogin) { _, on in
            do {
                try LaunchAtLoginService.setEnabled(on)
            } catch {
                NSSound.beep()
            }
            launchAtLogin = LaunchAtLoginService.isEnabled
        }
    }

    private func chooseCustomSound() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mp3, .wav, .aiff, .mpeg4Audio]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try PopSoundPreferences.installCustomSound(from: url)
            customName = PopSoundPreferences.customFileName()
        } catch {
            NSSound.beep()
        }
    }
}

#Preview {
    WedgeSettingsView()
}
