import Testing

@testable import wedge

@Suite("LaunchMode")
@MainActor
struct LaunchModeTests {
    private let xctest = ["XCTestConfigurationFilePath": "/tmp/x.xctestconfiguration"]

    @Test func normalByDefault() {
        #expect(LaunchMode.current(["wedge"], environment: [:]) == .normal)
    }

    @Test func uiTestViaArgument() {
        #expect(LaunchMode.current(["wedge", "-WedgeUITest"], environment: [:]) == .uiTest)
    }

    @Test func unitTestViaEnvironment() {
        #expect(LaunchMode.current(["wedge"], environment: xctest) == .unitTest)
    }

    @Test func uiTestWinsWhenBothPresent() {
        #expect(LaunchMode.current(["wedge", "-WedgeUITest"], environment: xctest) == .uiTest)
    }

    @Test func showsPanelAtStartOnlyForUITestsWithTheFlag() {
        let args = ["wedge", "-WedgeUITest", "-WedgeUITestShowPanel"]
        #expect(LaunchMode.showsPanelAtStart(.uiTest, args: args))
        #expect(!LaunchMode.showsPanelAtStart(.uiTest, args: ["wedge", "-WedgeUITest"]))
        #expect(!LaunchMode.showsPanelAtStart(.normal, args: args))
        #expect(!LaunchMode.showsPanelAtStart(.unitTest, args: args))
    }
}
