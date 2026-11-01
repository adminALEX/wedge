import Foundation
import Observation

/// User preferences, persisted to `UserDefaults` as they change.
@Observable
final class WedgeSettings {
    private enum Key {
        static let bold = "menuBar.bold"
        static let colorHex = "menuBar.colorHex"
        static let playSound = "done.playSound"
        static let customSoundFile = "done.customSoundFile"
        static let customSoundName = "done.customSoundName"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var isBold: Bool {
        didSet { defaults.set(isBold, forKey: Key.bold) }
    }

    /// `#RRGGBB`; nil means Automatic (system label color).
    var customColorHex: String? {
        didSet { Self.write(customColorHex, forKey: Key.colorHex, in: defaults) }
    }

    var playsSound: Bool {
        didSet { defaults.set(playsSound, forKey: Key.playSound) }
    }

    /// File name inside the custom-sound folder; nil means the bundled sound.
    var customSoundFileName: String? {
        didSet { Self.write(customSoundFileName, forKey: Key.customSoundFile, in: defaults) }
    }

    /// The name of the file the user chose (for example "Chime.mp3"), shown in Settings.
    var customSoundDisplayName: String? {
        didSet { Self.write(customSoundDisplayName, forKey: Key.customSoundName, in: defaults) }
    }

    /// What Settings shows for the custom sound; nil while the bundled sound is in use.
    var customSoundLabel: String? {
        customSoundFileName.map { customSoundDisplayName ?? $0 }
    }

    init(defaults: UserDefaults) {
        self.defaults = defaults
        isBold = defaults.bool(forKey: Key.bold)
        customColorHex = Self.read(Key.colorHex, in: defaults)
        playsSound = defaults.object(forKey: Key.playSound) as? Bool ?? true
        customSoundFileName = Self.read(Key.customSoundFile, in: defaults)
        customSoundDisplayName = Self.read(Key.customSoundName, in: defaults)
    }

    /// Switches to an installed custom sound. The name is set first, so whoever observes the file
    /// name (the sound loader, Settings) sees both together.
    func useCustomSound(fileName: String, displayName: String) {
        customSoundDisplayName = displayName
        customSoundFileName = fileName
    }

    func useDefaultSound() {
        customSoundFileName = nil
        customSoundDisplayName = nil
    }

    private static func read(_ key: String, in defaults: UserDefaults) -> String? {
        guard let value = defaults.string(forKey: key)?.trimmingCharacters(in: .whitespacesAndNewlines),
            !value.isEmpty
        else { return nil }
        return value
    }

    private static func write(_ value: String?, forKey key: String, in defaults: UserDefaults) {
        if let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            defaults.set(value, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
