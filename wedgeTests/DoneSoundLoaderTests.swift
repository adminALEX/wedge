import Foundation
import Testing

@testable import wedge

@Suite("DoneSoundLoader")
@MainActor
struct DoneSoundLoaderTests {
    @MainActor
    private struct Fixture {
        let directory: URL
        let defaultsName: String
        let settings: WedgeSettings
        let soundStore: CustomSoundStore
        let sound = SpySoundPlayer()

        func cleanup() {
            try? FileManager.default.removeItem(at: directory)
            UserDefaults(suiteName: defaultsName)?.removePersistentDomain(forName: defaultsName)
        }
    }

    private func makeFixture() throws -> Fixture {
        let directory = FileManager.default.temporaryDirectory.appending(path: "wedge-loader-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let defaultsName = "wedge.tests.loader.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: defaultsName))
        return Fixture(
            directory: directory, defaultsName: defaultsName, settings: WedgeSettings(defaults: defaults),
            soundStore: CustomSoundStore(directory: directory.appending(path: "Support")))
    }

    /// The reload happens a turn after the change; waits up to about a second for it.
    private func waitForLoads(_ count: Int, on sound: SpySoundPlayer) async throws {
        var tries = 0
        while sound.loads.count < count, tries < 200 {
            try await Task.sleep(for: .milliseconds(5))
            tries += 1
        }
    }

    private func install(_ name: String, seconds: Double, in fixture: Fixture) async throws -> String {
        let source = fixture.directory.appending(path: name)
        try TestAudioFixtures.writeSilenceWAV(to: source, seconds: seconds)
        let fileName = try await fixture.soundStore.install(from: source)
        fixture.settings.useCustomSound(fileName: fileName, displayName: name)
        return fileName
    }

    @Test func startLoadsTheBundledSoundOnce() throws {
        let fixture = try makeFixture()
        defer { fixture.cleanup() }
        let loader = DoneSoundLoader(settings: fixture.settings, soundStore: fixture.soundStore, sound: fixture.sound)
        loader.start()
        #expect(fixture.sound.loads == [nil])
    }

    @Test func secondCustomSoundWithTheSameExtensionReloads() async throws {
        let fixture = try makeFixture()
        defer { fixture.cleanup() }
        let loader = DoneSoundLoader(settings: fixture.settings, soundStore: fixture.soundStore, sound: fixture.sound)
        loader.start()

        let first = try await install("A.wav", seconds: 0.2, in: fixture)
        try await waitForLoads(2, on: fixture.sound)
        #expect(fixture.sound.loads.count == 2)
        #expect(fixture.sound.loads.last == fixture.soundStore.url(for: first))

        let second = try await install("B.wav", seconds: 0.4, in: fixture)
        try await waitForLoads(3, on: fixture.sound)
        #expect(fixture.sound.loads.count == 3)
        #expect(fixture.sound.loads.last == fixture.soundStore.url(for: second))
        #expect(fixture.settings.customSoundLabel == "B.wav")
    }

    @Test func useDefaultReloadsTheBundledSound() async throws {
        let fixture = try makeFixture()
        defer { fixture.cleanup() }
        let loader = DoneSoundLoader(settings: fixture.settings, soundStore: fixture.soundStore, sound: fixture.sound)
        loader.start()
        _ = try await install("A.wav", seconds: 0.2, in: fixture)
        try await waitForLoads(2, on: fixture.sound)

        fixture.settings.useDefaultSound()
        try await waitForLoads(3, on: fixture.sound)
        #expect(fixture.sound.loads.count == 3)
        #expect(fixture.sound.loads.last == .some(nil))
    }
}
