import Foundation
import Testing
@testable import wedge

/// Mutable flag the notification observer (a @Sendable closure) can set.
private final class NotificationFlag: @unchecked Sendable {
    var value = false
}

@Suite("PopSoundPreferences")
@MainActor
struct PopSoundPreferencesTests {
    @Test("enabled defaults to true when key absent")
    func enabledDefaultsToTrue() throws {
        let suiteName = "wedge.tests.pop.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        #expect(PopSoundPreferences.isEnabled(defaults: defaults) == true)
    }

    @Test("disabled persists")
    func disabledPersists() throws {
        let suiteName = "wedge.tests.pop.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        PopSoundPreferences.setEnabled(false, defaults: defaults)
        #expect(PopSoundPreferences.isEnabled(defaults: defaults) == false)
        PopSoundPreferences.setEnabled(true, defaults: defaults)
        #expect(PopSoundPreferences.isEnabled(defaults: defaults) == true)
    }

    @Test("install and clear custom sound")
    func installAndClearCustomSound() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("wedge-pop-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let suiteName = "wedge.tests.pop.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let source = tmp.appendingPathComponent("sample.wav")
        try TestAudioFixtures.writeSilenceWAV(to: source, seconds: 0.25)

        let support = tmp.appendingPathComponent("Support", isDirectory: true)
        try PopSoundPreferences.installCustomSound(
            from: source,
            defaults: defaults,
            supportRoot: support
        )
        #expect(PopSoundPreferences.customFileName(defaults: defaults) == "custom-pop.wav")
        #expect(PopSoundPreferences.customSoundURL(defaults: defaults, supportRoot: support) != nil)

        PopSoundPreferences.clearCustomSound(defaults: defaults, supportRoot: support)
        #expect(PopSoundPreferences.customFileName(defaults: defaults) == nil)
        #expect(PopSoundPreferences.customSoundURL(defaults: defaults, supportRoot: support) == nil)
        #expect(!FileManager.default.fileExists(atPath: support.appendingPathComponent("custom-pop.wav").path))
    }

    @Test("accepts custom sound of exactly three seconds")
    func acceptsExactThreeSeconds() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("wedge-pop-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let suiteName = "wedge.tests.pop.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let source = tmp.appendingPathComponent("exact.wav")
        try TestAudioFixtures.writeSilenceWAV(to: source, seconds: 3.0)
        let support = tmp.appendingPathComponent("Support", isDirectory: true)
        try PopSoundPreferences.installCustomSound(
            from: source,
            defaults: defaults,
            supportRoot: support
        )
        #expect(PopSoundPreferences.customFileName(defaults: defaults) == "custom-pop.wav")
    }

    @Test("rejects custom sound longer than three seconds")
    func rejectsCustomSoundLongerThanThreeSeconds() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("wedge-pop-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let suiteName = "wedge.tests.pop.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let source = tmp.appendingPathComponent("long.wav")
        try TestAudioFixtures.writeSilenceWAV(to: source, seconds: 3.1)

        #expect(throws: PopSoundPreferencesError.tooLong) {
            try PopSoundPreferences.installCustomSound(
                from: source,
                defaults: defaults,
                supportRoot: tmp.appendingPathComponent("Support", isDirectory: true)
            )
        }
        #expect(PopSoundPreferences.customFileName(defaults: defaults) == nil)
    }

    @Test("rejects unsupported file type")
    func rejectsUnsupportedType() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("wedge-pop-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let suiteName = "wedge.tests.pop.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let source = tmp.appendingPathComponent("notes.txt")
        try Data("hello".utf8).write(to: source)

        #expect(throws: PopSoundPreferencesError.unsupportedType) {
            try PopSoundPreferences.installCustomSound(
                from: source,
                defaults: defaults,
                supportRoot: tmp.appendingPathComponent("Support", isDirectory: true)
            )
        }
    }

    @Test("rejects unreadable audio payload")
    func rejectsUnreadable() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("wedge-pop-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let suiteName = "wedge.tests.pop.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let source = tmp.appendingPathComponent("fake.wav")
        try Data([0, 1, 2, 3]).write(to: source)

        #expect(throws: PopSoundPreferencesError.unreadable) {
            try PopSoundPreferences.installCustomSound(
                from: source,
                defaults: defaults,
                supportRoot: tmp.appendingPathComponent("Support", isDirectory: true)
            )
        }
    }

    @Test("install replaces previous custom file")
    func installReplacesPreviousCustom() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("wedge-pop-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let suiteName = "wedge.tests.pop.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let support = tmp.appendingPathComponent("Support", isDirectory: true)
        let first = tmp.appendingPathComponent("first.wav")
        let second = tmp.appendingPathComponent("second.wav")
        try TestAudioFixtures.writeSilenceWAV(to: first, seconds: 0.2)
        try TestAudioFixtures.writeSilenceWAV(to: second, seconds: 0.4)

        try PopSoundPreferences.installCustomSound(from: first, defaults: defaults, supportRoot: support)
        try PopSoundPreferences.installCustomSound(from: second, defaults: defaults, supportRoot: support)

        let files = try FileManager.default.contentsOfDirectory(at: support, includingPropertiesForKeys: nil)
            .map(\.lastPathComponent)
            .filter { $0.hasPrefix("custom-pop.") }
        #expect(files == ["custom-pop.wav"])
        #expect(PopSoundPreferences.customFileName(defaults: defaults) == "custom-pop.wav")
    }

    @Test("customSoundURL is nil when file is missing")
    func staleCustomFileReturnsNilURL() throws {
        let suiteName = "wedge.tests.pop.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set("custom-pop.wav", forKey: PopSoundPreferences.customFileNameKey)
        let missingRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("wedge-missing-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: missingRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: missingRoot) }

        #expect(PopSoundPreferences.customFileName(defaults: defaults) == "custom-pop.wav")
        #expect(PopSoundPreferences.customSoundURL(defaults: defaults, supportRoot: missingRoot) == nil)
    }

    @Test("blank custom file name is treated as absent")
    func blankCustomFileNameIgnored() throws {
        let suiteName = "wedge.tests.pop.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set("   ", forKey: PopSoundPreferences.customFileNameKey)
        #expect(PopSoundPreferences.customFileName(defaults: defaults) == nil)
    }

    @Test("setEnabled posts change notification")
    func setEnabledPostsNotification() throws {
        let suiteName = "wedge.tests.pop.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let center = NotificationCenter.default
        let saw = NotificationFlag()
        let token = center.addObserver(
            forName: .wedgePopSoundPreferencesDidChange,
            object: nil,
            queue: nil
        ) { _ in saw.value = true }
        defer { center.removeObserver(token) }

        PopSoundPreferences.setEnabled(false, defaults: defaults)
        #expect(saw.value)
    }
}
