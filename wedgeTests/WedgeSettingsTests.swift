import AppKit
import Foundation
import Observation
import Testing

@testable import wedge

/// Lets the `@Sendable` observation callback record that it ran.
private final class ChangeFlag: @unchecked Sendable {
    var fired = false
}

@Suite("WedgeSettings")
@MainActor
struct WedgeSettingsTests {
    private func makeDefaults() throws -> (UserDefaults, cleanup: () -> Void) {
        let suiteName = "wedge.tests.settings.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        return (defaults, { defaults.removePersistentDomain(forName: suiteName) })
    }

    @Test("defaults")
    func defaultValues() throws {
        let (defaults, cleanup) = try makeDefaults()
        defer { cleanup() }
        let settings = WedgeSettings(defaults: defaults)
        #expect(settings.isBold == false)
        #expect(settings.customColorHex == nil)
        #expect(settings.playsSound == true)
        #expect(settings.customSoundFileName == nil)
        #expect(settings.customSoundDisplayName == nil)
        #expect(settings.customSoundLabel == nil)
    }

    @Test("every property round-trips through a fresh instance")
    func roundTrip() throws {
        let (defaults, cleanup) = try makeDefaults()
        defer { cleanup() }
        let settings = WedgeSettings(defaults: defaults)
        settings.isBold = true
        settings.customColorHex = "#3366CC"
        settings.playsSound = false
        settings.customSoundFileName = "custom-done.wav"
        settings.customSoundDisplayName = "Chime.wav"

        let reloaded = WedgeSettings(defaults: defaults)
        #expect(reloaded.isBold == true)
        #expect(reloaded.customColorHex == "#3366CC")
        #expect(reloaded.playsSound == false)
        #expect(reloaded.customSoundFileName == "custom-done.wav")
        #expect(reloaded.customSoundDisplayName == "Chime.wav")
    }

    @Test("setting optional properties to nil clears them")
    func clearingOptionals() throws {
        let (defaults, cleanup) = try makeDefaults()
        defer { cleanup() }
        let settings = WedgeSettings(defaults: defaults)
        settings.customColorHex = "#3366CC"
        settings.customSoundFileName = "custom-done.wav"
        settings.customColorHex = nil
        settings.customSoundFileName = nil

        let reloaded = WedgeSettings(defaults: defaults)
        #expect(reloaded.customColorHex == nil)
        #expect(reloaded.customSoundFileName == nil)
    }

    @Test("blank stored sound file name is treated as absent")
    func blankSoundFileName() throws {
        let (defaults, cleanup) = try makeDefaults()
        defer { cleanup() }
        defaults.set("   ", forKey: "done.customSoundFile")
        #expect(WedgeSettings(defaults: defaults).customSoundFileName == nil)
    }

    @Test("uses the documented defaults keys")
    func keys() throws {
        let (defaults, cleanup) = try makeDefaults()
        defer { cleanup() }
        let settings = WedgeSettings(defaults: defaults)
        settings.isBold = true
        settings.customColorHex = "#112233"
        settings.playsSound = false
        settings.customSoundFileName = "custom-done.aiff"
        #expect(defaults.bool(forKey: "menuBar.bold") == true)
        #expect(defaults.string(forKey: "menuBar.colorHex") == "#112233")
        #expect(defaults.object(forKey: "done.playSound") as? Bool == false)
        #expect(defaults.string(forKey: "done.customSoundFile") == "custom-done.aiff")
        settings.customSoundDisplayName = "Chime.aiff"
        #expect(defaults.string(forKey: "done.customSoundName") == "Chime.aiff")
    }

    @Test("the custom sound shows the chosen file's name, and both clear with Use Default")
    func customSoundLabel() throws {
        let (defaults, cleanup) = try makeDefaults()
        defer { cleanup() }
        let settings = WedgeSettings(defaults: defaults)
        settings.useCustomSound(fileName: "custom-done-1.mp3", displayName: "Chime.mp3")
        #expect(settings.customSoundFileName == "custom-done-1.mp3")
        #expect(settings.customSoundLabel == "Chime.mp3")

        settings.useDefaultSound()
        #expect(settings.customSoundFileName == nil)
        #expect(settings.customSoundDisplayName == nil)
        #expect(settings.customSoundLabel == nil)
    }

    @Test("a custom sound without a stored display name shows its file name")
    func customSoundLabelFallsBackToFileName() throws {
        let (defaults, cleanup) = try makeDefaults()
        defer { cleanup() }
        let settings = WedgeSettings(defaults: defaults)
        settings.customSoundFileName = "custom-done.wav"
        #expect(settings.customSoundLabel == "custom-done.wav")
    }

    @Test("changes are observable")
    func observable() throws {
        let (defaults, cleanup) = try makeDefaults()
        defer { cleanup() }
        let settings = WedgeSettings(defaults: defaults)
        let flag = ChangeFlag()
        withObservationTracking {
            _ = settings.isBold
        } onChange: {
            flag.fired = true
        }
        settings.isBold = true
        #expect(flag.fired)
    }

    @Test("hex round-trips")
    func hexRoundTrip() {
        #expect(NSColor(hex: "#3366CC")?.hexString == "#3366CC")
        #expect(NSColor(hex: "#3366cc")?.hexString == "#3366CC")
    }

    @Test("invalid hex is rejected")
    func invalidHex() {
        #expect(NSColor(hex: "blue") == nil)
        #expect(NSColor(hex: "#12345") == nil)
        #expect(NSColor(hex: "#GG0000") == nil)
        #expect(NSColor(hex: "") == nil)
    }
}
