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

    init(defaults: UserDefaults) {
        self.defaults = defaults
        isBold = defaults.bool(forKey: Key.bold)
        customColorHex = Self.read(Key.colorHex, in: defaults)
        playsSound = defaults.object(forKey: Key.playSound) as? Bool ?? true
        customSoundFileName = Self.read(Key.customSoundFile, in: defaults)
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
