import Foundation

enum LaunchMode {
    case normal
    /// UI tests: seeded in-memory list, silent sound, throwaway defaults, no login item.
    case uiTest

    static func current(_ args: [String] = CommandLine.arguments) -> LaunchMode {
        args.contains("-WedgeUITest") ? .uiTest : .normal
    }
}
