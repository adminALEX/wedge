import Foundation
import os

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.xela.wedge"

    static let store = Logger(subsystem: subsystem, category: "store")
    static let panel = Logger(subsystem: subsystem, category: "panel")
    static let done = Logger(subsystem: subsystem, category: "done")
    static let settings = Logger(subsystem: subsystem, category: "settings")
    static let signposter = OSSignposter(subsystem: subsystem, category: "performance")
}
