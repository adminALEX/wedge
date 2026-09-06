import Foundation

extension Notification.Name {
    static let wedgePopSoundPreferencesDidChange = Notification.Name("wedgePopSoundPreferencesDidChange")
}

enum PopSoundPreferencesError: Error {
    case unsupportedType
}

enum PopSoundPreferences {
    static let enabledKey = "wedge.popSoundEnabled"
    static let customFileNameKey = "wedge.popSoundCustomFileName"

    static func isEnabled(defaults: UserDefaults = .standard) -> Bool {
        if defaults.object(forKey: enabledKey) == nil { return true }
        return defaults.bool(forKey: enabledKey)
    }

    static func setEnabled(_ enabled: Bool, defaults: UserDefaults = .standard) {
        defaults.set(enabled, forKey: enabledKey)
        notify()
    }

    static func customFileName(defaults: UserDefaults = .standard) -> String? {
        let name = defaults.string(forKey: customFileNameKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (name?.isEmpty == false) ? name : nil
    }

    static func defaultSupportRoot() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("Wedge", isDirectory: true)
    }

    static func customSoundURL(
        defaults: UserDefaults = .standard,
        supportRoot: URL = defaultSupportRoot()
    ) -> URL? {
        guard let name = customFileName(defaults: defaults) else { return nil }
        let url = supportRoot.appendingPathComponent(name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Copies `source` into Application Support as `custom-pop.<ext>`.
    static func installCustomSound(
        from source: URL,
        defaults: UserDefaults = .standard,
        supportRoot: URL = defaultSupportRoot()
    ) throws {
        let ext = source.pathExtension.isEmpty ? "aiff" : source.pathExtension.lowercased()
        let allowed: Set<String> = ["aiff", "aif", "wav", "mp3", "m4a", "caf"]
        guard allowed.contains(ext) else {
            throw PopSoundPreferencesError.unsupportedType
        }
        try FileManager.default.createDirectory(at: supportRoot, withIntermediateDirectories: true)
        // ponytail: single slot — replace any previous custom file
        if let existing = try? FileManager.default.contentsOfDirectory(
            at: supportRoot,
            includingPropertiesForKeys: nil
        ) {
            for url in existing where url.lastPathComponent.hasPrefix("custom-pop.") {
                try? FileManager.default.removeItem(at: url)
            }
        }
        let dest = supportRoot.appendingPathComponent("custom-pop.\(ext)")
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: source, to: dest)
        defaults.set(dest.lastPathComponent, forKey: customFileNameKey)
        notify()
    }

    static func clearCustomSound(
        defaults: UserDefaults = .standard,
        supportRoot: URL = defaultSupportRoot()
    ) {
        if let name = customFileName(defaults: defaults) {
            let url = supportRoot.appendingPathComponent(name)
            try? FileManager.default.removeItem(at: url)
        }
        defaults.removeObject(forKey: customFileNameKey)
        notify()
    }

    static func notify() {
        NotificationCenter.default.post(name: .wedgePopSoundPreferencesDidChange, object: nil)
    }
}
