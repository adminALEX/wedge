import SwiftUI
import AppKit
import KeyboardShortcuts
import UniformTypeIdentifiers

/// Menu-bar appearance, sound, login, and remappable global keyboard shortcuts.
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
                Toggle(WedgeCopy.bold, isOn: $isBold)
                Toggle(WedgeCopy.automaticColor, isOn: $usesAutomaticColor)
                if !usesAutomaticColor {
                    ColorPicker(WedgeCopy.color, selection: $customColor, supportsOpacity: false)
                }
            } footer: {
                Text(WedgeCopy.appearanceFooter)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(WedgeCopy.playSound, isOn: $soundEnabled)
                HStack {
                    Text(customName.map(WedgeCopy.customPopSoundLabel) ?? WedgeCopy.defaultPopSound)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Button(WedgeCopy.preview) { previewPlayer.play() }
                        .disabled(!soundEnabled)
                    Button(WedgeCopy.chooseEllipsis) { chooseCustomSound() }
                    if customName != nil {
                        Button(WedgeCopy.useDefault) {
                            PopSoundPreferences.clearCustomSound()
                            customName = nil
                        }
                    }
                }
            } header: {
                Text(WedgeCopy.soundSection)
            } footer: {
                Text(WedgeCopy.soundFooter)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(WedgeCopy.launchAtLogin, isOn: $launchAtLogin)
            } header: {
                Text(WedgeCopy.generalSection)
            } footer: {
                Text(WedgeCopy.launchAtLoginFooter)
                    .foregroundStyle(.secondary)
            }

            Section {
                KeyboardShortcuts.Recorder(WedgeCopy.togglePanelShortcut, name: .togglePanel)
                KeyboardShortcuts.Recorder(WedgeCopy.doneShortcut, name: .markDone)
                Button(WedgeCopy.resetToDefaults) {
                    KeyboardShortcuts.reset(.togglePanel, .markDone)
                }
            } header: {
                Text(WedgeCopy.keyboardShortcutsSection)
            } footer: {
                Text(WedgeCopy.keyboardShortcutsFooter)
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
