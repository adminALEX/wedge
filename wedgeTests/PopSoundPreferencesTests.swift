import Foundation
import Testing
@testable import wedge

@Suite
struct PopSoundPreferencesTests {
    @Test
    func enabledDefaultsToTrue() throws {
        let suiteName = "wedge.tests.pop.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        #expect(PopSoundPreferences.isEnabled(defaults: defaults) == true)
    }

    @Test
    func disabledPersists() throws {
        let suiteName = "wedge.tests.pop.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        PopSoundPreferences.setEnabled(false, defaults: defaults)
        #expect(PopSoundPreferences.isEnabled(defaults: defaults) == false)
    }

    @Test
    func installAndClearCustomSound() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("wedge-pop-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let suiteName = "wedge.tests.pop.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let source = tmp.appendingPathComponent("sample.aiff")
        // Minimal non-empty file is enough for copy path tests (player not invoked).
        try Data([0, 1, 2, 3]).write(to: source)

        try PopSoundPreferences.installCustomSound(
            from: source,
            defaults: defaults,
            supportRoot: tmp.appendingPathComponent("Support", isDirectory: true)
        )
        #expect(PopSoundPreferences.customFileName(defaults: defaults) == "custom-pop.aiff")
        #expect(PopSoundPreferences.customSoundURL(defaults: defaults, supportRoot: tmp.appendingPathComponent("Support")) != nil)

        PopSoundPreferences.clearCustomSound(
            defaults: defaults,
            supportRoot: tmp.appendingPathComponent("Support", isDirectory: true)
        )
        #expect(PopSoundPreferences.customFileName(defaults: defaults) == nil)
    }
}
