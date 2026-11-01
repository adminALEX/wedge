import AppKit
import Foundation
import Testing

/// The tests are hosted in the app, so `Bundle.main` and `NSImage(named:)` resolve against Wedge's own bundle.
@Suite("AppResources")
@MainActor
struct AppResourcesTests {
    @Test func menuBarGlyphShipsAsATemplateImage() throws {
        let glyph = try #require(NSImage(named: "MenuBarGlyph"))
        #expect(glyph.isTemplate)
    }

    @Test func privacyManifestShipsInTheAppBundle() throws {
        let url = try #require(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
        let manifest = try #require(plist as? [String: Any])
        #expect(manifest["NSPrivacyTracking"] as? Bool == false)
        #expect((manifest["NSPrivacyCollectedDataTypes"] as? [Any])?.isEmpty == true)

        let accessed = try #require(manifest["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        var reasons: [String: [String]] = [:]
        for entry in accessed {
            if let type = entry["NSPrivacyAccessedAPIType"] as? String {
                reasons[type] = entry["NSPrivacyAccessedAPITypeReasons"] as? [String]
            }
        }
        #expect(reasons == [
            "NSPrivacyAccessedAPICategoryUserDefaults": ["CA92.1"],
            "NSPrivacyAccessedAPICategoryFileTimestamp": ["C617.1"],
            "NSPrivacyAccessedAPICategorySystemBootTime": ["35F9.1"],
        ])
    }
}
