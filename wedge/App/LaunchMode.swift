import Foundation

enum LaunchMode: Equatable {
    case normal
    /// UI tests: seeded in-memory list, silent sound, throwaway defaults, no login item.
    case uiTest
    /// Hosted unit tests: like `.uiTest` but an empty list, and the app never starts (no status item, hotkeys or login item).
    case unitTest

    /// `-WedgeUITest` wins over the XCTest environment variable: UI-test launches may carry both.
    static func current(
        _ args: [String] = CommandLine.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> LaunchMode {
        if args.contains("-WedgeUITest") { return .uiTest }
        return environment["XCTestConfigurationFilePath"] != nil ? .unitTest : .normal
    }
}
