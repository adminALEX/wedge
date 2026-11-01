import SwiftUI
import AppKit
import KeyboardShortcuts
import UniformTypeIdentifiers

/// Menu-bar appearance, sound, login, and remappable global keyboard shortcuts.
struct WedgeSettingsView: View {
    @Bindable var settings: WedgeSettings
    let soundStore: CustomSoundStore
    let sound: any DoneSoundPlaying
    @State private var usesAutomaticColor: Bool
    @State private var customColor: Color
    @State private var launchAtLogin = LaunchAtLoginService.isEnabled

    init(settings: WedgeSettings, soundStore: CustomSoundStore, sound: any DoneSoundPlaying) {
        self.settings = settings
        self.soundStore = soundStore
        self.sound = sound
        _usesAutomaticColor = State(initialValue: settings.customColorHex == nil)
        _customColor = State(
            initialValue: Color(nsColor: settings.customColorHex.flatMap { NSColor(hex: $0) } ?? .labelColor)
        )
    }

    var body: some View {
        Form {
            Section {
                Toggle(WedgeCopy.bold, isOn: $settings.isBold)
                Toggle(WedgeCopy.automaticColor, isOn: $usesAutomaticColor)
                if !usesAutomaticColor {
                    ColorPicker(WedgeCopy.color, selection: $customColor, supportsOpacity: false)
                }
            } footer: {
                Text(WedgeCopy.appearanceFooter)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle(WedgeCopy.playSound, isOn: $settings.playsSound)
                HStack {
                    Text(settings.customSoundFileName.map { WedgeCopy.customPopSoundLabel($0) } ?? WedgeCopy.defaultPopSound)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Button(WedgeCopy.preview) { sound.play() }
                        .disabled(!settings.playsSound)
                    Button(WedgeCopy.chooseEllipsis) { chooseCustomSound() }
                    if let customName = settings.customSoundFileName {
                        Button(WedgeCopy.useDefault) {
                            soundStore.remove(fileName: customName)
                            settings.customSoundFileName = nil
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
                KeyboardShortcuts.Recorder(WedgeCopy.showWedgeShortcut, name: .showWedge)
                KeyboardShortcuts.Recorder(WedgeCopy.doneShortcut, name: .markDone)
                Button(WedgeCopy.resetToDefaults) {
                    KeyboardShortcuts.reset(.showWedge, .markDone)
                }
            } header: {
                Text(WedgeCopy.keyboardShortcutsSection)
            }
        }
        .formStyle(.grouped)
        .frame(width: 360, height: usesAutomaticColor ? 420 : 460)
        .onChange(of: usesAutomaticColor) { _, automatic in
            settings.customColorHex = automatic ? nil : NSColor(customColor).hexString
        }
        .onChange(of: customColor) { _, newValue in
            guard !usesAutomaticColor else { return }
            settings.customColorHex = NSColor(newValue).hexString
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
        Task {
            do {
                settings.customSoundFileName = try await soundStore.install(from: url)
            } catch {
                NSSound.beep()
            }
        }
    }
}

#Preview {
    WedgeSettingsView(
        settings: WedgeSettings(defaults: .standard),
        soundStore: CustomSoundStore(directory: FileWedgePersistence.defaultDirectory()),
        sound: DoneSoundPlayer()
    )
}
