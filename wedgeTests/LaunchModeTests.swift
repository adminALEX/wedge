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
}
