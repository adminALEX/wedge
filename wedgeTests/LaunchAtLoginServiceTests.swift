import Foundation
import Testing
@testable import wedge

@Suite("LaunchAtLoginService")
struct LaunchAtLoginServiceTests {
    @Test("enableOnLaunch sets the one-shot did-request flag")
    func enableOnLaunchSetsDidRequestFlag() throws {
        let suiteName = "wedge.tests.login.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(defaults.bool(forKey: LaunchAtLoginService.didRequestKey) == false)
        LaunchAtLoginService.enableOnLaunch(defaults: defaults)
        #expect(defaults.bool(forKey: LaunchAtLoginService.didRequestKey) == true)

        // Second call must remain a no-op for the flag (still true; no crash).
        LaunchAtLoginService.enableOnLaunch(defaults: defaults)
        #expect(defaults.bool(forKey: LaunchAtLoginService.didRequestKey) == true)
    }

    @Test("enableOnLaunch is skipped when flag already set")
    func enableOnLaunchSkippedWhenAlreadyRequested() throws {
        let suiteName = "wedge.tests.login.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(true, forKey: LaunchAtLoginService.didRequestKey)
        LaunchAtLoginService.enableOnLaunch(defaults: defaults)
        #expect(defaults.bool(forKey: LaunchAtLoginService.didRequestKey) == true)
    }
}
