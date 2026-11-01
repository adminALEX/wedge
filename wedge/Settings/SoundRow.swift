import AppKit
import SwiftUI
import UniformTypeIdentifiers
import os

/// The Done sound row: current name, Preview, Choose…, and Use Default once a custom file is set.
/// A failed choice shows its message under the row and clears on the next success.
struct SoundRow: View {
    @Bindable var settings: WedgeSettings
    let soundStore: CustomSoundStore
    let sound: any DoneSoundPlaying
    let announce: (String) -> Void
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(WedgeCopy.sound)
                Text(settings.customSoundFileName ?? WedgeCopy.defaultSoundName)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 8)
                Button(WedgeCopy.preview, systemImage: "play.fill") { sound.play() }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help(WedgeCopy.preview)
                    .disabled(!settings.playsSound)
                Button(WedgeCopy.chooseEllipsis, action: choose)
                if let fileName = settings.customSoundFileName {
                    Button(WedgeCopy.useDefault) { useDefault(replacing: fileName) }
                }
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private func useDefault(replacing fileName: String) {
        soundStore.remove(fileName: fileName)
        settings.customSoundFileName = nil
        errorMessage = nil
    }

    private func choose() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mp3, .wav, .aiff, .mpeg4Audio]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        Task {
            do {
                settings.customSoundFileName = try await soundStore.install(from: url)
                errorMessage = nil
            } catch {
                let message = WedgeCopy.soundMessage(for: error)
                errorMessage = message
                announce(message)
                Log.settings.error("Custom sound rejected: \(error.localizedDescription, privacy: .private)")
            }
        }
    }
}
