import Foundation

protocol WedgePersisting: AnyObject {
    func load() throws -> [WedgeItem]
    func save(_ items: [WedgeItem]) throws
}

enum WedgePersistenceError: Error, Equatable {
    /// The file could not be decoded; it was moved to `backup` and nothing is left at the original path.
    case corrupt(backup: URL)
    /// The file was written by a newer version of Wedge; it is left untouched.
    case unsupportedVersion(Int)
}

/// Keeps items in memory only. Used by tests and previews.
final class InMemoryWedgePersistence: WedgePersisting {
    var items: [WedgeItem]
    var failSaves = false
    /// Number of `save` calls, including failed ones.
    private(set) var saveCount = 0

    init(items: [WedgeItem] = []) {
        self.items = items
    }

    func load() throws -> [WedgeItem] { items }

    func save(_ items: [WedgeItem]) throws {
        saveCount += 1
        if failSaves { throw CocoaError(.fileWriteUnknown) }
        self.items = items
    }
}
